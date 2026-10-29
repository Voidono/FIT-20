class_name BattleLaser
extends BattleBullet
## A beam. Thin blinking warning line first, then a thick beam that hurts, then it disappears.
## Only hurts while the beam is active (its collision layer is switched on at that moment).

@export var warn_time := 0.9
@export var active_time := 0.35
@export var thickness := 16.0

var length := 240.0
var horizontal := true

var _time := 0.0
var _active := false


func _ready() -> void:
	super._ready()
	lifetime = warn_time + active_time + 1.0
	_apply()


func configure(p_length: float, p_horizontal: bool, p_warn: float, p_active: float) -> void:
	length = p_length
	horizontal = p_horizontal
	warn_time = p_warn
	active_time = p_active
	lifetime = warn_time + active_time + 1.0
	_apply()


func _physics_process(delta: float) -> void:
	_time += delta
	if not _active:
		visual.modulate.a = 0.3 + 0.4 * float(int(_time * 14.0) % 2)
		if _time >= warn_time:
			_active = true
			collision_layer = HIT_LAYER
			visual.modulate.a = 1.0
			_apply()
	elif _time >= warn_time + active_time:
		queue_free()


func _beam_size() -> Vector2:
	return Vector2(length, thickness) if horizontal else Vector2(thickness, length)


func _apply() -> void:
	var beam := _beam_size()
	var rect := _shape.shape as RectangleShape2D
	if rect != null:
		rect.size = beam
	if _active:
		visual.placeholder_size = beam
	elif horizontal:
		visual.placeholder_size = Vector2(beam.x, 3.0)
	else:
		visual.placeholder_size = Vector2(3.0, beam.y)
