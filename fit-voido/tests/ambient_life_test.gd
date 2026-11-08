extends SceneTree
## Sparse cast, every choice branch, real walking/talking, and unique story portraits.
var failures := 0
var conversations := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func clear_at(npc: Node2D, point: Vector2) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = 9
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0, point + Vector2(0, 2))
	q.collision_mask = 1
	q.exclude = [npc.get_node("Body").get_rid()]
	return npc.get_world_2d().direct_space_state.intersect_shape(q).is_empty()
func follow(resource: Resource, cue: String, choice: int) -> void:
	var manager = root.get_node("DialogueManager")
	var line = await manager.get_next_dialogue_line(resource, cue)
	var count := 0
	var choices := 0
	while line != null and count < 20:
		count += 1
		var next: String = line.next_id
		if not line.responses.is_empty():
			choices += 1
			check(line.responses.size() >= 2, "Pickable replies: " + cue)
			next = line.responses[mini(choice, line.responses.size() - 1)].next_id
		line = await manager.get_next_dialogue_line(resource, next)
	check(count >= 2 and count < 20 and choices >= 1, "Choice branch terminates: " + cue)
func close_bubble(map: Node) -> void:
	var balloon: Node
	for child in map.get_children():
		if "dialogue_label" in child and "dock" in child: balloon = child
	check(balloon != null, "Real dialogue opens")
	if balloon == null: return
	for i in 20:
		if not is_instance_valid(balloon) or balloon.dialogue_line == null: break
		var line = balloon.dialogue_line
		balloon.next(line.next_id if line.responses.is_empty() else line.responses[0].next_id)
		await create_timer(0.04).timeout
	await create_timer(0.3).timeout
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://cast_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.set_flag("intro_complete")
	var source := FileAccess.get_file_as_string("res://Dialogues/campus_banter.dialogue")
	check(not source.contains("GameState") and not source.contains("\nset ") and not source.contains("\ndo "), "Banter never changes quests")
	var manager = root.get_node("DialogueManager")
	var resource = manager.create_resource_from_text(source)
	var names: Array[String] = []
	var professors: Array[String] = []
	var people := 0
	var campus_only := "campus-only" in OS.get_cmdline_user_args()
	var locations := ["campus"] if campus_only else ["campus", "t_2", "t_3", "t_4"]
	for location in locations:
		var path: String = "nửa đầu" if location == "campus" else location
		var map = load("res://scenes/mapsides/%s.tscn" % path).instantiate()
		root.add_child(map)
		current_scene = map
		await create_timer(0.15).timeout
		var cast = map.get_node("CampusLife").get_children()
		check(cast.size() == (9 if location == "campus" else 2), "Population count " + location)
		var positions := {}
		for npc in cast:
			people += 1
			positions[npc.name] = npc.global_position
			check(not names.has(npc.npc_name), "Unique nickname " + npc.npc_name)
			names.append(npc.npc_name)
			var static_guest: bool = npc.name == "chairman_afk"
			if static_guest:
				check(location == "campus" and npc.mode == 0 and npc.npc_skin.is_empty() and npc.npc_sprite.resource_path.ends_with("/T1.png"), "Stationary T1 guest")
			else:
				check(npc.npc_skin in ["NPC_1", "NPC_2", "boykopho"] and npc.mode != 0 and npc._has_anim, "Animated walking skin " + npc.name)
			check(clear_at(npc, npc.global_position), "Walkable spawn " + location + "/" + npc.name + " " + str(npc.position))
			if location != "campus":
				var tiles = map.find_child("sàn", true, false)
				check(tiles.get_cell_source_id(tiles.local_to_map(tiles.to_local(npc.global_position))) != -1, "On corridor floor " + location + "/" + npc.name)
			if not static_guest:
				for direction in ["down", "up", "left", "right"]:
					check(npc.anim_sprite.sprite_frames.get_frame_count("walk_" + direction) >= 3, "Full walking animation " + npc.name)
			if npc.mode == 2:
				for offset in npc.patrol_points:
					for i in range(1, 9):
						var point: Vector2 = npc._home.lerp(npc._home + offset, i / 8.0)
						check(clear_at(npc, point), "Clear patrol " + location + "/" + npc.name + " " + str(point - map.global_position))
			elif npc.mode == 1:
				for i in 16:
					var point: Vector2 = npc._home + Vector2.from_angle(TAU * i / 16) * npc.wander_radius
					check(clear_at(npc, point), "Clear wandering " + location + "/" + npc.name + " " + str(point - map.global_position))
			for cue in npc.conversation_cues:
				conversations += 1
				for branch in 2: await follow(resource, cue, branch)
		for actor in map.find_children("*", "Area2D", true, false):
			if "npc_name" in actor and actor.npc_name.begins_with("Thầy "):
				check(not professors.has(actor.npc_name), "Unique professor " + actor.npc_name)
				professors.append(actor.npc_name)
				check(actor.mode == 0 and actor.npc_skin.is_empty(), "Professor stays stationary " + actor.npc_name)
		var furthest := {}
		for npc in cast: furthest[npc.name] = 0.0
		for sample in 12:
			await create_timer(0.5).timeout
			for npc in cast:
				furthest[npc.name] = maxf(furthest[npc.name], npc.global_position.distance_to(positions[npc.name]))
		for npc in cast:
			if npc.mode == 0:
				check(furthest[npc.name] == 0, "Stationary guest stays in place")
			else:
				check(furthest[npc.name] > 1, "Actually walks " + location + "/" + npc.name)
		if location == "campus":
			check(map.get_node("DialogueNPC").position == Vector2(3260,359), "Khánh position unchanged")
			check(map.get_node("DialogueNPC").npc_sprite.resource_path.ends_with("/khanh.png"), "Khánh field portrait unchanged")
			var npc = map.get_node("CampusLife/wifi")
			var player = map.get_node("Map/Character")
			var previous := ""
			for attempt in 2:
				player.global_position = npc.global_position + Vector2(0,26)
				npc._on_body_entered(player)
				npc.talk()
				await create_timer(0.1).timeout
				check(npc._is_talking and npc._wait_timer.paused and not player.can_move, "Conversation freezes walker and player")
				check(npc.cue != previous, "Next conversation varies")
				previous = npc.cue
				await close_bubble(map)
				check(not npc._is_talking and player.can_move and not npc._wait_timer.paused, "Conversation resumes movement")
		map.free()
		await process_frame
	if campus_only:
		check(people == 9 and conversations == 18, "Eight outdoor walkers and one stationary guest, eighteen conversations")
		DirAccess.remove_absolute(state.save_path)
		print("Outdoor campus: %d NPCs, %d conversations, %d failures" % [people, conversations, failures])
		quit(0 if failures == 0 else 1)
		return
	var office = load("res://scenes/mapsides/phòng210.tscn").instantiate()
	check(office.get_node("DialogueNPC").npc_sprite.resource_path.ends_with("/Thắng.png"), "Thắng unchanged in office")
	professors.append("Thầy Thắng")
	office.free()
	var classroom = load("res://scenes/mapsides/phòng_máy_2.tscn").instantiate()
	check(classroom.get_node("DialogueNPC").npc_name == "Giảng viên thỉnh giảng", "417 guest lecturer")
	check(not classroom.get_node("DialogueNPC").npc_sprite.resource_path.ends_with("/Tùng.png"), "417 doesn't duplicate Tùng")
	classroom.free()
	check(professors.size() == 6, "All six professors assigned once")
	check(people == 15 and conversations == 30, "Fourteen walkers and one stationary guest, thirty choice conversations")
	DirAccess.remove_absolute(state.save_path)
	print("Campus recast: %d walkers, %d conversations, %d failures" % [people,conversations,failures])
	quit(0 if failures == 0 else 1)
