extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _require(value: bool, label: String) -> void:
	if not value:
		push_error("FAIL: " + label)
		quit(1)
		assert(value, label)

func _wait_for_scene(path: String) -> bool:
	var deadline := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.scene_file_path == path:
			await create_timer(0.35).timeout
			if current_scene != null and current_scene.scene_file_path == path:
				return true
		await create_timer(0.1).timeout
	push_error("Timed out loading " + path)
	quit(1)
	return false

func _run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "res://tests/chapter1_world_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	_require(change_scene_to_file("res://scenes/mapsides/nửa đầu.tscn") == OK, "campus loads")
	await create_timer(0.4).timeout
	var campus := current_scene
	var player := campus.get_node("Map/Character") as CharacterBody2D
	_require(player.position == campus.starting_position, "player starts at gate")
	_require(campus.get_node("NPC/Minh").position == campus.minh_position, "Minh near gate")
	_require(campus.get_node("NPC/Lecturer").position == campus.lecturer_position, "lecturer near Nhà C")
	_require(state.is_quest_active("meet_minh"), "first objective is Minh")
	for entry in [["start", campus.starting_position], ["Minh approach", campus.minh_position + Vector2(0, 40)], ["lecturer approach", campus.lecturer_position + Vector2(0, 40)]]:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = player.get_node("CollisionShape2D").shape
		query.transform = Transform2D(0, campus.to_global(entry[1]))
		query.collision_mask = player.collision_mask
		query.exclude = [player.get_rid()]
		var hits := player.get_world_2d().direct_space_state.intersect_shape(query)
		for hit in hits:
			print("BLOCKED ", entry[0], " by ", hit.collider.get_path())
		_require(hits.is_empty(), "walkable " + entry[0])
	print("PASS: campus staging and approach positions are walkable")
	var door := campus.get_node("Area/Area2D")
	door.call("_on_body_entered", player)
	_require(not door.get("_changing"), "door remains locked before stone")
	state.select_stage1_activity("fit_runner")
	state.record_activity_result("fit_runner", {"passed": true})
	_require(state.claim_stage1_stone(), "lecturer reward")
	player.global_position = campus.to_global(Vector2(300, 100))
	door.call("_on_body_entered", player)
	if not await _wait_for_scene("res://scenes/mapsides/t_2.tscn"):
		return
	var hall := current_scene
	var hall_player := hall.get_node("Character") as Node2D
	_require(hall_player.position == Vector2(2000, 100), "Nhà C arrival uses shared entrance")
	_require(not state.has_completed_quest("enter_room_417"), "hallway arrival does not complete room objective")
	_require(not hall.get_node("CampusEntrance").get("_armed"), "arrival cannot immediately exit again")
	# Step away from the shared threshold, then use the classroom door.
	hall_player.position = Vector2(2200, 250)
	await create_timer(0.1).timeout
	hall_player.position = Vector2(3100, 150)
	if not await _wait_for_scene("res://scenes/chapters/room_417.tscn"):
		return
	_require(current_scene.scene_file_path == "res://scenes/chapters/room_417.tscn", "unlocked entrance reaches Room 417")
	_require(state.has_completed_quest("enter_room_417"), "arrival completes objective")
	print("PASS: locked entrance, hallway arrival, and Room 417 doorway")
	var room_player := current_scene.get_node("Classroom/Character") as Node2D
	current_scene.get_node("Exit").call("_on_body_entered", room_player)
	if not await _wait_for_scene("res://scenes/mapsides/t_2.tscn"):
		return
	hall = current_scene
	hall_player = hall.get_node("Character")
	_require(hall_player.position == Vector2(3100, 210), "classroom exit returns safely in front of its hallway doorway")
	_require(not hall.get_node("Room417Door").get("_changing"), "room return cannot immediately reenter")
	hall_player.position = Vector2(2200, 250)
	await create_timer(0.1).timeout
	hall_player.position = Vector2(2000, 100)
	if not await _wait_for_scene("res://scenes/mapsides/nửa đầu.tscn"):
		return
	_require(current_scene.scene_file_path == "res://scenes/mapsides/nửa đầu.tscn", "classroom exit returns to campus")
	player = current_scene.get_node("Map/Character")
	_require(player.position == Vector2(1258, -850), "campus return restores safe location outside Nhà C")
	_require(not current_scene.get_node("Area/Area2D").get("_changing"), "return does not trigger immediate reentry")
	DirAccess.remove_absolute(state.save_path)
	# The same outside entrance can be used again after returning.
	current_scene.get_node("Area/Area2D").call("_on_body_entered", player)
	if not await _wait_for_scene("res://scenes/mapsides/t_2.tscn"):
		return
	_require(current_scene.get_node("Character").position == Vector2(2000, 100), "campus entrance supports reentry")
	print("PASS: campus ↔ Nhà C hallway ↔ Room 417, including reentry")
	quit(0)
