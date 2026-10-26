extends SceneTree
## Headless check of the stamina model and the par bot, no window needed:
##   godot --headless --path . --script res://minigames/fit_runner/tools/strategy_sim.gd
## Open the project in the editor once first so the class names are registered.
## Compare with the table in README.md: if par is far off, something differs from the model I calibrated.

const DT: float = 1.0 / 60.0


func _init() -> void:
	var tuning := FrTuning.new()
	for mode: int in [0, 1]:
		tuning.input_mode = mode as FrTuning.InputMode
		var bot: FrParBot = FrParBot.build(tuning)
		var steady: FrModel = _run(tuning, "steady", 0.62)
		var mash_go: FrModel = _run(tuning, "mash_let_go", 0.0)
		var mash_never: FrModel = _run(tuning, "mash_never", 0.0)
		print("mode %s | par %.1f s (walls %d) | steady 0.62 + spurt %.1f s | mash, lets go at the wall %.1f s (walls %d) | mash, never releases %.1f s | cutoff %.1f s" % [
			"AB"[mode], bot.finish_time, bot.walls_hit, steady.finish_time, mash_go.finish_time, mash_go.walls_hit, mash_never.finish_time, bot.finish_time * tuning.cutoff_mult])
	quit()


func _run(tuning: FrTuning, kind: String, e: float) -> FrModel:
	var m := FrModel.new(tuning)
	var input: FrEffortInput = FrEffortFactory.create(tuning)
	var release_timer: float = 0.0
	while (not m.finished) and m.elapsed < 400.0:
		var target: float = _target(m, kind, e)
		var held: bool = input.effort < target
		var effort: float = input.update(DT, held, clampf(m.progress(), 0.0, 1.0))
		if m.in_station() and not held:
			release_timer += DT
			if release_timer >= tuning.water_release_delay:
				m.request_drink()
		else:
			release_timer = 0.0
		m.step(DT, effort)
	return m


func _target(m: FrModel, kind: String, e: float) -> float:
	if kind == "mash_never":
		return FrParBot.HOLD
	if m.in_station() and m.stamina < 90.0:
		return FrParBot.RELEASE
	if kind == "mash_let_go":
		if m.walled and m.stamina < m.tuning.wall_release:
			return FrParBot.RELEASE
		return FrParBot.HOLD
	if m.walled:
		return FrParBot.RELEASE
	if m.in_spurt():
		return FrParBot.HOLD
	return e
