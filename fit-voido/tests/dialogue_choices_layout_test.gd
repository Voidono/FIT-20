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
	state.save_path = "user://choices_layout_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	var manager = root.get_node("DialogueManager")
	for dimensions in [Vector2i(640, 360), Vector2i(960, 540), Vector2i(1900, 1080), Vector2i(540, 960)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var balloon = manager.show_dialogue_balloon_scene(load("res://Dialogues/Bubbles/pixel_balloon.tscn"), load("res://Dialogues/tutorial_arrival.dialogue"), "start")
		await create_timer(0.15).timeout
		balloon.dialogue_label.skip_typing()
		await create_timer(0.3).timeout
		check(balloon.responses_panel.size.x >= balloon.dock.size.x - 1, "Choices use dock width")
		check(balloon.responses_panel.size.y < 180, "Choices do not grow into a vertical strip")
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(balloon.dock.get_global_rect()), "Whole dialogue fits viewport")
		if "render" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/dialogue_choices_%dx%d.png" % [dimensions.x, dimensions.y])
		balloon.free()
		await process_frame
	DirAccess.remove_absolute(state.save_path)
	print("Dialogue choices layout: %d failures" % failures)
	quit(0 if failures == 0 else 1)
