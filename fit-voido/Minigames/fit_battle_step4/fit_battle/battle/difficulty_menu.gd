class_name BattleDifficultyMenu
extends Control
## "Choose difficulty" screen in Undertale style. Reusable: show it anywhere with
##     var chosen: BattleDifficulty = await menu.pick(current_or_null)
## BossBattle shows it automatically when it starts without a difficulty, and from the
## game-over screen ("change difficulty").
## Presets come from the path list, so adding a preset = drop a .tres in data/difficulty
## and add its path here.

@export var title := "ĐỘ KHÓ"
@export_file("*.tres") var preset_paths := PackedStringArray()

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var choices: BattleChoiceList = %ChoiceList

var _presets: Array[BattleDifficulty] = []


func _ready() -> void:
	title_label.text = title
	for path in preset_paths:
		var preset := load(path) as BattleDifficulty
		if preset != null:
			_presets.append(preset)
	choices.focused.connect(_on_focused)
	hide()


## Resolves with the chosen preset. `current` pre-selects an entry. Cancel (X) is ignored.
func pick(current: BattleDifficulty = null) -> BattleDifficulty:
	assert(not _presets.is_empty(), "BattleDifficultyMenu needs at least one preset path")
	var labels := PackedStringArray()
	var start := 0
	for i in _presets.size():
		labels.append(_presets[i].display_name)
		if _presets[i] == current:
			start = i
	show()
	var index := -1
	while index < 0:
		index = await choices.choose(labels, PackedInt32Array(), start)
	hide()
	return _presets[index]


func _on_focused(index: int) -> void:
	if index >= 0 and index < _presets.size():
		description_label.text = _presets[index].description
