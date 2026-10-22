extends Node2D
## FIT-20 entry point for the boss battle minigame.
##
## The battle is a self-contained scene. This host supplies the skill selected
## by FIT-20 and returns the player to the hub when the battle ends.

const BATTLE_SCENE := preload("res://Minigames/fit_battle/battle/battle.tscn")
const HUB_SCENE := "res://scenes/mapsides/nửa đầu.tscn"
const BATTLE_SIZE := Vector2(640, 480)

## Replace this assignment when FIT-20 has a player-selected battle skill.
@export var skill_id: StringName = &"fist"

var _battle: BossBattle


func _ready() -> void:
	_start_battle()


func _start_battle() -> void:
	_battle = BATTLE_SCENE.instantiate() as BossBattle
	_battle.skill_id = skill_id
	add_child(_battle)
	_center_battle()
	get_viewport().size_changed.connect(_center_battle)
	_battle.finished.connect(_on_battle_finished, CONNECT_ONE_SHOT)


func _center_battle() -> void:
	if is_instance_valid(_battle):
		_battle.position = (get_viewport_rect().size - BATTLE_SIZE) * 0.5


func _on_battle_finished(_result: StringName) -> void:
	if has_node("/root/SceneLoader"):
		get_node("/root/SceneLoader").go_to(HUB_SCENE)
	else:
		get_tree().change_scene_to_file(HUB_SCENE)
