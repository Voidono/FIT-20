class_name TrashPointer
extends Node2D
## ONE code path for mouse and touch -> a movement vector with length 0..1.
## Put it under a CanvasLayer so the stick graphics draw in screen space.
##
## It only reacts to REAL mouse / touch events (events emulated by the engine are skipped),
## so it behaves the same whether "Emulate Mouse From Touch" / "Emulate Touch From Mouse" are on or off.
## Only one finger steers; any other finger is ignored here (the Pulse button will use it).
##
## Mode A STEER_TO_POINTER: run toward the pointer, measured on screen from the runner.
## Mode B FLOATING_STICK:   stick appears where the pointer lands; dragging past stick_radius
##                          drags the anchor along, so reversing direction is a short move.

signal pressed  ## a steering press began (not on a UI blocker): used for "tap to start"

const NO_POINTER := -2
const MOUSE_POINTER := -1

var tuning: TrashTrainTuning
var follow_target: Node2D  # the runner; needed by STEER_TO_POINTER
var blockers: Array[Control] = []  # UI that must not start a steering drag

var _id := NO_POINTER
var _anchor := Vector2.ZERO  # viewport px
var _pos := Vector2.ZERO  # viewport px


func is_active() -> bool:
	return _id != NO_POINTER


func get_move_vector() -> Vector2:
	if _id == NO_POINTER or tuning == null:
		return Vector2.ZERO
	var origin := _anchor
	if tuning.control_mode == TrashTrainTuning.ControlMode.STEER_TO_POINTER and follow_target != null:
		origin = _runner_screen_pos()
	var offset := _pos - origin
	var dist := offset.length()
	if dist <= tuning.deadzone:
		return Vector2.ZERO
	var mag := clampf((dist - tuning.deadzone) / maxf(tuning.ramp, 1.0), 0.0, 1.0)
	return offset / dist * mag


func _input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_down(t.index, t.position)
		else:
			_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_move(d.index, d.position)
	elif event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.button_index != MOUSE_BUTTON_LEFT:
			return
		if b.pressed:
			_down(MOUSE_POINTER, b.position)
		else:
			_up(MOUSE_POINTER)
	elif event is InputEventMouseMotion:
		_move(MOUSE_POINTER, (event as InputEventMouseMotion).position)


func _process(_delta: float) -> void:
	if _id == MOUSE_POINTER and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_up(MOUSE_POINTER)  # a release was missed (e.g. let go outside the window)
	if _id != NO_POINTER:
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_up(_id)


func _down(id: int, pos: Vector2) -> void:
	if _id != NO_POINTER:
		return
	for c in blockers:
		if is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return
	_id = id
	_anchor = pos
	_pos = pos
	queue_redraw()
	pressed.emit()


func _move(id: int, pos: Vector2) -> void:
	if id != _id:
		return
	_pos = pos
	if tuning != null and tuning.control_mode == TrashTrainTuning.ControlMode.FLOATING_STICK:
		var off := _pos - _anchor
		var d := off.length()
		if d > tuning.stick_radius:
			_anchor += off / d * (d - tuning.stick_radius)


func _up(id: int) -> void:
	if id != _id:
		return
	_id = NO_POINTER
	queue_redraw()


func _runner_screen_pos() -> Vector2:
	return get_viewport().get_canvas_transform() * follow_target.global_position


func _draw() -> void:
	if _id == NO_POINTER or tuning == null:
		return
	var ring := Color(1, 1, 1, 0.35)
	var knob := Color(1, 1, 1, 0.55)
	if tuning.control_mode == TrashTrainTuning.ControlMode.FLOATING_STICK:
		draw_arc(_anchor, tuning.stick_radius, 0.0, TAU, 48, ring, 3.0)
		draw_circle(_pos, 18.0, knob)
	elif follow_target != null:
		draw_line(_runner_screen_pos(), _pos, ring, 3.0)
		draw_circle(_pos, 12.0, knob)
