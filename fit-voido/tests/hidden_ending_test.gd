extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://hidden_ending_%d.cfg" % Time.get_ticks_usec()
	for outcome in ["win", "spared"]:
		state.reset_progress()
		check(not state.complete_ending(), "Cannot end without stones")
		state.award_time_stone(1)
		state.choose_skill(&"poison")
		state.award_time_stone(2)
		state.award_time_stone(3)
		state.record_activity_result("boss_fight", {"outcome": outcome, "passed": outcome == "win", "score": 1500 if outcome == "win" else 0})
		check(state.has_completed_quest("boss_fight"), "Both outcomes rescue")
		var manager = root.get_node("DialogueManager")
		var dialogue = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/minigame_battle.dialogue"))
		var line = await manager.get_next_dialogue_line(dialogue, "start")
		var turns := 0
		while line != null and turns < 20:
			turns += 1
			line = await manager.get_next_dialogue_line(dialogue, line.next_id)
		check(state.has_time_stone(4), "Both rescue dialogues award fourth stone")
		state.record_activity_result("boss_fight", {"outcome": "win" if outcome == "spared" else "spared", "passed": true})
		check(state.boss_resolution() == outcome, "Replay preserves original ending route")
		check(not state.complete_ending(), "Gate requires placement")
		var gate = load("res://scenes/chapters/time_gate.tscn").instantiate()
		root.add_child(gate)
		await process_frame
		check(gate._activate.disabled, "Gate disabled before stones placed")
		for i in range(4):
			gate._slots[i].pressed.emit()
		check(not gate._activate.disabled, "Gate opens after placement")
		gate._activate.pressed.emit()
		var expected := 5 if outcome == "spared" else 3
		check(gate._lines.size() == expected, "Correct epilogue branch")
		for i in range(expected):
			gate._next()
		check(state.has_flag("ending_complete"), "Epilogue saves completion")
		check(state.has_flag("badge_debug_together") == (outcome == "spared"), "Hidden ending awards separate badge")
		state.load_game()
		check(state.boss_resolution() == outcome and state.has_flag("ending_complete"), "Ending survives restart")
		check(state.activity_result("boss_fight").best_score == (1500 if outcome == "win" else 0), "Spare does not earn combat points")
		if "render" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/ending_%s.png" % outcome)
		gate.queue_free()
		await process_frame
	DirAccess.remove_absolute(state.save_path)
	print("Hidden ending: %d failures" % failures)
	quit(1 if failures else 0)
