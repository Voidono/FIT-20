extends Node
## Persistent, dialogue-friendly progress state.
##
## Add this file as the `GameState` autoload. Dialogue Manager can then read
## conditions and call mutations such as:
##   if GameState.npc_stage("coach_mira") == "new":
##   set GameState.set_npc_stage("coach_mira", "met")

signal npc_stage_changed(npc_id: String, previous_stage: String, new_stage: String)
signal quest_stage_changed(quest_id: String, previous_stage: String, new_stage: String)
signal flag_changed(flag_id: String, value: bool)
signal quiz_result_recorded(quiz_id: String, result: Dictionary)
signal state_saved

const SAVE_PATH := "user://game_state.cfg"
const STATE_SECTION := "progress"

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
var _flags: Dictionary = {}
var _quiz_results: Dictionary = {}


func _ready() -> void:
	load_game()


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


# Save data ----------------------------------------------------------------------

func save_game() -> void:
	var save_file := ConfigFile.new()
	save_file.set_value(STATE_SECTION, "npc_stages", _npc_stages)
	save_file.set_value(STATE_SECTION, "quest_stages", _quest_stages)
	save_file.set_value(STATE_SECTION, "flags", _flags)
	save_file.set_value(STATE_SECTION, "quiz_results", _quiz_results)

	var error := save_file.save(SAVE_PATH)
	if error != OK:
		push_error("Could not save game state to %s (error %s)." % [SAVE_PATH, error])
		return
	state_saved.emit()


func load_game() -> void:
	var save_file := ConfigFile.new()
	if save_file.load(SAVE_PATH) != OK:
		return # First launch: all accessors use their default values.

	_npc_stages = _read_dictionary(save_file, "npc_stages")
	_quest_stages = _read_dictionary(save_file, "quest_stages")
	_flags = _read_dictionary(save_file, "flags")
	_quiz_results = _read_dictionary(save_file, "quiz_results")


## Starts a fresh game while keeping this autoload alive.
func reset_progress() -> void:
	_npc_stages.clear()
	_quest_stages.clear()
	_flags.clear()
	_quiz_results.clear()
	save_game()


func _read_dictionary(save_file: ConfigFile, key: String) -> Dictionary:
	var value: Variant = save_file.get_value(STATE_SECTION, key, {})
	return value.duplicate(true) if value is Dictionary else {}
