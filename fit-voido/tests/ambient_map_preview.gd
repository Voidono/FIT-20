extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://ambient_preview_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.set_flag("intro_complete")
	root.get_node("QuestTracker").hide()
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	for id in ["nửa đầu", "t_2", "t_3", "t_4"]:
		var map = load("res://scenes/mapsides/%s.tscn" % id).instantiate()
		root.add_child(map)
		current_scene = map
		var camera := Camera2D.new()
		map.add_child(camera)
		camera.position = Vector2(2200, -350) if id == "nửa đầu" else Vector2(1700, 280)
		camera.zoom = Vector2.ONE * (0.185 if id == "nửa đầu" else 0.44)
		camera.make_current()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/ambient_overview_%s.png" % ("campus" if id == "nửa đầu" else id))
		if id == "nửa đầu":
			root.size = Vector2i(960, 540)
			root.content_scale_size = root.size
			camera.zoom = Vector2.ONE
			var player = map.get_node("Map/Character")
			var npc = map.get_node("CampusLife/wifi")
			player.global_position = npc.global_position + Vector2(0, 26)
			camera.global_position = npc.global_position + Vector2(100, 0)
			await create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/ambient_campus_closeup.png")
			npc._on_body_entered(player)
			npc.talk()
			await create_timer(0.2).timeout
			var balloon: Node
			for child in map.get_children():
				if "dialogue_label" in child and "dock" in child:
					balloon = child
			if balloon != null:
				balloon.dialogue_label.skip_typing()
				await create_timer(0.2).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://tests/ambient_food_dialogue.png")
				while is_instance_valid(balloon) and balloon.dialogue_line != null:
					var line = balloon.dialogue_line
					balloon.next(line.next_id if line.responses.is_empty() else line.responses[0].next_id)
					await create_timer(0.1).timeout
				await create_timer(0.4).timeout
			root.size = Vector2i(1600, 1000)
			root.content_scale_size = root.size
		map.free()
		await process_frame
	DirAccess.remove_absolute(state.save_path)
	quit()
