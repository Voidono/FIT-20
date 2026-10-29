class_name BattleDifficulty
extends Resource
## One difficulty preset. Everything in the fight that can be tuned is a multiplier here.

## Used to look a preset up by name: BossFightConfig.difficulty_id.
@export var id: StringName = &"normal"
@export var display_name := "Normal"
@export_multiline var description := ""
@export_group("Player")
@export var player_max_hp := 20
## Seconds of invincibility after being hit.
@export var invincibility_time := 1.0
@export var damage_taken_multiplier := 1.0
@export_group("Attacks")
@export var bullet_speed_multiplier := 1.0
## More = denser bullets.
@export var spawn_rate_multiplier := 1.0
@export var attack_duration_multiplier := 1.0
## Warning time before lasers fire / paused bullets launch.
@export var telegraph_multiplier := 1.0
@export_group("Attack bar")
## Cursor speed of the FIGHT timing bar.
@export var bar_speed_multiplier := 1.0
## Scales the skill's `forgiveness` (width of the good zone).
@export var sweet_spot_multiplier := 1.0
@export_group("Boss")
@export var boss_hp_multiplier := 1.0
## Scales how much mercy each ACT gives.
@export var mercy_multiplier := 1.0
