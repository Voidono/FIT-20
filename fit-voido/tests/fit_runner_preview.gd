extends SceneTree
## Render the actual game, not a UI mock. Pass -- --out=absolute-directory.
var output_dir: String = "user://"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output_dir = arg.trim_prefix("--out=")
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	TranslationServer.set_locale("en")
	var game: FitRunner = load("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd").create()
	root.add_child(game)
	game.set_process(false)
	await capture("practice_ready")
	game.select_mode(1)
	game._begin_run()
	var planner: FrParBot = FrParBot.build(game.tuning)
	while game.model.progress() < 0.13:
		game._push_held = game.effort_input.effort < planner._target_hold_release(game.model)
		game._sim_tick()
	game._update_views(0)
	game._refresh_hud(0)
	await capture("race_running")
	game._qte.trigger_checkpoint()
	game._qte.elapsed = game._qte.settings.duration * 0.35
	game._refresh_hud(0)
	await capture("race_qte")
	game._qte.reset(1)
	TranslationServer.set_locale("vi")
	game._refresh_hud(0)
	await capture("race_vi")
	while game.phase == FrRunState.Phase.RUNNING:
		game._push_held = game.effort_input.effort < planner._target_hold_release(game.model)
		if game._qte.is_active():
			game._qte.elapsed = game._qte.target_center * game._qte.settings.duration
			game._on_qte_button_pressed()
		game._sim_tick()
	game._update_views(0)
	game._refresh_hud(0)
	await capture("race_result_vi")
	game.select_mode(0)
	root.content_scale_size = Vector2i(640, 360)
	TranslationServer.set_locale("en")
	await capture("practice_small")
	game._begin_run()
	game._hud._speed_button.show()
	game._hud._qte_button.show()
	game._update_views(0)
	game._refresh_hud(0)
	await capture("race_touch_small")
	game.free()
	print("PASS: rendered seven FIT Runner previews")
	quit()

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = output_dir.path_join("fit_runner_%s.png" % label)
	var error: Error = root.get_texture().get_image().save_png(path)
	if error != OK: push_error("Preview could not save: " + path)
