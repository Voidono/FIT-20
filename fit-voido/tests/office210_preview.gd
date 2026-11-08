extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://office_preview_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	state.award_time_stone(3)
	state.set_flag("room210_intro_seen")
	root.size = Vector2i(960, 640)
	root.content_scale_size = root.size
	var scene = load("res://scenes/mapsides/phòng210.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var camera := Camera2D.new()
	scene.add_child(camera)
	var tiles = scene.get_node("TileMap")
	print("Office used rect ", tiles.get_used_rect(), " tile size ", tiles.tile_set.tile_size)
	camera.position = Vector2(250, 210)
	camera.zoom = Vector2.ONE
	camera.make_current()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/office210_layout.png")
	DirAccess.remove_absolute(state.save_path)
	quit()
