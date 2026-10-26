class_name BattleSoul
extends Node2D
## The heart. Moves with arrows / WASD, the on-screen joystick (phones), or by dragging a finger or
## the mouse anywhere (relative drag, so the finger never covers the heart). Hurt by BattleBullets.

signal hit(damage: int)

enum Mode { HIDDEN, PLAYING }

@export var speed := 140.0
@export var invincibility_time := 1.0
@export var blink_interval := 0.08
## Keeps the heart's centre this far inside the box's inner edge.
@export var edge_margin := 8.0
@export_group("Touch")
@export var touch_sensitivity := 1.0
## Top speed while dragging, as a multiple of `speed`, so a flick cannot teleport the heart.
@export var touch_speed_factor := 2.5
## Off when the on-screen joystick is in use (phones), so the two never fight.
@export var touch_drag_enabled := true

@onready var visual: Node2D = %Visual
@onready var hurtbox: Area2D = %Hurtbox

var mode: Mode = Mode.HIDDEN
var speed_multiplier := 1.0

var _box: BattleBox
var _invincible := 0.0
var _touching := false
var _touch_target := Vector2.ZERO


func _ready() -> void:
	hide_soul()


func configure(p_invincibility_time: float, p_speed_multiplier: float) -> void:
	invincibility_time = p_invincibility_time
	speed_multiplier = p_speed_multiplier


func hide_soul() -> void:
	mode = Mode.HIDDEN
	hide()


func begin_play(global_pos: Vector2, p_box: BattleBox) -> void:
	_box = p_box
	global_position = global_pos
	_touch_target = global_pos
	_touching = false
	_invincible = 0.0
	visual.modulate.a = 1.0
	mode = Mode.PLAYING
	show()


func play_death() -> void:
	mode = Mode.HIDDEN
	show()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.8)
	await tween.finished
	hide()


func _input(event: InputEvent) -> void:
	if mode != Mode.PLAYING or not touch_drag_enabled:
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		_touching = touch.pressed
		_touch_target = global_position
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		_touch_target += drag.relative * touch_sensitivity
		return
	if BattleInput.mouse_emulates_touch():
		return  # the emulated touch events above already cover the mouse
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT \
			and click.device != InputEvent.DEVICE_ID_EMULATION:
		_touching = click.pressed
		_touch_target = global_position
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _touching and motion.device != InputEvent.DEVICE_ID_EMULATION:
		_touch_target += motion.relative * touch_sensitivity


func _physics_process(delta: float) -> void:
	if mode != Mode.PLAYING:
		return
	var current_speed := speed * speed_multiplier
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down", 0.1)
	global_position += direction * current_speed * delta
	if _box != null:
		var area := _box.get_inner_rect().grow(-edge_margin)
		if _touching:
			_touch_target = _touch_target.clamp(area.position, area.end)
			global_position = global_position.move_toward(
					_touch_target, current_speed * touch_speed_factor * delta)
		global_position = global_position.clamp(area.position, area.end)
	if _invincible > 0.0:
		_invincible -= delta
		visible = _invincible <= 0.0 or int(_invincible / blink_interval) % 2 == 0
		return
	for overlap in hurtbox.get_overlapping_areas():
		var bullet := overlap as BattleBullet
		if bullet != null:
			_invincible = invincibility_time
			hit.emit(bullet.damage)
			break
