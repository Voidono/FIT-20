extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://live_flow_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.set_flag("intro_complete")
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	var routes := [
		["t_2", "StairsToFloor3"],
		["t_3", "StaticBody2D2/CollisionShape2D/StairsToFloor4"],
		["t_4", "StairsDownToFloor3"],
		["t_3", "StaticBody2D2/CollisionShape2D/StairsToFloor4/StairsDownToFloor2"],
		["phòng_máy_2", "SceneDoor"],
		["nửa đầu", "Area/Area2D"],
		["t_2", "CampusEntrance"]]
	for route in routes:
		if "campus-return" in OS.get_cmdline_user_args() and route != ["t_2", "CampusEntrance"]: continue
		change_scene_to_file("res://scenes/mapsides/%s.tscn" % route[0])
		await create_timer(0.4).timeout
		var scene := current_scene
		var door = scene.get_node(route[1])
		var expected: String = load(door.target_scene).resource_path
		var arrival: Vector2 = door.target_position
		var player = get_first_node_in_group("player")
		var shape = door.get_node("CollisionShape2D")
		player.global_position = shape.global_position
		await create_timer(0.3).timeout
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = true
		Input.parse_input_event(event)
		var deadline := Time.get_ticks_msec() + 60000
		while (current_scene == null or current_scene.scene_file_path != expected) and Time.get_ticks_msec() < deadline:
			await process_frame
		await create_timer(0.35).timeout
		player = get_first_node_in_group("player")
		var ok := current_scene != null and current_scene.scene_file_path == expected
		if ok: ok = player.position.distance_to(arrival) < 3
		if not ok: failures += 1
		print("LIVE ", route, " -> ", expected.get_file(), " configured arrival ", arrival, " result=", ok)
		if not ok:
			print("  Actual scene=", current_scene.scene_file_path if current_scene != null else "none", " player=", player.position if player != null else Vector2.ZERO)
		if ok:
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = player.get_node("CollisionShape2D").shape
			query.transform = player.get_node("CollisionShape2D").global_transform
			query.collision_mask = player.collision_mask
			query.exclude = [player.get_rid()]
			var hits = player.get_world_2d().direct_space_state.intersect_shape(query)
			print("  Arrival blocked=", not hits.is_empty())
			if not hits.is_empty(): failures += 1
	DirAccess.remove_absolute(state.save_path)
	print("LIVE FLOW failures: ", failures)
	quit(0 if failures == 0 else 1)
