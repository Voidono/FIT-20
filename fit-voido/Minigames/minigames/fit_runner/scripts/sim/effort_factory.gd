class_name FrEffortFactory
extends RefCounted
## Picks the input scheme from the tuning. Separate file so the schemes don't have to know about each other.


static func create(tuning: FrTuning) -> FrEffortInput:
	if tuning.input_mode == FrTuning.InputMode.TIERS:
		return FrEffortTiers.new(tuning)
	return FrEffortHoldRelease.new(tuning)
