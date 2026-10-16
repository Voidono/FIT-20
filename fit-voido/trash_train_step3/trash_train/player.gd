class_name TrashPlayer
extends CharacterBody2D
## The runner. Top-down (floating motion mode), speed = base_speed x tail weight factor.
## Physics layers: runner is on layer 1. Walls/obstacles (later) go on layer 4 and into collision_mask.

var tuning: TrashTrainTuning
var pointer: TrashPointer
var tail: TrashTail
var speed_now := 0.0  # px/s, for the debug overlay

var _facing := Vector2.RIGHT
var _shape := CollisionShape2D.new()


func _init() -> void:
	add_to_group(&"trash_player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 0
	z_index = 200
	_shape.shape = CircleShape2D.new()
	add_child(_shape)


func setup(t: TrashTrainTuning, p: TrashPointer, tl: TrashTail) -> void:
	tuning = t
	pointer = p
	tail = tl
	(_shape.shape as CircleShape2D).radius = tuning.player_radius


func _physics_process(delta: float) -> void:
	speed_now = tuning.base_speed * tail.speed_multiplier()
	var wanted := pointer.get_move_vector() * speed_now
	if tuning.acceleration > 0.0:
		velocity = velocity.move_toward(wanted, tuning.acceleration * delta)
	else:
		velocity = wanted
	move_and_slide()
	var r := tuning.player_radius
	global_position = global_position.clamp(Vector2(r, r), tuning.map_size - Vector2(r, r))
	if velocity.length_squared() > 100.0:
		_facing = velocity.normalized()
	queue_redraw()


func _draw() -> void:
	var r := tuning.player_radius
	draw_circle(Vector2.ZERO, r, Color("fff4d6"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color("5a4a2a"), 2.5)
	draw_circle(_facing * r * 0.55, r * 0.3, Color("5a4a2a"))
