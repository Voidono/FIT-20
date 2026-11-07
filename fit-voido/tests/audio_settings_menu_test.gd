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
	state.save_path = "user://settings_menu_progress_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var settings = root.get_node("Setting")
	var previous: Array = [settings.get_master_volume(), settings.get_music_volume(), settings.get_effects_volume()]
	settings.save_path = "user://settings_menu_audio_%d.cfg" % Time.get_ticks_usec()
	var scene := Node2D.new()
	scene.scene_file_path = "res://tests/fixtures/return_scene.tscn"
	root.add_child(scene)
	current_scene = scene
	var player = load("res://scenes/Character/Character.tscn").instantiate()
	scene.add_child(player)
	for dimensions in [Vector2i(960, 540), Vector2i(640, 360), Vector2i(540, 960)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		player._on_button_pressed()
		await create_timer(0.1).timeout
		var panel = player._menu_panel
		check(paused, "Opening menu pauses gameplay")
		check(panel.sliders.size() == 3, "Three audio controls")
		check(panel._card.size.x <= dimensions.x - 24, "Card fits viewport")
		panel.sliders[0].value = 0.42
		panel.sliders[1].value = 0.21
		panel.sliders[2].value = 0.0
		check(is_equal_approx(settings.get_master_volume(), 0.42), "Master slider adjusts bus")
		check(is_equal_approx(settings.get_music_volume(), 0.21), "Music slider adjusts bus")
		check(settings.get_effects_volume() == 0.0, "Zero effects mutes bus")
		settings.load_settings()
		check(is_equal_approx(settings.get_music_volume(), 0.21), "Audio preferences survive reload")
		if "render" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/audio_menu_%dx%d.png" % [dimensions.x, dimensions.y])
		panel.close()
		await process_frame
		check(not paused, "Resume unpauses world")
	player._on_button_pressed()
	await process_frame
	player._menu_panel.queue_free()
	await process_frame
	check(not paused, "Teardown cannot leave tree paused")
	var standalone = load("res://scenes/menu & options/setting_game.tscn").instantiate()
	scene.add_child(standalone)
	await process_frame
	check(not paused and standalone.panel.sliders.size() == 3, "Title settings uses same audio panel without pause")
	standalone.free()
	settings.set_master_volume(previous[0])
	settings.set_music_volume(previous[1])
	settings.set_effects_volume(previous[2])
	DirAccess.remove_absolute(settings.save_path)
	player._on_button_pressed()
	player._menu_panel.return_to_menu()
	check(not paused and root.get_node("SceneLoader").target_scene == root.get_node("SceneLoader").MENU, "Return saves and opens main menu")
	await process_frame
	DirAccess.remove_absolute(state.save_path)
	print("Audio settings menu: %d failures" % failures)
	quit(0 if failures == 0 else 1)
