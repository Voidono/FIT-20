class_name PlayerMobileControls
extends CanvasLayer
## Mobile on-screen controls for the main character (overworld movement).
## Shows a floating VirtualJoystick on the left and an Interact button on the right.
## Visibility is decided once in _ready() based on DeviceInput.is_mobile().
##
## The joystick feeds the move_left / move_right / move_up / move_down actions.
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
	# Wire the joystick output into Godot's built-in move_* actions so
	# character.gd's Input.get_vector() reads them automatically.
	if _joystick != null:
		_joystick.axis_changed.connect(_on_joystick_changed)
	if _interact_btn != null:
		_interact_btn.pressed.connect(_on_interact_pressed)


func _should_show() -> bool:
	match mode:
		Mode.ALWAYS:
			return true
		Mode.NEVER:
			return false
	return DeviceInput.is_mobile()


func _on_joystick_changed(axis_x: float, axis_y: float) -> void:
	## Translate the joystick [-1,1] output into the four directional actions.
	## We use action_strength via synthetic events so get_vector() works as-is.
	_set_axis("move_right",  axis_x,  1.0)
	_set_axis("move_left",   axis_x, -1.0)
	_set_axis("move_down",   axis_y,  1.0)
	_set_axis("move_up",     axis_y, -1.0)


func _set_axis(action: StringName, raw: float, sign: float) -> void:
	var strength := clampf(raw * sign, 0.0, 1.0)
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _on_interact_pressed() -> void:
	interact_pressed.emit()
	## Also synthesise the interact InputEvent so character.gd's
	## _unhandled_input() catches it via is_action_pressed("interact").
	var ev := InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = true
	Input.parse_input_event(ev)
