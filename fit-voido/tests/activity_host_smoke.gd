extends SceneTree
## Launch each real activity through the host using disposable progression.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state = root.get_node("GameState")
	var loader = root.get_node("SceneLoader")
	state.save_path = "user://activity_smoke_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.award_time_stone(1)
	state.choose_skill(&"poison")
	state.award_time_stone(2)
	state.award_time_stone(3)
	state.set_flag("room419_lead_received")
	state.set_flag("tuan_identity_verified")
	change_scene_to_file("res://tests/fixtures/return_scene.tscn")
	await create_timer(0.1).timeout
	for id in ["garbage_quest", "fit_runner", "fit_runner_race", "boss_fight"]:
		var player := get_first_node_in_group("player") as Node2D
		player.global_position = Vector2(123, 456)
		if loader.start_minigame(id) != OK:
			push_error("Activity launch refused: " + id)
			quit(1)
			return
		await create_timer(1.6).timeout
		var host := current_scene
		if host.get("_game") == null:
			push_error("Activity did not launch: " + id)
			quit(1)
			return
		print("LAUNCHED: " + id)
		if id in ["fit_runner", "fit_runner_race"]:
			var expected_mode := 1 if id == "fit_runner_race" else 0
			if host._game.race_mode != expected_mode or not host._game.lock_mode:
				push_error("Incorrect story race mode: " + id)
				quit(1)
				return
		# Exercise real result adapters, with a controlled synthetic success.
		if id == "boss_fight":
			var result = load("res://Minigames/boss_fight/boss_fight_result.gd").new()
			result.outcome = &"win"
			host.call("_on_boss_finished", result)
		else:
			var result_path := "res://Minigames/trash_train_v3/trash_train/run_result.gd" if id == "garbage_quest" else "res://Minigames/minigames/fit_runner/scripts/api/fit_runner_result.gd"
			var result = load(result_path).new()
			result.passed = true
			result.stars = 2
			if id == "fit_runner_race":
				result.race_mode = 1
				result.completed = true
				result.placement = 2
			host.call("_on_run_finished", result)
		if not state.has_completed_quest(id):
			push_error("Result did not complete quest: " + id)
			quit(1)
			return
		host.call("_return_to_host")
		await create_timer(1.3).timeout
		player = get_first_node_in_group("player") as Node2D
		if player == null or player.global_position != Vector2(123, 456):
			push_error("Return position not restored: " + id)
			quit(1)
			return
		print("RETURNED: " + id)
	loader.activity_id = ""
	DirAccess.remove_absolute(state.save_path)
	print("PASS: all four activities launched, story modes locked, results recorded, and return positions restored")
	quit(0)
