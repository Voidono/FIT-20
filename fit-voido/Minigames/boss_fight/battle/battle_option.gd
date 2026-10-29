class_name BattleOption
extends Node
## One selectable entry. Children of BossEnemy/Acts are ACT options,
## children of BossBattle/Items are ITEM options. Add / remove / reorder them in the editor.

@export var label := "Check"
@export_multiline var response := ""
## -1 = unlimited, 0 = used up. Works for ACT and ITEM entries alike.
@export var uses := -1
@export_group("ACT")
@export var mercy_delta := 0
@export_group("ITEM")
@export var heal_amount := 0

var _initial_uses := -1


func _ready() -> void:
	_initial_uses = uses


func use() -> void:
	if uses > 0:
		uses -= 1


func reset() -> void:
	uses = _initial_uses
