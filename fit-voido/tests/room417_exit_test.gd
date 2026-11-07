extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://room417_exit_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.award_time_stone(1)
	state.award_time_stone(2)
	change_scene_to_file("res://scenes/mapsides/phòng_máy_2.tscn")
	await process_frame
	await process_frame
	var door = current_scene.get_node("SceneDoor")
	var player = get_first_node_in_group("player")
	player.global_position = door.global_position
	await create_timer(0.5).timeout
	if current_scene.scene_file_path != "res://scenes/mapsides/phòng_máy_2.tscn":
		push_error("Classroom exit must wait for interaction")
		quit(1)
		return
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	var deadline := Time.get_ticks_msec() + 15000
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/mapsides/t_4.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	await create_timer(0.5).timeout
	player = get_first_node_in_group("player")
	if current_scene == null or current_scene.scene_file_path != "res://scenes/mapsides/t_4.tscn" or player.position.distance_to(Vector2(2723, 390)) > 2:
		push_error("Classroom exit did not arrive at corrected hallway position")
		quit(1)
		return
	# Check the actual player collider against map walls, then move away normally.
	var collider = player.get_node("CollisionShape2D") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	if not player.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
		push_error("Hallway arrival intersects a wall")
		quit(1)
		return
	var start: Vector2 = player.position
	player.velocity = Vector2(0, 100)
	player.move_and_collide(Vector2(0, 24))
	if player.position.y < start.y + 20:
		push_error("Cannot walk away from the classroom exit")
		quit(1)
		return
	player.position = Vector2(2723, 390)
	await create_timer(0.2).timeout
	Input.parse_input_event(press)
	deadline = Time.get_ticks_msec() + 15000
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/mapsides/phòng_máy_2.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://scenes/mapsides/phòng_máy_2.tscn":
		push_error("Classroom door cannot be interacted with from the walkable corridor")
		quit(1)
		return
	DirAccess.remove_absolute(state.save_path)
	print("PASS: explicit classroom exit, clear arrival, walking away, and reentry from corridor")
	quit()
