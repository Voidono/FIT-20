extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://canopy_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var map = load("res://scenes/mapsides/nửa đầu.tscn").instantiate()
	root.add_child(map)
	current_scene = map
	var player = map.get_node("Map/Character")
	var button = player.get_node("ScreenUI/MenuButton")
	for dimensions in [Vector2i(640, 360), Vector2i(960, 540), Vector2i(1170, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await process_frame
		check(button.get_global_rect().end.x <= dimensions.x and button.position.x >= dimensions.x - 100, "Menu anchored to right")
		check(button.size.y >= 44, "Touch-sized menu button")
	var tree = map.get_node("Map/cây to")
	var fader = tree.get_node("OcclusionFader")
	check(fader.localized_canopy and not fader._canopy_materials.is_empty(), "Tree has local reveal materials")
	player.position = Vector2(2500, 100)
	fader._on_body_entered(player)
	await create_timer(0.3).timeout
	check(tree.modulate.a == 1.0, "Distant canopy remains opaque")
	check(fader._canopy_materials[0].get_shader_parameter("reveal_strength") > 0.99, "Reveal opens around player")
	fader._on_body_exited(player)
	await create_timer(0.3).timeout
	check(fader._canopy_materials[0].get_shader_parameter("reveal_strength") < 0.01, "Reveal closes on exit")
	if "render" in OS.get_cmdline_user_args():
		root.size = Vector2i(960, 540)
		root.content_scale_size = root.size
		# Locate an actual canopy trigger and move inside it.
		var shape = fader.get_child(0)
		player.global_position = shape.global_position
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/canopy_menu_fixed.png")
	DirAccess.remove_absolute(state.save_path)
	print("Canopy and menu: %d failures" % failures)
	quit(0 if failures == 0 else 1)
