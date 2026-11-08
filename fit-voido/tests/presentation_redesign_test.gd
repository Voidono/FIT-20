extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func capture(id: String) -> void:
	await process_frame
	await process_frame
	if "render" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/redesign_%s.png" % id)
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://presentation_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	for dimensions in [Vector2i(960, 540), Vector2i(640, 360), Vector2i(540, 960), Vector2i(360, 640)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var tag := "%dx%d" % [dimensions.x, dimensions.y]
		var menu = load("res://scenes/menu & options/menu.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		await capture("menu_" + tag)
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(menu.play_button.get_global_rect()), "Start button visible " + tag)
		menu.free()
		for number in range(1, 5): state.award_time_stone(number)
		var gate = load("res://scenes/chapters/time_gate.tscn").instantiate()
		root.add_child(gate)
		current_scene = gate
		for slot in gate._slots: slot.pressed.emit()
		await capture("gate_" + tag)
		check(not gate._activate.disabled, "Gate unlocks after four stones")
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(gate._activate.get_global_rect()), "Open gate visible " + tag)
		gate.free()
		var result := BossFightResult.new()
		result.outcome = &"win"
		result.difficulty = load("res://Minigames/boss_fight/data/difficulty/hard.tres")
		result.max_hp = 32
		result.final_hp = 26
		result.calculate_score()
		var screen = load("res://scenes/UI/boss_result_screen.gd").new()
		screen.result = result
		screen.best_score = result.score
		root.add_child(screen)
		current_scene = screen
		await capture("boss_" + tag)
		check(screen.return_button.size.y >= 48, "Return touch target")
		check(screen.return_button.get_global_rect().end.x <= dimensions.x, "Result fits width")
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(screen.return_button.get_global_rect()), "Return button visible " + tag)
		screen.free()
	DirAccess.remove_absolute(state.save_path)
	print("Presentation redesign: %d failures" % failures)
	quit(0 if failures == 0 else 1)
