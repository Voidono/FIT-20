class_name BattleKeyboardHint
extends CanvasLayer
## Small keyboard-hint overlay for the Boss Battle (desktop only).
## Shows automatically on PC, hidden on mobile.
## Place this as a sibling of TouchControls inside boss_battle.tscn.

@export var hint_text: String = "WASD / Arrow keys: Dodge   |   Z: Confirm   |   X: Cancel"

var _label: Label


func _ready() -> void:
	# Only show on desktop
	visible = DeviceInput.is_desktop()
	if not visible:
		return
	_build_label()


func _build_label() -> void:
	_label = Label.new()
	_label.text = hint_text
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 5)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.anchor_left = 0.0
	_label.anchor_right = 1.0
	_label.offset_bottom = 24.0
	_label.offset_top = 0.0
	add_child(_label)
