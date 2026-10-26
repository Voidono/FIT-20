class_name BattleHud
extends Control
## Undertale status row: name + LV on the left, "HP" + bar + numbers in the middle.
## The bar is as long as the max HP, like in Undertale (`hp_pixels_per_point` px per HP).
## Call bind(stats) once per fight attempt.

@export var hp_pixels_per_point := 1.2

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LvLabel
@onready var bar: ProgressBar = %HpBar
@onready var value_label: Label = %HpValue

var _stats: BattleStats


func bind(stats: BattleStats) -> void:
	if _stats != null and _stats.hp_changed.is_connected(_refresh):
		_stats.hp_changed.disconnect(_refresh)
	_stats = stats
	stats.hp_changed.connect(_refresh)
	name_label.text = stats.display_name
	level_label.text = "LV %d" % stats.level
	_refresh(stats.hp, stats.max_hp)


func _refresh(hp: int, max_hp: int) -> void:
	bar.max_value = max_hp
	bar.value = hp
	bar.custom_minimum_size = Vector2(maxf(float(max_hp) * hp_pixels_per_point, 8.0), 20.0)
	value_label.text = "%d / %d" % [hp, max_hp]
