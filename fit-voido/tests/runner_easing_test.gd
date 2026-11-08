extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	TranslationServer.set_locale("en")
	var game = load("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd").create()
	root.add_child(game)
	game.set_process(false)
	assert(TranslationServer.get_locale().begins_with("vi"))
	var guide := FrParBot.build(game.tuning)
	assert(guide.playback_speed == 1.0)
	for strategy in range(1, 6):
		var old := FrParBot.build(game.tuning, strategy, 1.0)
		var easier := FrParBot.build(game.tuning, strategy)
		assert(is_equal_approx(easier.finish_time, old.finish_time / 0.94))
		assert(is_equal_approx(easier.position_at(30), old.position_at(30 * 0.94)))
		assert(absf(easier.time_at(easier.position_at(30)) - 30) < 0.02)
		print("Ghost ", strategy, ": ", old.finish_time, " -> ", easier.finish_time)
	for key in FitRunnerStrings.TABLE.vi:
		assert(TranslationServer.translate(key) == FitRunnerStrings.TABLE.vi[key])
	print("PASS: all rivals 6% slower, guide unchanged, Vietnamese default and translations")
	game.free()
	quit()
