class_name Zones
extends RefCounted
## The five zones the HUD shows. Zones only name a range of pace; the drain itself is a smooth curve in RunnerModel.

enum Id { RECOVER, CRUISE, PUSH, SPRINT, WALL }

const CRUISE_FROM: float = 0.5
const PUSH_FROM: float = 0.7
const SPRINT_FROM: float = 0.9


static func for_pace(pace: float, walled: bool) -> int:
	if walled:
		return Id.WALL
	if pace < CRUISE_FROM:
		return Id.RECOVER
	if pace < PUSH_FROM:
		return Id.CRUISE
	if pace < SPRINT_FROM:
		return Id.PUSH
	return Id.SPRINT
