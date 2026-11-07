extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "res://scenes/mapsides/map.tscn"
	var area := Rect2(3275, 375, 2650, 1475)
	if "field" in OS.get_cmdline_user_args():
		path = "res://Minigames/trash_train_v3/trash_train/levels/Field.tscn"
		area = Rect2(-180, -285, 1440, 1220)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1200, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene = load(path).instantiate()
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	# Prevent game controllers and player cameras from running in this preview.
	strip_scripts(scene)
	viewport.add_child(scene)
	var camera := Camera2D.new()
	camera.position = area.get_center()
	camera.zoom = Vector2.ONE * minf(1200.0 / area.size.x, 720.0 / area.size.y)
	viewport.add_child(camera)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var suffix := "field" if "field" in OS.get_cmdline_user_args() else "campus"
	viewport.get_texture().get_image().save_png("res://tests/sports_%s.png" % suffix)
	quit()

func strip_scripts(node: Node) -> void:
	for child in node.get_children():
		strip_scripts(child)
	if node is Camera2D:
		node.enabled = false
	node.set_script(null)
