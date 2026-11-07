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
		map.free()
		await process_frame
	DirAccess.remove_absolute(state.save_path)
	quit()
