extends SceneTree
const ROUTES = preload("res://scenes/UI/quests/quest_destination.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func finish_dialogue() -> void:
	var balloon: Node
	for attempt in 30:
		await create_timer(0.05).timeout
		for node in current_scene.get_children():
			if "dialogue_line" in node and "dialogue_label" in node: balloon = node
		if balloon != null: break
	check(balloon != null, "Dialogue opens")
	var turns := 0
	while is_instance_valid(balloon) and balloon.dialogue_line != null and turns < 35:
		var line = balloon.dialogue_line
		if not line.responses.is_empty():
			var index := 2 if line.responses.size() == 4 else 0
			balloon.next(line.responses[index].next_id)
		else:
			balloon.next(line.next_id)
		turns += 1
		await create_timer(0.03).timeout
	await create_timer(0.3).timeout
	check(turns < 35, "Dialogue exits normally")
func press_interact() -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://reconnected_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	change_scene_to_file("res://scenes/mapsides/t_4.tscn")
	await create_timer(0.4).timeout
	var player = current_scene.get_node("Character")
	var keypad = current_scene.get_node("SceneDoor2")
	var door419 = current_scene.get_node("Room419Door")
	check(ROUTES.resolve(current_scene, "reach_room_416")[0].node == keypad, "416 marker uses new door")
	check(ROUTES.resolve(current_scene, "reach_room_419")[0].node == door419, "419 marker uses conversation door")
	player.position = keypad.position + Vector2(0, 40)
	await create_timer(0.15).timeout
	press_interact()
	await finish_dialogue()
	check(state.has_flag("room416_help_requested"), "416 hint starts puzzle")
	press_interact()
	await process_frame
	check(keypad._panel != null, "416 keypad opens from actual interaction")
	keypad._code.text = "2006"
	keypad._submit()
	await finish_dialogue()
	check(state.has_flag("room416_rescue_complete"), "416 code and rescue complete")
	player.position = door419.position + Vector2(28, -8)
	check(not door419._professor.visible, "Tuấn starts inside 419")
	await create_timer(0.15).timeout
	press_interact()
	await finish_dialogue()
	check(state.has_flag("room419_lead_received"), "Tuấn gives Khánh's field lead")
	check(door419._professor.visible and door419._professor.mode == 0, "Tuấn emerges and stays stationary")
	check(door419._professor.position == Vector2(50, 0), "Tuấn finishes on corridor side of doorway")
	# Classroom entrance and exit use the user's new floor-4 door and arrival.
	var room = current_scene.get_node("SceneDoor")
	player.position = room.position + Vector2(0, -30)
	await create_timer(0.2).timeout
	press_interact()
	var deadline := Time.get_ticks_msec() + 30000
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/mapsides/phòng_máy_2.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/mapsides/phòng_máy_2.tscn", "Floor4 classroom entrance works")
	for floor in [2, 3]:
		var map = load("res://scenes/mapsides/t_%d.tscn" % floor).instantiate()
		check(map.find_children("RoomNumberSign", "Node2D", true, false).size() == 16, "Sixteen signs on floor %d" % floor)
		check(not ROUTES.resolve(map, "rescue_faculty_head").is_empty(), "Boss or stair waypoint on floor %d" % floor)
		map.free()
	DirAccess.remove_absolute(state.save_path)
	print("Reconnected rooms: %d failures" % failures)
	quit(0 if failures == 0 else 1)
