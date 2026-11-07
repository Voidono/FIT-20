extends SceneTree

const LAUNCHER = preload("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var config := FitRunnerConfig.new()
	var game: FitRunner = LAUNCHER.create(config)
	root.add_child(game)
	game.set_process(false)
	await process_frame
	check(game.rivals.is_empty() and game._ghost.visible, "Practice should show only the guide")
	var easy_width: float = game._qte.settings.good_width
	var normal_width: float = game._qte.preset_normal.good_width
	var easy_cutoff: float = game.cutoff_time
	var practice_rate: float = game.tuning.rate_recover
	var finish_count: Array[int] = [0]
	game.run_finished.connect(func(_result: FitRunnerResult) -> void: finish_count[0] += 1)
	game._begin_run()
	play_race(game)
	check(game.last_result != null and game.last_result.passed, "Tutorial should complete with steady pacing")
	check(game.last_result.qte_perfect == 4, "Both laps must trigger both bends")
	check(finish_count[0] == 1, "Only one result should be emitted per finish")
	# Exercise the player-facing result menu and tab signals, not just the API.
	game._hud._result_panel._mode_menu.pressed.emit()
	check(game.phase == FrRunState.Phase.READY, "Choose mode must return to the briefing")
	game._hud._mode_buttons[1].pressed.emit()
	check(game.rivals.size() == 5 and not game._ghost.visible, "Competition should replace guide with five rivals")
	check(game._qte.settings.good_width < easy_width, "Practice timing should be more forgiving")
	check(game.cutoff_time < easy_cutoff and game.tuning.rate_recover == practice_rate, "Modes share recovery but have different cutoff")
	check(game._qte.preset_normal.good_width == normal_width, "Switching must not mutate the shared normal preset")
	var times := PackedFloat32Array()
	for rival in game.rivals:
		times.append(rival.finish_time)
	print("RIVAL FINISH TIMES: ", times)
	check(absf(times[0] - times[2]) > 0.1, "Rivals must have distinct race plans")
	game._begin_run()
	game._speed_button_held = true
	game.toggle_pause()
	check(not game._speed_button_held, "Pausing must release touch input")
	var paused_time: float = game.model.elapsed
	game._process(0.1)
	check(game.model.elapsed == paused_time, "Pause must freeze race")
	game.toggle_pause()
	play_race(game)
	check(game.last_result.completed and game.last_result.entrants == 6, "Competition must finish and report the field size")
	check(game.last_result.placement == game.placement_at(game.model.finish_time, game.model.pos, true), "Final rank must use exact finish times")
	check(game.last_result.to_dict().has("race_mode"), "Result adapter must preserve race mode")
	print("PERFECT PLAYER: ", game.last_result.to_dict())
	game.retry()
	check(game.rivals.size() == 5 and game.model.elapsed == 0, "Retry must reset rivals and race")
	game._begin_run()
	play_race(game, false)
	print("GOOD PLAYER: ", game.last_result.to_dict())
	check(game.last_result.passed, "A steady race with GOOD checkpoints should reach the podium")
	check(game._hud._result_panel._title.text == TranslationServer.translate("FR_RESULT_PODIUM"), "Results must display the podium outcome")
	game.retry()
	game._begin_run()
	game.model.elapsed = game.cutoff_time
	game._sim_tick()
	check(not game.last_result.passed and not game.last_result.completed, "A timeout must not be treated as a finish")
	check(not game._hud._qte_prompt.visible, "Checkpoint UI must not remain above the results")
	game.retry()
	game._begin_run()
	game.model.pos = game.tuning.track_length
	game.model.finish_time = game.par_time * 1.4
	game._finish_run(true)
	check(game.last_result.completed and not game.last_result.passed and game.last_result.placement == 6, "Finishing outside the podium must report completion without a pass")
	game.select_mode(0)
	check(game._rival_nodes.is_empty() and game._ghost.visible, "Returning to practice must remove opponents")
	var model := FrModel.new(FrTuning.new())
	model.stamina = 0
	model.walled = true
	for i in range(1200): model.step(1.0 / 60.0, 0.25)
	check(not model.walled and model.stamina > 35, "Easing off must escape exhaustion without a checkpoint")
	game.free()
	print("PASS: FIT Runner modes, full races, timing, rank, pause, retry and recovery" if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)

func play_race(game: FitRunner, perfect: bool = true) -> void:
	var planner: FrParBot = FrParBot.build(game.tuning)
	for i in range(24000):
		if game.phase != FrRunState.Phase.RUNNING: break
		game._push_held = game.effort_input.effort < planner._target_hold_release(game.model)
		if game._qte.is_active():
			var cursor: float = game._qte.target_center
			if not perfect:
				cursor += (game._qte.settings.perfect_width + game._qte.settings.good_width) * 0.25
			game._qte.elapsed = cursor * game._qte.settings.duration
			game._on_qte_button_pressed()
		game._sim_tick()
	game._update_views(0)
	game._refresh_hud(0)
