class_name FrEffortInput
extends RefCounted
## One job: turn "is the player holding?" into a single effort value from 0 to 1.
## Stamina and speed only ever see that value. To try another scheme (alternating taps, Uma Racing style)
## write a new subclass, add it to FrEffortFactory, and nothing else changes.

var effort: float = 0.0  ## current effort, 0..1


func reset() -> void:
	effort = 0.0


## Called once per simulation tick. progress is 0..1 along the track. Returns the new effort.
func update(_dt: float, _held: bool, _progress: float) -> float:
	return effort
