class_name BattleInput
extends Node
## Input glue. Keep one in any scene that uses the battle UI (BossBattle already has one).
## While it exists it adds Z / X (and WASD) to Godot's built-in ui_* actions, and removes exactly
## those events again when it is freed, so the rest of the game's Input Map is left alone.
## The static helpers define what "confirm" means everywhere: Z / Enter / Space, a screen tap or a
## left mouse click. They do not depend on any Project Setting: a click counts exactly once whether
## or not "Emulate Touch From Mouse" is on.

@export var add_undertale_keys := true
@export var confirm_key: Key = KEY_Z
@export var cancel_key: Key = KEY_X
@export var add_wasd := true

var _added := {}


static func is_confirm(event: InputEvent) -> bool:
	if event.is_action_pressed(&"ui_accept"):
		return true
	var touch := event as InputEventScreenTouch
	if touch != null:
		return touch.pressed
	var click := event as InputEventMouseButton
	return click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT \
			and click.device != InputEvent.DEVICE_ID_EMULATION and not mouse_emulates_touch()


static func is_cancel(event: InputEvent) -> bool:
	return event.is_action_pressed(&"ui_cancel")


## True on phones and tablets: native Android / iOS, or a web export running on them.
static func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## True when the project turns mouse clicks into touch events (then those touch events are used).
static func mouse_emulates_touch() -> bool:
	return bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false))


func _enter_tree() -> void:
	if add_undertale_keys:
		_add(&"ui_accept", confirm_key)
		_add(&"ui_cancel", cancel_key)
	if add_wasd:
		_add(&"ui_up", KEY_W)
		_add(&"ui_left", KEY_A)
		_add(&"ui_down", KEY_S)
		_add(&"ui_right", KEY_D)


func _exit_tree() -> void:
	for action in _added:
		InputMap.action_erase_event(action, _added[action])
	_added.clear()


func _add(action: StringName, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	if InputMap.action_has_event(action, event):
		return
	InputMap.action_add_event(action, event)
	_added[action] = event
