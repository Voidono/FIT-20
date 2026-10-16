class_name ParBot
extends RefCounted
## Plays the course with the same model and the same input scheme as the player. Its finish time is par,
## and its trajectory is the translucent ghost. It is a plan-tracking controller, not a perfect optimiser:
## in the headless model it lands within about 1-2% of the best plan found by random search.

const DT: float = 1.0 / 60.0
const MAX_TIME: float = 400.0
const HOLD: float = 2.0  ## "target effort" above any real effort = keep holding
const RELEASE: float = -1.0  ## below any real effort = let go
const PULSE_HALF: float = 0.25  ## hold/release pulse that keeps a tier latched in scheme B

var positions: PackedFloat32Array = PackedFloat32Array()  ## position at tick i, time = i * DT
var finish_time: float = 0.0
var walls_hit: int = 0

var _tuning: RunnerTuning
var _high: bool = false
var _phase: float = 0.0


static func build(tuning: RunnerTuning) -> ParBot:
	var bot := ParBot.new()
	bot._run(tuning)
	return bot


func _run(tuning: RunnerTuning) -> void:
	_tuning = tuning
	var model := RunnerModel.new(tuning)
	var input: EffortInput = EffortFactory.create(tuning)
	var release_timer: float = 0.0
	positions.append(0.0)
	while (not model.finished) and model.elapsed < MAX_TIME:
		var target: float
		if tuning.input_mode == RunnerTuning.InputMode.TIERS:
			target = _target_tiers(model, input as EffortTiers)
		else:
			target = _target_hold_release(model)
		var held: bool = input.effort < target
		var effort: float = input.update(DT, held, clampf(model.progress(), 0.0, 1.0))
		if model.in_station() and not held:
			release_timer += DT
			if release_timer >= tuning.water_release_delay:
				model.request_drink()
		else:
			release_timer = 0.0
		model.step(DT, effort)
		positions.append(model.pos)
	finish_time = model.finish_time if model.finished else MAX_TIME
	walls_hit = model.walls_hit


func _target_hold_release(m: RunnerModel) -> float:
	var t: RunnerTuning = _tuning
	var p: float = m.progress()
	if m.in_station() and m.stamina < t.bot_drink_below:
		return RELEASE
	if m.walled:
		return RELEASE
	if p >= t.spurt_start - t.bot_spurt_lead:
		return HOLD
	var plan: float = t.stamina_max - (t.stamina_max - t.bot_reserve) * (p / t.spurt_start)
	var target: float = t.bot_e_base + t.bot_k * (m.stamina - plan) / t.stamina_max - t.bot_ff * m.slope_norm
	return clampf(target, t.bot_e_min, 1.0)


func _target_tiers(m: RunnerModel, input: EffortTiers) -> float:
	var t: RunnerTuning = _tuning
	var p: float = m.progress()
	if m.in_station() and m.stamina < t.bot_drink_below:
		return RELEASE
	if m.walled:
		return RELEASE
	var top: int = t.tier_values.size() - 1
	var want: int
	if p >= t.spurt_start - t.bot_b_spurt_lead:
		want = top
	else:
		var plan: float = t.stamina_max - (t.stamina_max - t.bot_b_reserve) * (p / t.spurt_start)
		var err: float = m.stamina - plan
		if err > t.bot_b_hysteresis:
			_high = true
		elif err < -t.bot_b_hysteresis:
			_high = false
		want = mini(2, top) if _high else mini(1, top)
	if input.tier < want:
		return HOLD
	if input.tier > want:
		return RELEASE
	_phase = fmod(_phase + DT, PULSE_HALF * 2.0)
	return HOLD if _phase < PULSE_HALF else RELEASE


## Ghost position at time t (seconds).
func position_at(t: float) -> float:
	var n: int = positions.size()
	if n == 0:
		return 0.0
	var f: float = maxf(t, 0.0) / DT
	var i: int = int(f)
	if i >= n - 1:
		return positions[n - 1]
	return lerpf(positions[i], positions[i + 1], f - float(i))


## Time the par runner needed to reach position p. Used for the "+1.2 s ahead of par" readout.
func time_at(p: float) -> float:
	var n: int = positions.size()
	if n < 2:
		return 0.0
	if p >= positions[n - 1]:
		return float(n - 1) * DT
	var lo: int = 0
	var hi: int = n - 1
	while lo < hi:
		var mid: int = (lo + hi) >> 1
		if positions[mid] < p:
			lo = mid + 1
		else:
			hi = mid
	if lo == 0:
		return 0.0
	var prev: float = positions[lo - 1]
	var cur: float = positions[lo]
	var frac: float = (p - prev) / (cur - prev) if cur > prev else 0.0
	return (float(lo - 1) + frac) * DT
