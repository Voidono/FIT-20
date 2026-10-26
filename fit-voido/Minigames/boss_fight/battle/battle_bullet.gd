class_name BattleBullet
extends Area2D
## One projectile. Swap the "Visual" AssetSlot texture for your art, or let BossAttack
## draw an error glyph (";", "}", "404"...) on it with set_glyph().

## Physics layer 32: bullets live on it and the heart only listens to it, so nothing in the host game
## (which very rarely uses layer 32) can hurt the heart by accident.
const HIT_LAYER := 1 << 31

@export var damage := 2
@export var velocity := Vector2.ZERO
@export var acceleration := Vector2.ZERO
@export var spin := 0.0
@export var lifetime := 10.0
## Seconds the bullet hangs in place (drawn faded) before it starts moving.
@export var start_delay := 0.0
@export var hit_radius := 6.0
## Removed when it leaves this global rectangle. An empty Rect2 means "never".
var kill_rect := Rect2()

@onready var visual: AssetSlot = %Visual
@onready var _shape: CollisionShape2D = %Collision


func _ready() -> void:
	_set_radius(hit_radius)
	if start_delay > 0.0:
		visual.modulate.a = 0.45


func set_glyph(glyph: String, color: Color) -> void:
	visual.draw_shape = false
	visual.label = glyph
	visual.label_color = color
	visual.label_size = 22
	_set_radius(minf(6.0 + 1.5 * float(glyph.length() - 1), 12.0))


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if start_delay > 0.0:
		start_delay -= delta
		if start_delay <= 0.0:
			visual.modulate.a = 1.0
	else:
		velocity += acceleration * delta
		global_position += velocity * delta
		rotation += spin * delta
	if lifetime <= 0.0 or (kill_rect.has_area() and not kill_rect.has_point(global_position)):
		queue_free()


func _set_radius(radius: float) -> void:
	var circle := _shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius
