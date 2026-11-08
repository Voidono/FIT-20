extends SceneTree
const OFFICE := "res://scenes/mapsides/phòng210.tscn"
const HOST := "res://scenes/UI/activity_host.tscn"
var failures := 0
var state: Node
var loader: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func prepare() -> void:
	state.reset_progress()
	state.set_flag("intro_complete")
	state.award_time_stone(1)
	state.choose_skill(&"poison")
	state.award_time_stone(2)
	state.award_time_stone(3)
func wait_scene(path: String) -> void:
	var deadline := Time.get_ticks_msec() + 60000
	while (current_scene == null or current_scene.scene_file_path != path) and Time.get_ticks_msec() < deadline:
		await process_frame
	await create_timer(0.25).timeout
	check(current_scene != null and current_scene.scene_file_path == path, "Arrived at " + path)
func interact() -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
func forward_office(until_battle: bool) -> void:
	for i in 250:
		await create_timer(0.04).timeout
		if current_scene == null: continue
		if current_scene.scene_file_path == HOST and until_battle: return
		if current_scene.scene_file_path != OFFICE: continue
		var room := current_scene
		if not room.cinematic_running and not until_battle: return
		var balloon = room._balloon
		if is_instance_valid(balloon) and balloon.dialogue_line != null:
			check(balloon.dialogue_line.responses.is_empty(), "Cinematic has no fight/leave choice")
			balloon.next(balloon.dialogue_line.next_id)
	check(false, "Office sequence completed in time")
func snapshot(name: String) -> void:
	if "render" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/office210_%s.png" % name)
func use_gate(outcome: String) -> void:
	var room := current_scene
	room.player.position = Vector2(440, 162)
	room.teacher._on_body_entered(room.player)
	room.teacher.talk()
	await create_timer(0.1).timeout
	var balloon: Node
	for child in room.get_children():
		if "dialogue_line" in child and "dock" in child: balloon = child
	check(balloon != null and balloon.dialogue_line.responses.size() == 2, "Rescued teacher offers gate / stay options")
	balloon.next(balloon.dialogue_line.responses[0].next_id)
	await wait_scene("res://scenes/chapters/time_gate.tscn")
	var gate := current_scene
	for slot in gate._slots: slot.pressed.emit()
	gate._activate.pressed.emit()
	check(gate._lines.size() == (5 if outcome == "spared" else 3), "Correct ending after office rescue")
	for i in gate._lines.size(): gate._next()
	check(state.has_flag("ending_complete"), "Gate completes new flow")
	check(state.has_flag("badge_debug_together") == (outcome == "spared"), "Hidden ending badge preserved")
func run() -> void:
	state = root.get_node("GameState")
	loader = root.get_node("SceneLoader")
	state.save_path = "user://office210_flow_%d.cfg" % Time.get_ticks_usec()
	prepare()
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	change_scene_to_file("res://scenes/mapsides/t_2.tscn")
	await wait_scene("res://scenes/mapsides/t_2.tscn")
	var player = current_scene.get_node("Character")
	var entrance = current_scene.get_node("Doors/210door/FacultyBossDoor")
	var hallway_position: Vector2 = entrance.global_position + Vector2(0, 37)
	player.global_position = hallway_position
	await create_timer(0.2).timeout
	interact()
	await wait_scene(OFFICE)
	check(loader.activity_id.is_empty(), "Door enters office before battle")
	var room := current_scene
	check(room.cinematic_running and not room.player.can_move, "Entrance freezes movement")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = room.player.get_node("CollisionShape2D").shape
	query.transform = room.player.get_node("CollisionShape2D").global_transform
	query.collision_mask = room.player.collision_mask
	query.exclude = [room.player.get_rid()]
	check(room.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Office arrival is clear of furniture and walls")
	var before: Vector2 = room.bug.position
	await create_timer(0.7).timeout
	check(room.bug.position.distance_to(before) > 3, "CON BUG rampages")
	check(room._panic_label.visible, "Thang is panicking")
	check(is_instance_valid(room._balloon), "Dialogue starts automatically")
	if is_instance_valid(room._balloon): room._balloon.dialogue_label.skip_typing()
	await snapshot("intro")
	var first_line: String = room._balloon.dialogue_line.id
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	await snapshot("intro_phone")
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	await create_timer(3.5).timeout
	check(room._balloon.dialogue_line.id != first_line, "Cinematic advances without input")
	await forward_office(true)
	await wait_scene(HOST)
	check(state.has_flag("room210_intro_seen"), "Introduction saved")
	check(state.return_point().scene == OFFICE, "Boss checkpoint is inside office")
	check(current_scene._game != null and not current_scene._intro_open, "Fight starts without a second entry menu")
	state.record_activity_result("boss_fight", {"outcome": "win", "passed": true, "score": 1200})
	loader.return_from_minigame()
	await wait_scene(OFFICE)
	await forward_office(false)
	check(state.has_time_stone(4), "Rescue awards stone four inside office")
	check(not current_scene.bug.visible and not current_scene._panic_label.visible, "Victory calms room")
	check(current_scene.player.can_move, "Rescue restores control")
	await snapshot("rescued")
	await use_gate("win")
	# A replay/Spare return retains the hidden ending and a friendly boss.
	prepare()
	state.record_activity_result("boss_fight", {"outcome": "spared", "passed": true, "score": 0})
	change_scene_to_file(OFFICE)
	await create_timer(0.3).timeout
	await forward_office(false)
	check(state.has_time_stone(4) and state.boss_resolution() == "spared", "Spare rescue retains hidden ending")
	check(current_scene.bug.visible and current_scene.bug.scale == Vector2.ONE, "Spared boss stays small and calm")
	await snapshot("spared")
	await use_gate("spared")
	# Returning after quitting must not force the player straight back into battle.
	prepare()
	state.set_flag("room210_intro_seen")
	change_scene_to_file(OFFICE)
	await create_timer(0.5).timeout
	room = current_scene
	check(not room.cinematic_running and room.player.can_move, "Revisit allows leaving or retrying")
	var bug = room.bug
	room.player.global_position = bug.global_position + Vector2(0, 35)
	bug._on_body_entered(room.player)
	bug.talk()
	await forward_office(true)
	await wait_scene(HOST)
	check(state.return_point().scene == OFFICE, "Retry also returns to office")
	loader.return_from_minigame()
	await wait_scene(OFFICE)
	await create_timer(0.3).timeout
	check(current_scene.player.can_move and not current_scene.cinematic_running, "Backing out avoids retry loop")
	current_scene.player.position = Vector2(256, 300)
	await create_timer(0.15).timeout
	interact()
	await wait_scene("res://scenes/mapsides/t_2.tscn")
	check(current_scene.get_node("Character").position.distance_to(hallway_position) < 2, "Exit restores the same hallway approach")
	# The entrance remains a story gate before the third stone.
	state.reset_progress()
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	interact()
	await create_timer(0.15).timeout
	check(current_scene.scene_file_path.ends_with("t_2.tscn"), "Locked entrance stays in hallway")
	var locked_balloon: Node
	for child in current_scene.get_children():
		if "dialogue_line" in child and "dock" in child: locked_balloon = child
	check(locked_balloon != null, "Locked entrance explains prerequisite")
	if locked_balloon != null: locked_balloon.next(locked_balloon.dialogue_line.next_id)
	await create_timer(0.35).timeout
	check(current_scene.get_node("Character").can_move, "Locked-door dialogue releases movement")
	# 419 uses its own talking-door prefab, not the new office entrance.
	var floor4 = load("res://scenes/mapsides/t_4.tscn").instantiate()
	check(floor4.get_node("Room419Door").get_script().resource_path.ends_with("room419_door.gd"), "419 conversation preserved")
	floor4.free()
	DirAccess.remove_absolute(state.save_path)
	print("Office 210 flow: %d failures" % failures)
	quit(0 if failures == 0 else 1)
