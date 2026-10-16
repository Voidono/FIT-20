class_name EffortFactory
extends RefCounted
## Picks the input scheme from the tuning. Separate file so the schemes don't have to know about each other.


static func create(tuning: RunnerTuning) -> EffortInput:
	if tuning.input_mode == RunnerTuning.InputMode.TIERS:
		return EffortTiers.new(tuning)
	return EffortHoldRelease.new(tuning)
