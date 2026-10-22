class_name BattleTouchControls
extends CanvasLayer
## Phone controls. Creates Godot's built-in VirtualJoystick only while the heart is being dodged
## with, and only on mobile platforms (AUTO) unless forced with `mode`.
## The joystick feeds ui_left / ui_right / ui_up / ui_down, which the heart already reads, so no
## other code changes. Size, colours and textures live in touch_joystick.tscn (theme styleboxes).
## A fresh joystick is created each time, so no stale touch state can survive between phases.

enum Mode { AUTO, ALWAYS, NEVER }

## AUTO = phones and tablets only. ALWAYS / NEVER are for testing on a desktop.
@export var mode: Mode = Mode.AUTO
## Moves the joystick to the bottom-right corner.
@export var joystick_on_right := false
@export var joystick_scene: PackedScene

var _joystick: VirtualJoystick


func is_enabled() -> bool:
	match mode:
		Mode.ALWAYS:
			return true
		Mode.NEVER:
			return false
	return BattleInput.is_mobile()


## Shows a fresh joystick (if enabled) or removes it.
func set_active(active: bool) -> void:
	if _joystick != null:
		_joystick.queue_free()
		_joystick = null
		_release_actions()
	if active and is_enabled() and joystick_scene != null:
		_joystick = joystick_scene.instantiate() as VirtualJoystick
		add_child(_joystick)
		if joystick_on_right:
			var width := _joystick.offset_right - _joystick.offset_left
			_joystick.anchor_left = 1.0
			_joystick.anchor_right = 1.0
			_joystick.offset_left = -width
			_joystick.offset_right = 0.0


func _exit_tree() -> void:
	_release_actions()


func _release_actions() -> void:
	for action in [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]:
		Input.action_release(action)
