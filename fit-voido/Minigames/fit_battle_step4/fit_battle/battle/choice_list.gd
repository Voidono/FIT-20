class_name BattleChoiceList
extends GridContainer
## Undertale-style option list (two columns by default, like the ACT menu; set `columns` = 1 for a
## plain list). Buttons are cloned from the hidden "Template" button, so restyling Template
## restyles every option. Used for the target / ACT / ITEM / MERCY lists and the difficulty menu.

signal opened
signal closed
## Emitted when the highlighted option changes (keyboard or touch).
signal focused(index: int)
signal _picked(index: int)

@export var prefix := "* "
@export var highlight_color := Color(1, 1, 0, 1)
## Taller buttons on phones so options are easy to tap.
@export var mobile_button_height := 44.0

@onready var template: Button = %Template
@onready var heart: Node2D = %Heart

var _buttons: Array[Button] = []


func _ready() -> void:
	if BattleInput.is_mobile():
		template.custom_minimum_size.y = maxf(template.custom_minimum_size.y, mobile_button_height)
	template.hide()
	hide()


## Shows the options. Resolves with the picked index, or -1 if cancelled (X or the BACK button).
## `highlighted` = indices drawn in yellow (e.g. "spareable"); `start_index` = initial selection.
func choose(options: PackedStringArray, highlighted := PackedInt32Array(), start_index := 0) -> int:
	if options.is_empty():
		return -1
	_clear()
	for i in options.size():
		var button := template.duplicate() as Button
		button.text = prefix + options[i]
		if highlighted.has(i):
			button.add_theme_color_override(&"font_color", highlight_color)
		button.focus_entered.connect(_on_button_focused.bind(i))
		button.pressed.connect(func() -> void: _picked.emit(i))
		add_child(button)
		button.show()
		_buttons.append(button)
	show()
	opened.emit()
	await get_tree().process_frame  # let the container lay the buttons out
	if not _buttons.is_empty():
		_buttons[clampi(start_index, 0, _buttons.size() - 1)].grab_focus()
	var index: int = await _picked
	_clear()
	hide()
	closed.emit()
	return index


func cancel() -> void:
	if not _buttons.is_empty():
		_picked.emit(-1)


func _unhandled_input(event: InputEvent) -> void:
	if visible and BattleInput.is_cancel(event):
		get_viewport().set_input_as_handled()
		cancel()


func _on_button_focused(index: int) -> void:
	if index >= _buttons.size():
		return
	var button := _buttons[index]
	heart.global_position = button.global_position + Vector2(-18.0, button.size.y * 0.5)
	focused.emit(index)


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
