class_name EffortHoldRelease
extends EffortInput
## Scheme A: effort rises while held and falls when released. Inside the cruise band the rates are
## multiplied by a stickiness factor, so small feathering keeps you in it. The band gets less sticky
## as the run goes on ("wide early, narrower later").

var _t: RunnerTuning


func _init(tuning: RunnerTuning) -> void:
	_t = tuning
	effort = tuning.rest_floor


func reset() -> void:
	effort = _t.rest_floor


func update(dt: float, held: bool, progress: float) -> float:
	var p: float = clampf(progress, 0.0, 1.0)
	var rate: float = _t.rise_rate if held else -_t.fall_rate
	var band_hi: float = lerpf(_t.band_hi_start, _t.band_hi_end, p)
	if effort >= _t.band_lo and effort <= band_hi:
		rate *= lerpf(_t.stick_start, _t.stick_end, p)
	effort = clampf(effort + rate * dt, _t.rest_floor, 1.0)
	return effort
