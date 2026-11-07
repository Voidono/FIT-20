extends SceneTree
var failures := 0
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
	q.collide_with_areas = false
	return npc.get_world_2d().direct_space_state.intersect_shape(q).is_empty()

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://ambient_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.set_flag("intro_complete")
	var manager = root.get_node("DialogueManager")
	var source := FileAccess.get_file_as_string("res://Dialogues/campus_banter.dialogue")
	check(not source.contains("GameState") and not source.contains("\nset ") and not source.contains("\ndo "), "Banter cannot change quests")
	var resource = manager.create_resource_from_text(source)
	var names: Array[String] = []
	var people := 0
	var conversations := 0
	var professors: Array[String] = []
	for location in ["campus", "t_2", "t_3", "t_4"]:
		var path: String = "nửa đầu" if location == "campus" else location
		var map = load("res://scenes/mapsides/%s.tscn" % path).instantiate()
		root.add_child(map)
		current_scene = map
		await create_timer(0.1).timeout
		var cast = map.get_node("CampusLife").get_children()
		for npc in cast:
			people += 1
			check(npc.dialogue != null, "Imported dialogue for " + npc.name)
			check(not names.has(npc.npc_name), "Unique nickname " + npc.npc_name)
			names.append(npc.npc_name)
			check(clear_at(npc, npc.global_position), "Walkable spawn: " + location + "/" + npc.name + " " + str(npc.position))
			if location != "campus":
				var floor_tiles = map.get_node("sàn")
				check(floor_tiles.get_cell_source_id(floor_tiles.local_to_map(floor_tiles.to_local(npc.global_position))) != -1, "On corridor floor: " + location + "/" + npc.name)
			if npc.npc_skin.is_empty():
				check(npc.mode == 0, "Static art stays stationary: " + npc.name)
			else:
				check(npc.mode != 0 and npc._has_anim, "Walking art is animated: " + npc.name)
				for direction in ["down", "up", "left", "right"]:
					check(npc.anim_sprite.sprite_frames.get_frame_count("walk_" + direction) >= 3, "Walk frames: " + npc.name)
			if npc.mode == 2:
				check(npc.patrol_points.size() >= 2 and npc.ping_pong, "Ping-pong route: " + npc.name)
				for offset in npc.patrol_points:
					for i in range(1, 9):
						var spot: Vector2 = npc._home.lerp(npc._home + offset, i / 8.0)
						check(clear_at(npc, spot), "Clear route: " + location + "/" + npc.name + " " + str(spot - map.global_position))
			if npc.mode == 1:
				for i in 16:
					var spot: Vector2 = npc._home + Vector2.from_angle(TAU * i / 16) * npc.wander_radius
					check(clear_at(npc, spot), "Clear wander area: " + location + "/" + npc.name + " " + str(spot - map.global_position))
			for other in cast:
				if other == npc: continue
				if npc.npc_sprite.resource_path == other.npc_sprite.resource_path:
					check(npc.position.distance_to(other.position) >= 600, "Reused sprites separated: " + npc.name + "/" + other.name)
			for cue in npc.conversation_cues:
				conversations += 1
				var line = await manager.get_next_dialogue_line(resource, cue)
				var count := 0
				while line != null and count < 12:
					check(line.responses.is_empty(), "Banter is conversation, not a quest menu")
					count += 1
					line = await manager.get_next_dialogue_line(resource, line.next_id)
				check(count >= 3 and count < 12, "Complete exchange: " + cue)
		# Professor artwork stays unique, including the existing classroom lecturer.
		for npc in map.find_children("*", "Area2D", true, false):
			if "npc_sprite" in npc and npc.npc_sprite != null and npc.npc_skin.is_empty():
				var portrait: String = npc.npc_sprite.resource_path.get_file()
				if portrait in ["Dũng.png", "Ngọc.png", "QKhánh.png", "Thắng.png", "Tuấn.png", "Tùng.png"]:
					check(not professors.has(portrait), "Professor portrait unique: " + portrait)
					professors.append(portrait)
		await create_timer(5.0).timeout
		for npc in cast:
			if npc.mode == 0:
				check(npc.global_position == npc._home, "Stationary actor stays in place: " + npc.name)
			else:
				check(npc.global_position.distance_to(npc._home) > 1, "Animated actor actually walks: " + location + "/" + npc.name)
		if location == "campus":
			var npc = map.get_node("CampusLife/wifi")
			var player = map.get_node("Map/Character")
			var previous_cue := ""
			for attempt in 2:
				player.global_position = npc.global_position + Vector2(0, 26)
				npc._on_body_entered(player)
				npc.talk()
				await create_timer(0.1).timeout
				check(npc._is_talking and npc._wait_timer.paused and not player.can_move, "Conversation pauses walker and player")
				check(npc.cue != previous_cue, "Repeat interaction chooses a different exchange")
				previous_cue = npc.cue
				var balloon: Node
				for child in map.get_children():
					if "dialogue_label" in child and "dock" in child: balloon = child
				check(balloon != null, "Real dialogue bubble opens")
				if balloon != null:
					for i in 3:
						balloon.next(balloon.dialogue_line.next_id)
						await create_timer(0.08).timeout
					await create_timer(0.35).timeout
				check(not npc._is_talking and player.can_move and not npc._wait_timer.paused, "Conversation releases player and resumes route")
		map.free()
		await process_frame
	check(people == 42 and conversations == 84, "Full campus cast and dialogue variants")
	var classroom = load("res://scenes/mapsides/phòng_máy_2.tscn").instantiate()
	var lecturer = classroom.get_node("DialogueNPC")
	var lecturer_portrait: String = lecturer.npc_sprite.resource_path.get_file()
	check(not professors.has(lecturer_portrait), "Classroom professor is not reused as an ambient character")
	professors.append(lecturer_portrait)
	check(professors.size() == 6, "Six distinct professor portraits")
	classroom.free()
	DirAccess.remove_absolute(state.save_path)
	print("Ambient campus: %d NPCs, %d conversations, %d failures" % [people, conversations, failures])
	quit(0 if failures == 0 else 1)
