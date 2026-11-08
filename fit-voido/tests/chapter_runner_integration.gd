extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://chapter_runner_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	check(not state.can_start_activity("fit_runner_race"), "Chapter 1 cannot start Ghost Race")
	check(not state.record_activity_result("fit_runner", {"race_mode": 1, "passed": true}), "Race result cannot count as Practice")
	state.record_activity_result("fit_runner", {"race_mode": 0, "passed": true})
	check(state.can_claim_stage1_stone(), "Practice earns chapter one eligibility")
	check(not state.has_completed_quest("fit_runner_race"), "Practice cannot complete chapter three")
	state.claim_stage1_stone()
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	state.set_flag("room419_lead_received")
	state.quiz_begin("tuan_identity", 3)
	state.quiz_mark(true)
	check(not state.verify_tuan_identity(), "Failed identity quiz cannot unlock race")
	state.quiz_mark(true)
	state.quiz_mark(true)
	check(state.verify_tuan_identity(), "Perfect identity quiz unlocks race")
	check(not state.record_activity_result("fit_runner_race", {"race_mode": 0, "passed": true}), "Practice cannot count under race ID")
	state.record_activity_result("fit_runner_race", {"race_mode": 1, "passed": true, "completed": true, "placement": 4})
	check(not state.has_completed_quest("fit_runner_race"), "Non-podium cannot pass")
	check(not state.claim_tuan_documents(), "No document before podium")
	state.record_activity_result("fit_runner_race", {"race_mode": 1, "passed": true, "completed": true, "placement": 3})
	check(state.is_quest_active("return_to_tuan"), "Podium activates document handoff")
	check(state.claim_tuan_documents(), "Podium allows document claim")
	check(not state.claim_tuan_documents(), "No duplicate documents")
	state.record_activity_result("fit_runner_race", {"race_mode": 1, "passed": false})
	check(state.has_completed_quest("fit_runner_race"), "Failed replay preserves race success")
	state.load_game()
	check(state.has_quest_item("marathon_documents") and state.is_quest_active("deliver_marathon_documents"), "Document and delivery objective persist")
	var config := FitRunnerConfig.new()
	config.race_mode = 1
	config.lock_mode = true
	var game = load("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd").create(config)
	root.add_child(game)
	game.set_process(false)
	game.select_mode(0)
	check(game.race_mode == 1 and game.rivals.size() == 5, "Story host prevents switching to practice")
	check(not game._hud._mode_buttons[0].visible and not game._hud._result_panel._mode_menu.visible, "Story mode selectors hidden")
	var manager = root.get_node("DialogueManager")
	var resource = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/chapter3_tuan.dialogue"))
	check(resource != null, "Khánh field dialogue compiles")
	var line = await manager.get_next_dialogue_line(resource, "start")
	check(line != null and line.character == "Thầy Khánh" and line.text.contains("thầy Ngọc"), "Khánh directs document delivery to Ngọc")
	game.queue_free()
	DirAccess.remove_absolute(state.save_path)
	await process_frame
	print("Chapter runner integration: %d failures" % failures)
	quit(1 if failures else 0)
