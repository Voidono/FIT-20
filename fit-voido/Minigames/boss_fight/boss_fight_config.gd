class_name BossFightConfig
extends Resource
## Everything the main game tells the fight. All optional.
## Skill: give the resource, or just an id (looked up in BossBattle/Library/Skills: "fist", "poison").
## Difficulty: leave both empty and the player gets the difficulty menu.

@export var skill: BattleSkill
@export var skill_id: StringName = &""
@export var difficulty: BattleDifficulty
@export var difficulty_id: StringName = &""
## Shown in the status row. Empty = the battle's default.
@export var player_name := ""
## Optional: fight another boss. Must be a scene whose root script extends BossEnemy.
@export var enemy_scene: PackedScene
