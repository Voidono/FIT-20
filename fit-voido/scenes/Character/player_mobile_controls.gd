class_name PlayerMobileControls
extends CanvasLayer
## Mobile on-screen controls for the main character (overworld movement).
## Shows a floating VirtualJoystick on the left and an Interact button on the right.
## Visibility is decided once in _ready() based on DeviceInput.is_mobile().
##
## The joystick directly feeds the move_left / move_right / move_up / move_down actions.
## The interact button fires the "interact" action so NPCs can be talked to by tap.
##
## Scene setup:
##   PlayerMobileControls (CanvasLayer, layer = 5)
##     JoystickContainer  (Control – left half)
##       Joystick         (VirtualJoystick)
##     InteractButton     (Button – bottom-right)

signal interact_pressed

## Change to ALWAYS or NEVER to override the automatic platform check (useful for
## testing touch controls in the editor).
enum Mode { AUTO, ALWAYS, NEVER }
@export var mode: Mode = Mode.AUTO

@onready var _joystick: VirtualJoystick = $JoystickContainer/Joystick
@onready var _interact_btn: Button = $InteractButton
@onready var _joystick_container: Control = $JoystickContainer


func _ready() -> void:
	visible = _should_show()
	if not visible:
		return
	get_viewport().size_changed.connect(_layout)
	_layout()
	if _joystick != null:
		_joystick.action_left = &"move_left"
		_joystick.action_right = &"move_right"
		_joystick.action_up = &"move_up"
		_joystick.action_down = &"move_down"
	if _interact_btn != null:
		_interact_btn.pressed.connect(_on_interact_pressed)


func _should_show() -> bool:
	match mode:
		Mode.ALWAYS:
			return true
		Mode.NEVER:
			return false
	return DeviceInput.is_mobile()


func _on_interact_pressed() -> void:
	interact_pressed.emit()
	## Also synthesise the interact InputEvent so character.gd's
	## _unhandled_input() catches it via is_action_pressed("interact").
	var ev := InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	ev = InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = false
	Input.parse_input_event(ev)


func _layout() -> void:
	var area := get_viewport().get_visible_rect().size
	var extent := clampf(area.y * 0.42, 140, 220)
	_joystick_container.offset_top = -extent
	_joystick_container.offset_right = extent
	_joystick.joystick_size = extent * 0.65
	_joystick.tip_size = extent * 0.28
	_interact_btn.offset_left = -156
	_interact_btn.offset_top = -80
	_interact_btn.offset_right = -16
	_interact_btn.offset_bottom = -16
	_interact_btn.text = "Tương tác"
	_interact_btn.focus_mode = Control.FOCUS_NONE


func _exit_tree() -> void:
	# Scene changes must not carry a held virtual direction into the next map.
	if visible:
		for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
			Input.action_release(action)
