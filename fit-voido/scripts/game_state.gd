extends Node
## Persistent, dialogue-friendly progress state.
##
## Add this file as the `GameState` autoload. Dialogue Manager can then read
## conditions and call mutations such as:
##   if GameState.npc_stage("coach_mira") == "new":
##   set GameState.set_npc_stage("coach_mira", "met")

signal npc_stage_changed(npc_id: String, previous_stage: String, new_stage: String)
signal quests_changed
signal quest_stage_changed(quest_id: String, previous_stage: String, new_stage: String)
signal flag_changed(flag_id: String, value: bool)
signal quiz_result_recorded(quiz_id: String, result: Dictionary)
signal game_event_triggered(event_name: String, value: Variant)
signal state_saved
signal progression_changed
signal save_failed(error: int)

const SAVE_PATH := "user://game_state.cfg"
const STATE_SECTION := "progress"
const SAVE_VERSION := 2
const ACTIVITY_IDS := ["garbage_quest", "fit_runner", "fit_runner_race", "boss_fight"]
## Override only for isolated tests. Normal gameplay uses SAVE_PATH.
var save_path := SAVE_PATH
var last_save_error: Error = OK

const NPC_STAGE_NEW := "new"
const NPC_STAGE_MET := "met"
const NPC_STAGE_ACTIVE := "active"
const NPC_STAGE_COMPLETE := "complete"
const NPC_STAGE_LOCKED := "locked"

const QUEST_STAGE_INACTIVE := "inactive"
const QUEST_STAGE_ACTIVE := "active"
const QUEST_STAGE_COMPLETE := "complete"

## IDs are stable strings chosen by the game, for example "coach_mira".
## A missing NPC defaults to "new"; a missing quest defaults to "inactive".
var _npc_stages: Dictionary = {}
var _quest_stages: Dictionary = {}
var _quest_details: Dictionary = {}
var _flags: Dictionary = {}
var _quiz_results: Dictionary = {}
var _journey: Dictionary = {}
var _activity_results: Dictionary = {}

## Active quiz session state for dialogues
var quiz_session_id: String = ""
var quiz_session_score: int = 0
var quiz_session_total: int = 0


func _ready() -> void:
	quest_stage_changed.connect(func(_id: String, _before: String, _after: String): quests_changed.emit())
	load_game()


## Debug-only shortcut available from every scene.
## Press F8 while running from the editor to reset all persistent progress.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		reset_progress()
		get_viewport().set_input_as_handled()
		print("GameState: progress reset.")


# NPCs ---------------------------------------------------------------------------

func npc_stage(npc_id: String) -> String:
	return str(_npc_stages.get(npc_id, NPC_STAGE_NEW))


func set_npc_stage(npc_id: String, stage: String) -> void:
	var previous_stage := npc_stage(npc_id)
	if previous_stage == stage:
		return
	_npc_stages[npc_id] = stage
	npc_stage_changed.emit(npc_id, previous_stage, stage)
	save_game()


func has_met(npc_id: String) -> bool:
	return npc_stage(npc_id) != NPC_STAGE_NEW


func mark_met(npc_id: String) -> void:
	if not has_met(npc_id):
		set_npc_stage(npc_id, NPC_STAGE_MET)


# Quests -------------------------------------------------------------------------

func quest_stage(quest_id: String) -> String:
	return str(_quest_stages.get(quest_id, QUEST_STAGE_INACTIVE))


func set_quest_stage(quest_id: String, stage: String) -> void:
	var previous_stage := quest_stage(quest_id)
	if previous_stage == stage:
		return
	_quest_stages[quest_id] = stage
	quest_stage_changed.emit(quest_id, previous_stage, stage)
	save_game()


func start_quest(quest_id: String) -> void:
	if has_completed_quest(quest_id):
		return
	set_quest_stage(quest_id, QUEST_STAGE_ACTIVE)


func complete_quest(quest_id: String) -> void:
	set_quest_stage(quest_id, QUEST_STAGE_COMPLETE)


func is_quest_active(quest_id: String) -> bool:
	return quest_stage(quest_id) == QUEST_STAGE_ACTIVE


func has_completed_quest(quest_id: String) -> bool:
	return quest_stage(quest_id) == QUEST_STAGE_COMPLETE


# Flags --------------------------------------------------------------------------

## Use flags for one-off facts that do not need a multi-step stage.
func has_flag(flag_id: String) -> bool:
	return bool(_flags.get(flag_id, false))


func set_flag(flag_id: String, value: bool = true) -> void:
	if has_flag(flag_id) == value:
		return
	_flags[flag_id] = value
	flag_changed.emit(flag_id, value)
	save_game()


# Quizzes ------------------------------------------------------------------------

## Begins an interactive quiz session from dialogue
func quiz_begin(quiz_id: String, total: int = 5) -> void:
	quiz_session_id = quiz_id
	quiz_session_total = total
	quiz_session_score = 0


## Marks a question answer as correct or incorrect
func quiz_mark(correct: bool) -> void:
	if correct:
		quiz_session_score += 1


## Finishes the current quiz session and records the result
func quiz_finish() -> void:
	if quiz_session_id != "":
		record_quiz_result(quiz_session_id, quiz_session_score, quiz_session_total)


## Generic event trigger called from dialogues (e.g. award_exp)
func trigger_event(event_name: String, value: Variant = 0) -> void:
	game_event_triggered.emit(event_name, value)


## Stores the best score, latest score, number of attempts, and completion state.
func record_quiz_result(quiz_id: String, score: int, total: int) -> void:
	var previous: Dictionary = quiz_result(quiz_id)
	var result := {
		"best_score": maxi(int(previous.get("best_score", 0)), score),
		"last_score": score,
		"total": total,
		"attempts": int(previous.get("attempts", 0)) + 1,
		"completed": true,
	}
	_quiz_results[quiz_id] = result
	quiz_result_recorded.emit(quiz_id, result.duplicate(true))
	save_game()


func quiz_result(quiz_id: String) -> Dictionary:
	var result: Variant = _quiz_results.get(quiz_id, {})
	return result.duplicate(true) if result is Dictionary else {}


func quiz_best_score(quiz_id: String) -> int:
	return int(quiz_result(quiz_id).get("best_score", 0))


func has_completed_quiz(quiz_id: String) -> bool:
	return bool(quiz_result(quiz_id).get("completed", false))


# Journey ------------------------------------------------------------------------

## Chapter-one story handoffs. Presentation and NPC placement live in the scene.
func stage1_activity() -> String:
	return str(_journey.get("stage1_activity", ""))


func select_stage1_activity(activity_id: String) -> bool:
	if activity_id not in ["garbage_quest", "fit_runner"] or has_time_stone(1):
		return false
	var previous := stage1_activity()
	_journey["stage1_activity"] = activity_id
	if previous != "" and previous != activity_id and not has_completed_quest(previous):
		_quest_stages[previous] = QUEST_STAGE_INACTIVE
	if not has_completed_quest(activity_id):
		_quest_stages[activity_id] = QUEST_STAGE_ACTIVE
	_quest_stages["reach_building_c"] = QUEST_STAGE_COMPLETE
	_quest_stages["stage1_challenge"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	progression_changed.emit()
	return true


func can_claim_stage1_stone() -> bool:
	return not has_time_stone(1) and (has_completed_quest("garbage_quest") or has_completed_quest("fit_runner"))


## One save includes the stone, completed chapter, and next objective.
func claim_stage1_stone() -> bool:
	if not can_claim_stage1_stone():
		return false
	_flags["stage1_stone_collected"] = true
	_quest_stages["reach_building_c"] = QUEST_STAGE_COMPLETE
	_quest_stages["stage1_challenge"] = QUEST_STAGE_COMPLETE
	if not has_completed_quest("enter_room_417"):
		_quest_stages["enter_room_417"] = QUEST_STAGE_ACTIVE
	for id in ["garbage_quest", "fit_runner"]:
		if is_quest_active(id):
			_quest_stages[id] = QUEST_STAGE_INACTIVE
	save_game()
	flag_changed.emit("stage1_stone_collected", true)
	quests_changed.emit()
	progression_changed.emit()
	return true

## Legacy dialogue flags remain the source of truth for stone ownership.
func has_time_stone(number: int) -> bool:
	return number >= 1 and number <= 4 and has_flag("stage%d_stone_collected" % number)


func time_stone_count() -> int:
	var count := 0
	for number in range(1, 5):
		if has_time_stone(number):
			count += 1
	return count


## chapter 5 is the final gate. Unlocks are derived, never separately saved.
func is_chapter_unlocked(chapter: int) -> bool:
	if chapter < 1 or chapter > 5:
		return false
	for number in range(1, chapter):
		if not has_time_stone(number):
			return false
	return true


func award_time_stone(number: int) -> bool:
	if not is_chapter_unlocked(number) or has_time_stone(number):
		return false
	set_flag("stage%d_stone_collected" % number)
	if number == 2:
		_sync_chapter2_quests()
		save_game()
	progression_changed.emit()
	return true


func selected_skill() -> StringName:
	return StringName(str(_journey.get("skill", "")))


## The seating choice is permanent until New Game. Re-selecting it is harmless.
func choose_skill(skill_id: StringName) -> bool:
	if skill_id not in [&"fist", &"poison"] or not is_chapter_unlocked(2):
		return false
	if selected_skill() != &"" and selected_skill() != skill_id:
		return false
	_journey["skill"] = String(skill_id)
	_sync_chapter2_quests()
	save_game()
	progression_changed.emit()
	return true


func enter_chapter2_room() -> void:
	if not is_chapter_unlocked(2):
		return
	_quest_stages["enter_room_417"] = QUEST_STAGE_COMPLETE
	_sync_chapter2_quests()
	save_game()


func _sync_chapter2_quests() -> void:
	if not is_chapter_unlocked(2):
		return
	if has_time_stone(2):
		_quest_stages["enter_room_417"] = QUEST_STAGE_COMPLETE
		_quest_stages["choose_room417_seat"] = QUEST_STAGE_COMPLETE
		_quest_stages["chapter2_quiz"] = QUEST_STAGE_COMPLETE
		if not has_completed_quest("reach_room_416"):
			_quest_stages["reach_room_416"] = QUEST_STAGE_ACTIVE
	elif selected_skill() != &"":
		_quest_stages["choose_room417_seat"] = QUEST_STAGE_COMPLETE
		_quest_stages["chapter2_quiz"] = QUEST_STAGE_ACTIVE
	elif has_completed_quest("enter_room_417"):
		_quest_stages["choose_room417_seat"] = QUEST_STAGE_ACTIVE
	quests_changed.emit()


func has_quest_item(item_id: String) -> bool:
	var items: Dictionary = _journey.get("items", {})
	return bool(items.get(item_id, false))


func try_room416_code(code: String) -> bool:
	if not is_chapter_unlocked(3) or not has_flag("room416_help_requested") or code != "2006":
		return false
	_flags["room416_unlocked"] = true
	save_game()
	flag_changed.emit("room416_unlocked", true)
	return true


func finish_room416_rescue() -> void:
	if not is_chapter_unlocked(3) or not has_flag("room416_unlocked"):
		return
	_flags["room416_rescue_complete"] = true
	_quest_stages["reach_room_416"] = QUEST_STAGE_COMPLETE
	_quest_stages["unlock_room_416"] = QUEST_STAGE_COMPLETE
	if not has_completed_quest("reach_room_419"):
		_quest_stages["reach_room_419"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	flag_changed.emit("room416_rescue_complete", true)


func receive_room419_lead() -> bool:
	if not is_chapter_unlocked(3) or not has_flag("room416_rescue_complete") or has_flag("room419_lead_received"):
		return false
	_flags["room419_lead_received"] = true
	_quest_stages["reach_room_419"] = QUEST_STAGE_COMPLETE
	if not has_completed_quest("find_thay_tuan"):
		_quest_stages["find_thay_tuan"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	flag_changed.emit("room419_lead_received", true)
	return true


func grant_quest_item(item_id: String) -> bool:
	if item_id.is_empty() or has_quest_item(item_id) or has_flag("delivered:" + item_id):
		return false
	var items: Dictionary = _journey.get("items", {}).duplicate()
	items[item_id] = true
	_journey["items"] = items
	save_game()
	progression_changed.emit()
	return true


## Consumed items remain recorded as delivered and cannot be awarded again.
func deliver_quest_item(item_id: String) -> bool:
	if not has_quest_item(item_id) or has_flag("delivered:" + item_id):
		return false
	_flags["delivered:" + item_id] = true
	var items: Dictionary = _journey.get("items", {}).duplicate()
	items[item_id] = false
	_journey["items"] = items
	save_game()
	flag_changed.emit("delivered:" + item_id, true)
	progression_changed.emit()
	return true


func place_time_stone(number: int) -> bool:
	if not has_time_stone(number) or has_flag("gate_stone_%d" % number):
		return false
	set_flag("gate_stone_%d" % number)
	return true


func complete_ending() -> bool:
	for number in range(1, 5):
		if not has_time_stone(number) or not has_flag("gate_stone_%d" % number):
			return false
	if has_flag("ending_complete"):
		return false
	_flags["ending_complete"] = true
	_flags["hidden_ending_complete" if boss_resolution() == "spared" else "normal_ending_complete"] = true
	if boss_resolution() == "spared":
		_flags["badge_debug_together"] = true
	_quest_stages["activate_time_gate"] = QUEST_STAGE_COMPLETE
	save_game()
	quests_changed.emit()
	flag_changed.emit("ending_complete", true)
	return true


func boss_resolution() -> String:
	# Old victorious saves keep their original normal route.
	return str(_journey.get("boss_resolution", "win"))


func can_start_activity(activity_id: String) -> bool:
	if activity_id not in ACTIVITY_IDS:
		return false
	if activity_id == "boss_fight":
		return is_chapter_unlocked(4) and selected_skill() != &""
	if activity_id == "fit_runner_race":
		return is_chapter_unlocked(3) and has_flag("room419_lead_received") and has_flag("tuan_identity_verified")
	return true


func activity_result(activity_id: String) -> Dictionary:
	var value: Variant = _activity_results.get(activity_id, {})
	return value.duplicate(true) if value is Dictionary else {}


## Record once per emitted attempt, immediately (not on Continue).
## Stone handover stays with story NPCs; an activity pass completes its quest.
func record_activity_result(activity_id: String, result: Dictionary) -> bool:
	if not can_start_activity(activity_id):
		return false
	if activity_id in ["fit_runner", "fit_runner_race"]:
		var expected_mode := 1 if activity_id == "fit_runner_race" else 0
		if int(result.get("race_mode", expected_mode)) != expected_mode:
			return false
	var previous := activity_result(activity_id)
	var passed := bool(result.get("passed", false))
	if activity_id == "boss_fight":
		var outcome := str(result.get("outcome", "win" if passed else ""))
		passed = outcome in ["win", "spared"]
		if passed and not _journey.has("boss_resolution"):
			_journey["boss_resolution"] = "win" if has_completed_quest("boss_fight") else outcome
	if activity_id == "fit_runner_race":
		passed = passed and bool(result.get("completed", false)) and int(result.get("placement", 99)) <= 3
	var entry := {
		"attempts": int(previous.get("attempts", 0)) + 1,
		"failures": int(previous.get("failures", 0)) + (0 if passed else 1),
		"passed": bool(previous.get("passed", false)) or passed,
		"last_result": result.duplicate(true),
		"best_stars": maxi(int(previous.get("best_stars", 0)), int(result.get("stars", 0))),
		"best_score": maxi(int(previous.get("best_score", 0)), maxi(0, int(result.get("score", 0)))) if passed else int(previous.get("best_score", 0)),
	}
	_activity_results[activity_id] = entry
	var newly_complete := passed and not has_completed_quest(activity_id)
	var previous_stage := quest_stage(activity_id)
	if newly_complete:
		_quest_stages[activity_id] = QUEST_STAGE_COMPLETE
		if activity_id == "fit_runner_race":
			_quest_stages["return_to_tuan"] = QUEST_STAGE_ACTIVE
		if activity_id == "boss_fight":
			_quest_stages["claim_boss_reward"] = QUEST_STAGE_ACTIVE
	save_game()
	if newly_complete:
		quest_stage_changed.emit(activity_id, previous_stage, QUEST_STAGE_COMPLETE)
	progression_changed.emit()
	return true


func verify_tuan_identity() -> bool:
	if not is_chapter_unlocked(3) or not has_flag("room419_lead_received") or quiz_session_id != "tuan_identity" or quiz_session_score != 3 or quiz_session_total != 3:
		return false
	_flags["tuan_identity_verified"] = true
	_quest_stages["find_thay_tuan"] = QUEST_STAGE_COMPLETE
	if not has_completed_quest("fit_runner_race"):
		_quest_stages["fit_runner_race"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	return true


func claim_tuan_documents() -> bool:
	if not has_completed_quest("fit_runner_race") or not has_flag("tuan_identity_verified") or has_flag("tuan_documents_claimed"):
		return false
	_flags["tuan_documents_claimed"] = true
	var items: Dictionary = _journey.get("items", {}).duplicate()
	items["marathon_documents"] = true
	_journey["items"] = items
	_quest_stages["return_to_tuan"] = QUEST_STAGE_COMPLETE
	_quest_stages["deliver_marathon_documents"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	progression_changed.emit()
	return true


func hand_over_marathon_documents() -> bool:
	if not is_chapter_unlocked(3) or not has_quest_item("marathon_documents") or has_flag("delivered:marathon_documents") or has_time_stone(3):
		return false
	var items: Dictionary = _journey.get("items", {}).duplicate()
	items["marathon_documents"] = false
	_journey["items"] = items
	_flags["delivered:marathon_documents"] = true
	_flags["stage3_stone_collected"] = true
	_quest_stages["deliver_marathon_documents"] = QUEST_STAGE_COMPLETE
	_quest_stages["rescue_faculty_head"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	flag_changed.emit("stage3_stone_collected", true)
	progression_changed.emit()
	return true


func claim_boss_rescue_stone() -> bool:
	if not is_chapter_unlocked(4) or not has_completed_quest("boss_fight") or has_time_stone(4):
		return false
	_flags["stage4_stone_collected"] = true
	_flags["faculty_head_rescued"] = true
	_quest_stages["rescue_faculty_head"] = QUEST_STAGE_COMPLETE
	_quest_stages["claim_boss_reward"] = QUEST_STAGE_COMPLETE
	_quest_stages["activate_time_gate"] = QUEST_STAGE_ACTIVE
	save_game()
	quests_changed.emit()
	flag_changed.emit("stage4_stone_collected", true)
	progression_changed.emit()
	return true


## A checkpoint always names a host scene, never a minigame scene.
func set_return_point(scene_path: String, position: Vector2) -> bool:
	if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path, "PackedScene"):
		return false
	_journey["return_point"] = {"scene": scene_path, "position": position}
	save_game()
	return true


func return_point() -> Dictionary:
	var value: Variant = _journey.get("return_point", {})
	return value.duplicate(true) if value is Dictionary else {}


# Save data ----------------------------------------------------------------------

func save_game() -> void:
	var save_file := ConfigFile.new()
	save_file.set_value(STATE_SECTION, "version", SAVE_VERSION)
	save_file.set_value(STATE_SECTION, "npc_stages", _npc_stages)
	save_file.set_value(STATE_SECTION, "quest_stages", _quest_stages)
	save_file.set_value(STATE_SECTION, "quest_details", _quest_details)
	save_file.set_value(STATE_SECTION, "flags", _flags)
	save_file.set_value(STATE_SECTION, "quiz_results", _quiz_results)
	save_file.set_value(STATE_SECTION, "journey", _journey)
	save_file.set_value(STATE_SECTION, "activity_results", _activity_results)

	var error := save_file.save(save_path)
	last_save_error = error
	if error != OK:
		push_error("Could not save game state to %s (error %s)." % [save_path, error])
		save_failed.emit(error)
		return
	state_saved.emit()


func load_game() -> void:
	var save_file := ConfigFile.new()
	if save_file.load(save_path) != OK:
		return # First launch: all accessors use their default values.

	_npc_stages = _read_dictionary(save_file, "npc_stages")
	_quest_stages = _read_dictionary(save_file, "quest_stages")
	_quest_details = _read_dictionary(save_file, "quest_details")
	_flags = _read_dictionary(save_file, "flags")
	_quiz_results = _read_dictionary(save_file, "quiz_results")
	_journey = _read_dictionary(save_file, "journey")
	_activity_results = _read_dictionary(save_file, "activity_results")
	_sync_chapter2_quests()
	quests_changed.emit()


## Starts a fresh game while keeping this autoload alive.
func reset_progress() -> void:
	_npc_stages.clear()
	_quest_stages.clear()
	_quest_details.clear()
	quests_changed.emit()
	_flags.clear()
	_quiz_results.clear()
	_journey.clear()
	_activity_results.clear()
	quiz_session_id = ""
	quiz_session_score = 0
	quiz_session_total = 0
	save_game()
	progression_changed.emit()


func _read_dictionary(save_file: ConfigFile, key: String) -> Dictionary:
	var value: Variant = save_file.get_value(STATE_SECTION, key, {})
	return value.duplicate(true) if value is Dictionary else {}


# QuestManager API: GameState remains the single persistent source of truth.
const QUEST_CATALOG = {
	"meet_minh": ["Một nơi xa lạ", "Di chuyển tới thầy Dũng gần cổng trường và tương tác để hỏi chuyện."],
	"stage1_challenge": ["Viên đá đầu tiên", "Hoàn thành một thử thách rồi trở lại gặp giảng viên trước Nhà C."],
	"reach_building_c": ["Đến Nhà C", "Đi tới tòa nhà màu xanh phía trên bản đồ và gặp giảng viên trước cửa."],
	"enter_room_417": ["Phòng 417", "Đi đến phòng học 417."],
	"choose_room417_seat": ["Chọn chỗ ngồi", "Trò chuyện với nhóm phía trước hoặc cuối lớp và chọn chỗ ngồi."],
	"chapter2_quiz": ["Bài kiểm tra FIT", "Gặp giảng viên ở Phòng 417C, trả lời đúng 5/5 câu để nhận viên đá thứ hai."],
	"reach_room_416": ["Đến Phòng 416", "Sang Phòng 416 tìm giảng viên để tiếp tục hành trình."],
	"unlock_room_416": ["Mở cửa Phòng 416", "Nhập năm thành lập FIT vào bảng mã để giúp giảng viên mở cửa."],
	"reach_room_419": ["Đến Phòng 419", "Tìm giảng viên Truyền thông Đa phương tiện ở Phòng 419, tầng 4 Nhà C."],
	"find_thay_tuan": ["Tìm thầy Khánh", "Tìm thầy Khánh mặc áo marathon gần đường chạy ở sân thể thao."],
	"fit_runner_race": ["Cuộc đua sân thể thao", "Về đích trong ba vị trí đầu ở Ghost Race rồi quay lại gặp thầy Khánh."],
	"return_to_tuan": ["Nhận tài liệu", "Trở lại gặp thầy Khánh ở sân thể thao để nhận tài liệu."],
	"deliver_marathon_documents": ["Giao tài liệu", "Mang chương trình lễ kỷ niệm tới giảng viên phụ trách lễ kỷ niệm, bên ngoài Văn phòng Khoa 210C."],
	"rescue_faculty_head": ["Biến cố tại Văn phòng Khoa", "Tìm hiểu tiếng động tại Văn phòng Khoa 210C và đánh bại CON BUG để giải cứu thầy Trưởng khoa."],
	"claim_boss_reward": ["Giải cứu thành công", "Trở lại cửa Văn phòng Khoa 210C để gặp thầy Trưởng khoa và nhận viên đá cuối cùng."],
	"activate_time_gate": ["Cánh Cửa Thời Gian", "Mang đủ bốn Viên Đá Thời Gian tới cổng thời gian tại Văn phòng Khoa."],
	"garbage_quest": ["Dọn rác", "Hoàn thành thử thách phân loại rác."],
	"fit_runner": ["Đường chạy FIT", "Hoàn thành thử thách chạy."],
	"boss_fight": ["CON BUG", "Đánh bại CON BUG."],
}


func quest_info(id: String) -> Dictionary:
	var defaults: Array = QUEST_CATALOG.get(id, [id.replace("_", " ").capitalize(), "Hoàn thành nhiệm vụ."])
	var data: Dictionary = _quest_details.get(id, {}).duplicate(true)
	data["id"] = id
	data["title"] = data.get("title", defaults[0])
	data["objective"] = data.get("objective", defaults[1])
	data["target"] = maxi(int(data.get("target", 1)), 1)
	data["completed"] = has_completed_quest(id)
	data["progress"] = data["target"] if data["completed"] else clampi(int(data.get("progress", 0)), 0, int(data["target"]))
	return data


func tracked_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _quest_stages:
		if quest_stage(id) != QUEST_STAGE_INACTIVE:
			var data := quest_info(id)
			if not bool(data.get("hidden", false)):
				result.append(data)
	return result


## Updates display metadata without reopening a completed quest.
func add_quest(id: String, title: String, objective: String, target: int = 1) -> void:
	if id.is_empty():
		return
	var data := quest_info(id)
	data.merge({"title": title, "objective": objective, "target": maxi(target, 1)}, true)
	data["progress"] = clampi(int(data["progress"]), 0, int(data["target"]))
	_quest_details[id] = data
	if quest_stage(id) == QUEST_STAGE_INACTIVE:
		start_quest(id)
	else:
		quests_changed.emit()
	save_game()


## Absolute counter. Complex objectives may call complete_quest directly.
func update_quest_progress(id: String, amount: int) -> void:
	if not is_quest_active(id):
		return
	var data := quest_info(id)
	data["progress"] = clampi(amount, 0, int(data["target"]))
	_quest_details[id] = data
	if int(data["progress"]) >= int(data["target"]):
		complete_quest(id)
	else:
		quests_changed.emit()
		save_game()


func update_quest_objective(id: String, objective: String) -> void:
	var data := quest_info(id)
	data["objective"] = objective
	_quest_details[id] = data
	quests_changed.emit()
	save_game()


## Prefer hiding completed quests: their completion still gates story dialogues.
func hide_quest(id: String, hidden: bool = true) -> void:
	var data := quest_info(id)
	data["hidden"] = hidden
	_quest_details[id] = data
	quests_changed.emit()
	save_game()


## Explicit deletion removes completion as well as display data.
func remove_quest(id: String) -> void:
	var previous := quest_stage(id)
	_quest_details.erase(id)
	_quest_stages.erase(id)
	quest_stage_changed.emit(id, previous, QUEST_STAGE_INACTIVE)
	save_game()
