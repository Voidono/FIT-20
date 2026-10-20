class_name BattleStats
extends RefCounted
## The player's HP during one fight attempt. Created by BossBattle, shown by BattleHud.

signal hp_changed(hp: int, max_hp: int)

var display_name := "SV 2006"
var level := 1
var max_hp := 20
var hp := 20


func setup(p_name: String, p_max_hp: int) -> void:
	display_name = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	hp_changed.emit(hp, max_hp)


## Changes max HP but keeps the same fraction of health (used when difficulty changes mid-fight).
func set_max_hp(new_max: int) -> void:
	var ratio := float(hp) / float(maxi(max_hp, 1))
	max_hp = new_max
	hp = clampi(roundi(ratio * new_max), 1, new_max)
	hp_changed.emit(hp, max_hp)


func damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


func full_heal() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)


func is_dead() -> bool:
	return hp <= 0
