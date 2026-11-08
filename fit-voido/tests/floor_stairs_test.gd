extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://floor_stairs_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var failures := 0
	for route in [[2, 3, "StairsToFloor3"], [3, 4, "StairsToFloor4"], [4, 3, "StairsDownToFloor3"], [3, 2, "StairsDownToFloor2"]]:
		var floor_number: int = route[0]
		var target_floor: int = route[1]
		var path := "res://scenes/mapsides/t_%d.tscn" % floor_number
		change_scene_to_file(path)
		await process_frame
		await process_frame
		if current_scene == null:
			push_error("Floor scene did not load")
			quit(1)
			return
		var player = get_first_node_in_group("player")
		var stairs = current_scene.find_child(route[2], true, false)
		var stair_position: Vector2 = stairs.global_position
		var arrival: Vector2 = stairs.target_position
		player.global_position = stair_position + Vector2(0, 100)
		await create_timer(0.4).timeout
		player.global_position = stair_position
		await create_timer(0.3).timeout
		if current_scene.scene_file_path != path:
			push_error("Walking into stairs must not transport the player")
			quit(1)
			return
		var press := InputEventAction.new()
		press.action = &"interact"
		press.pressed = true
		Input.parse_input_event(press)
		var deadline := Time.get_ticks_msec() + 15000
		var expected := "res://scenes/mapsides/t_%d.tscn" % target_floor
		while (current_scene == null or current_scene.scene_file_path != expected) and Time.get_ticks_msec() < deadline:
			await process_frame
		await create_timer(0.4).timeout
		player = get_first_node_in_group("player")
		if current_scene == null or current_scene.scene_file_path != expected or player == null or player.position.distance_to(arrival) > 2:
			failures += 1
			push_error("Floor %d transition or arrival failed" % floor_number)
		await create_timer(0.5).timeout
		if current_scene.scene_file_path != expected:
			failures += 1
			push_error("Arrival triggered an unwanted second transition")
	DirAccess.remove_absolute(state.save_path)
	print("Floor stairs: %d failures" % failures)
	quit(1 if failures else 0)
