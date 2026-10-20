class_name BattleSkill
extends Resource
## A player skill. Make new ones with right-click > New Resource > BattleSkill.
## The main game picks one (from the player's earlier actions) and gives it to BossBattle.

## Used by BossBattle.skill_from_id(): the file must be res://Minigames/fit_battle_step4/fit_battle/data/skills/<id>.tres
@export var id: StringName = &"fist"
@export var display_name := "FIST"
@export_multiline var description := ""
@export var base_damage := 40
## Width of the good zone on the attack bar. 1.0 = whole bar, small = precise timing needed.
@export_range(0.05, 1.0) var forgiveness := 0.4
## Damage ratio at the very edge of the good zone (the centre is always 1.0).
@export_range(0.0, 1.0) var min_damage_ratio := 0.3
## Accuracy at or above this counts as a perfect hit.
@export_range(0.5, 1.0) var perfect_threshold := 0.9
@export var perfect_multiplier := 1.5
@export_group("Poison")
@export var poison_damage := 0
@export var poison_turns := 0
@export_group("Dodge phase")
## BattleSoul speed multiplier while this skill is equipped (placeholder for the "evasive" playstyle).
@export var dodge_speed_multiplier := 1.0
