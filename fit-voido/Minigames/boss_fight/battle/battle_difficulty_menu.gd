class_name BattleDifficultyMenu
extends Control
## "Choose difficulty" screen in Undertale style. Reusable anywhere:
##     var chosen: BattleDifficulty = await menu.pick(options, current_or_null)
## BossBattle shows it automatically when no difficulty was given, and from the game-over screen.

@export var title := "ĐỘ KHÓ"

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var choices: BattleChoiceList = %ChoiceList

var _options: Array[BattleDifficulty] = []


func _ready() -> void:
	title_label.text = title
	choices.focused.connect(_on_focused)
	hide()


## Resolves with the chosen preset. `current` pre-selects an entry. Cancel (X) is ignored.
func pick(options: Array[BattleDifficulty], current: BattleDifficulty = null) -> BattleDifficulty:
	assert(not options.is_empty(), "BattleDifficultyMenu needs at least one difficulty")
	_options = options
	var labels := PackedStringArray()
	var start := 0
	for i in options.size():
		labels.append(options[i].display_name)
		if options[i] == current:
			start = i
	show()
	var index := -1
	while index < 0:
		index = await choices.choose(labels, PackedInt32Array(), start)
	hide()
	return options[index]


func _on_focused(index: int) -> void:
	if index >= 0 and index < _options.size():
		description_label.text = _options[index].description
