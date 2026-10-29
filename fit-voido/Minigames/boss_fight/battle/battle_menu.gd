class_name BattleMenu
extends Control
## The four buttons. Uses Godot's own focus navigation (arrows + accept).
## Delete a Button node (e.g. Item) and that option simply disappears.
## Emits the lower-cased button name: &"fight", &"act", &"item", &"mercy".

signal chosen(action: StringName)
## The highlight moved to another button (hook for a cursor sound).
signal moved

@onready var buttons_root: Control = %Buttons
@onready var heart: Node2D = %Heart

var _last_focus: Button
var _active := false


func _ready() -> void:
	for button in _get_buttons():
		button.pressed.connect(_on_pressed.bind(button))
		button.focus_entered.connect(_on_focus.bind(button))
	deactivate()


func activate() -> void:
	var list := _get_buttons()
	if list.is_empty():
		return
	_active = true
	for button in list:
		button.focus_mode = Control.FOCUS_ALL
	var target := _last_focus if is_instance_valid(_last_focus) else list[0]
	target.grab_focus()
	heart.show()


func deactivate() -> void:
	_active = false
	heart.hide()
	for button in _get_buttons():
		button.release_focus()
		button.focus_mode = Control.FOCUS_NONE


func _get_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for child in buttons_root.get_children():
		if child is Button:
			result.append(child)
	return result


func _on_pressed(button: Button) -> void:
	if _active:
		chosen.emit(StringName(String(button.name).to_lower()))


func _on_focus(button: Button) -> void:
	if _last_focus != null and _last_focus != button:
		moved.emit()
	_last_focus = button
	heart.global_position = button.global_position + Vector2(22.0, button.size.y * 0.5)
