extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://sign_preview_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	for row in [["t_4", Vector2(2910, 295)], ["t_2", Vector2(2560, 300)]]:
		change_scene_to_file("res://scenes/mapsides/%s.tscn" % row[0])
		await create_timer(0.3).timeout
		var player = current_scene.get_node("Character")
		player.position = row[1]
		var camera := Camera2D.new()
		current_scene.add_child(camera)
		camera.position = row[1]
		camera.make_current()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/room_signs_%s.png" % row[0])
	DirAccess.remove_absolute(state.save_path)
	quit()
