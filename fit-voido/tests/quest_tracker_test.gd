extends SceneTree
var failures := 0
var state: Node
var hud: CanvasLayer

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	await process_frame
	await process_frame

func expect(id: String) -> void:
	await settle()
	check(str(hud.current_objective.get("id", "")) == id, "Next action should be " + id)

func run() -> void:
	state = root.get_node("GameState")
	hud = root.get_node("QuestTracker")
	state.save_path = "user://journal_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var host := Node2D.new()
	host.add_to_group("quest_hud_host")
	root.add_child(host)
	current_scene = host
	await settle()
	hud._update_scene()
	check(hud.visible, "Journal visible in exploration")
	check(hud.current_objective.is_empty(), "Empty save gets neutral exploration copy")
	state.start_quest("meet_minh")
	await expect("meet_minh")
	state.complete_quest("meet_minh")
	state.set_flag("intro_complete")
	state.start_quest("reach_building_c")
	await expect("reach_building_c")
	state.select_stage1_activity("fit_runner")
	await expect("fit_runner")
	state.record_activity_result("fit_runner", {"passed": true, "race_mode": 0})
	await expect("stage1_challenge")
	state.claim_stage1_stone()
	await expect("enter_room_417")
	check(hud.stones.get_child(0).owned and not hud.stones.get_child(1).owned, "First stone changes artwork without filling later sockets")
	state.enter_chapter2_room()
	await expect("choose_room417_seat")
	state.choose_skill(&"poison")
	await expect("chapter2_quiz")
	state.record_quiz_result("chapter2_fit_quiz", 5, 5)
	await settle()
	check(hud.objective.text.contains("5/5"), "Perfect quiz directs player to reward handoff")
	state.award_time_stone(2)
	await expect("reach_room_416")
	state.set_flag("room416_help_requested")
	await expect("unlock_room_416")
	state.try_room416_code("2006")
	await settle()
	check(hud.objective.text.contains("Cửa đã mở"), "Unlocked door directs player to rescue conversation")
	state.finish_room416_rescue()
	await expect("reach_room_419")
	state.receive_room419_lead()
	await expect("find_thay_tuan")
	state.quiz_begin("tuan_identity", 3)
	for i in range(3):
		state.quiz_mark(true)
	state.verify_tuan_identity()
	await expect("fit_runner_race")
	state.record_activity_result("fit_runner_race", {"passed": true, "race_mode": 1, "completed": true, "placement": 2})
	await expect("return_to_tuan")
	state.claim_tuan_documents()
	await expect("deliver_marathon_documents")
	state.hand_over_marathon_documents()
	await expect("rescue_faculty_head")
	# Old active flags must not pull the player back to earlier chapters.
	state.start_quest("reach_building_c")
	await expect("rescue_faculty_head")
	state.record_activity_result("boss_fight", {"outcome": "spared", "passed": true})
	await expect("claim_boss_reward")
	state.claim_boss_rescue_stone()
	await expect("activate_time_gate")
	for i in range(1, 5):
		state.place_time_stone(i)
	state.complete_ending()
	await expect("journey_complete")
	check(hud.count.text == "4 / 4", "Stone count is accurate")
	for stone in hud.stones.get_children():
		check(stone.owned and stone.placed, "Placed stones retain earned state")
	state.load_game()
	await expect("journey_complete")
	# Presentation changes never remove quest history.
	check(state.has_completed_quest("meet_minh"), "Completed quests remain saved")
	hud.toggle.button_pressed = true
	await settle()
	check(not hud.details.visible and hud.stones.is_visible_in_tree(), "Collapsed journal keeps stone progress")
	hud.toggle.button_pressed = false
	root.get_node("DialogueManager").dialogue_started.emit(null)
	check(not hud.details.visible, "Dialogue temporarily folds journal")
	root.get_node("DialogueManager").dialogue_ended.emit(null)
	check(hud.details.visible and not hud.toggle.button_pressed, "Dialogue restores expanded preference")
	hud.toggle.button_pressed = true
	root.get_node("DialogueManager").dialogue_started.emit(null)
	root.get_node("DialogueManager").dialogue_ended.emit(null)
	check(not hud.details.visible, "Dialogue preserves manual collapse")
	hud.toggle.button_pressed = false
	for size in [Vector2i(960, 540), Vector2i(640, 360), Vector2i(1280, 720), Vector2i(540, 960)]:
		root.content_scale_size = size
		root.size = size
		hud._resize()
		await settle()
		var screen := root.get_visible_rect()
		check(screen.encloses(hud.panel.get_global_rect()), "Journal fits viewport " + str(size))
		check(hud.toggle.size.x >= 44 and hud.toggle.size.y >= 44, "Collapse target stays touch-sized")
	hud._fold_preference_set = false
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	hud._resize()
	await settle()
	check(not hud.details.visible and hud.heading.text == hud.title.text, "Small screen defaults compact but retains current objective title")
	check(hud.panel.size.y < 140, "Compact mobile journal leaves room for play")
	hud.toggle.button_pressed = false
	check(hud.details.visible, "Small screen can expand objective details")
	check(hud.get_node("Root").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Full-screen root passes game input")
	check(hud.panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Journal does not block movement or touch drag")
	check(hud.toggle.focus_mode == Control.FOCUS_NONE, "Collapse button does not steal gameplay focus")
	host.remove_from_group("quest_hud_host")
	hud._update_scene()
	check(not hud.visible, "Non-exploration scenes hide journal")
	state.reset_progress()
	state.add_quest("optional", "Collect", "Collect ten items", 10)
	state.update_quest_progress("optional", 3)
	await expect("optional")
	check(hud.counter.visible and hud.counter.text == "3 / 10", "Generic counters still work")
	state.update_quest_objective("optional", "Updated objective")
	await settle()
	check(hud.objective.text == "Updated objective", "Authoring metadata still refreshes")
	state.complete_quest("optional")
	await settle()
	check(hud.current_objective.is_empty(), "Completed generic quest is not shown")
	state.reset_progress()
	await settle()
	check(hud.count.text == "0 / 4", "New Game clears stone artwork and count")
	DirAccess.remove_absolute(state.save_path)
	host.queue_free()
	await settle()
	print("Journey journal: %d failures" % failures)
	quit(1 if failures else 0)
