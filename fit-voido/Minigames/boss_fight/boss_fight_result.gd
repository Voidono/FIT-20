class_name BossFightResult
extends RefCounted
## What BossFight.finished hands back to the main game.

## &"win" or &"spared".
var outcome: StringName = &""
## How many times the player died before finishing.
var deaths := 0
## Seconds from the start of the fight to the end.
var seconds := 0.0
var skill: BattleSkill
var difficulty: BattleDifficulty
var final_hp := 0
var max_hp := 1
var base_points := 0
var health_bonus := 0
var score_multiplier := 1.0
var score := 0


func calculate_score() -> void:
	base_points = 1000 if won() else 0
	health_bonus = roundi(1000.0 * clampf(float(final_hp) / maxi(max_hp, 1), 0.0, 1.0)) if won() else 0
	score_multiplier = difficulty.score_multiplier if difficulty != null else 1.0
	score = roundi((base_points + health_bonus) * score_multiplier)


func won() -> bool:
	return outcome == &"win"


func spared() -> bool:
	return outcome == &"spared"
