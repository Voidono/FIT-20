class_name EffortTiers
extends EffortInput
## Scheme B: hold-time tiers. Holding climbs one tier every tier_up_time, letting go drops one tier
## every tier_down_time. Short taps and short releases leave the tier where it is.

var tier: int = 0
var _t: RunnerTuning
var _hold_time: float = 0.0
var _release_time: float = 0.0


func _init(tuning: RunnerTuning) -> void:
	_t = tuning
	effort = _tier_value()


func reset() -> void:
	tier = 0
	_hold_time = 0.0
	_release_time = 0.0
	effort = _tier_value()


func _tier_value() -> float:
	var values: PackedFloat32Array = _t.tier_values
	return values[clampi(tier, 0, values.size() - 1)]


func update(dt: float, held: bool, _progress: float) -> float:
	var top: int = _t.tier_values.size() - 1
	if held:
		_release_time = 0.0
		_hold_time += dt
		if _hold_time >= _t.tier_up_time and tier < top:
			tier += 1
			_hold_time = 0.0
	else:
		_hold_time = 0.0
		_release_time += dt
		if _release_time >= _t.tier_down_time and tier > 0:
			tier -= 1
			_release_time = 0.0
	effort = _tier_value()
	return effort
