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


func won() -> bool:
	return outcome == &"win"


func spared() -> bool:
	return outcome == &"spared"
