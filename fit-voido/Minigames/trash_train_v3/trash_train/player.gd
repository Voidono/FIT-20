class_name TrashPlayer
extends CharacterBody2D
## The runner (a scene: player.tscn). Top-down (floating motion mode). Speed = base_speed x tail weight.
## It collides with the WALLS layer, so every StaticBody2D / TileMap tile you put under the level's
## "Obstacles" node blocks it. Give player.tscn your own Sprite2D / AnimatedSprite2D and collision shape
## and untick draw_placeholder. If you attach this script to a bare CharacterBody2D it adds a circle shape.

@export var draw_placeholder := true
@export_range(6.0, 40.0, 0.5) var placeholder_radius := 14.0

var tuning: TrashTrainTuning
var pointer: TrashPointer
var tail: TrashTail
var powerups: TrashPowerups  ## set by TrashTrain after setup; null until powerups are wired
var speed_now := 0.0  # px/s, for the debug overlay

var _facing := Vector2.RIGHT


func _init() -> void:
	add_to_group(&"trash_player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	z_index = 200


func _ready() -> void:
	collision_layer = TrashLayers.RUNNER
	collision_mask = TrashLayers.WALLS
	var has_shape := false
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			has_shape = true
	if not has_shape:
		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = placeholder_radius
		cs.shape = circle
		add_child(cs)


func setup(t: TrashTrainTuning, p: TrashPointer, tl: TrashTail) -> void:
	tuning = t
	pointer = p
	tail = tl


func _physics_process(delta: float) -> void:
	var weight := tail.speed_multiplier()
	speed_now = tuning.base_speed * (powerups.speed_factor(weight) if powerups != null else weight)
	var wanted := pointer.get_move_vector() * speed_now
	if tuning.acceleration > 0.0:
		velocity = velocity.move_toward(wanted, tuning.acceleration * delta)
	else:
		velocity = wanted
	move_and_slide()
	if velocity.length_squared() > 100.0:
		_facing = velocity.normalized()
	if draw_placeholder:
		queue_redraw()


func _draw() -> void:
	if not draw_placeholder:
		return
	var r := placeholder_radius
	draw_circle(Vector2.ZERO, r, Color("fff4d6"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color("5a4a2a"), 2.5)
	draw_circle(_facing * r * 0.55, r * 0.3, Color("5a4a2a"))
