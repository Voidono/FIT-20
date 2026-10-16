class_name TrashPickup
extends Area2D
## One piece of trash lying on the ground. Pooled: the root activates / deactivates these
## instead of creating and freeing nodes. Glitch items (lifetime > 0) flicker and then expire.
## launch() is the bump scatter: the item hops to a landing spot and can't be picked up until it lands.
##
## Physics layers: pickups sit on no layer and only DETECT layer 1 (the runner).

signal collected(pickup: TrashPickup)
signal expired(pickup: TrashPickup)

const PICKUP_SLACK := 4.0  # extra px around the item so it is easy to grab
const HOP_HEIGHT := 26.0  # px, visual only

var kind := 0
var active := false

var _age := 0.0
var _lifetime := 0.0
var _fly_from := Vector2.ZERO
var _fly_to := Vector2.ZERO
var _fly_total := 0.0
var _fly_left := 0.0
var _hop := 0.0
var _shape := CollisionShape2D.new()


func _init() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = false
	visible = false
	_shape.shape = CircleShape2D.new()
	add_child(_shape)
	body_entered.connect(_on_body_entered)
	set_process(false)


## lifetime 0 = stays until collected.
func activate(new_kind: int, pos: Vector2, lifetime: float = 0.0) -> void:
	_reset_common(new_kind, lifetime)
	position = pos
	set_deferred("monitoring", true)  # deferred: may be called during a physics callback
	set_process(lifetime > 0.0)
	queue_redraw()


## Dropped by a bump. For glitch items the lifetime starts counting when the item lands.
func launch(new_kind: int, from: Vector2, to: Vector2, duration: float, lifetime: float = 0.0) -> void:
	_reset_common(new_kind, lifetime)
	position = from
	_fly_from = from
	_fly_to = to
	_fly_total = maxf(duration, 0.01)
	_fly_left = _fly_total
	set_deferred("monitoring", false)  # armed on landing
	set_process(true)
	queue_redraw()


func deactivate() -> void:
	active = false
	visible = false
	_fly_left = 0.0
	set_deferred("monitoring", false)
	set_process(false)


func is_flying() -> bool:
	return _fly_left > 0.0


func _reset_common(new_kind: int, lifetime: float) -> void:
	kind = new_kind
	_age = 0.0
	_lifetime = lifetime
	_fly_left = 0.0
	_hop = 0.0
	modulate = Color.WHITE
	(_shape.shape as CircleShape2D).radius = TrashItems.radius_of(kind) + PICKUP_SLACK
	active = true
	visible = true


func _process(delta: float) -> void:
	if _fly_left > 0.0:
		_fly_left = maxf(0.0, _fly_left - delta)
		var t := 1.0 - _fly_left / _fly_total
		position = _fly_from.lerp(_fly_to, 1.0 - (1.0 - t) * (1.0 - t))  # ease out
		_hop = sin(t * PI) * HOP_HEIGHT
		if _fly_left == 0.0:
			position = _fly_to
			_hop = 0.0
			set_deferred("monitoring", true)
			set_process(_lifetime > 0.0)
		queue_redraw()
		return
	_age += delta
	var left := _lifetime - _age
	if left <= 0.0:
		expired.emit(self)
		return
	var rate := 8.0 if left > 1.5 else 22.0  # flicker faster when about to vanish
	modulate.a = 0.45 + 0.55 * absf(sin(_age * rate))


func _on_body_entered(body: Node2D) -> void:
	if active and body.is_in_group(&"trash_player"):
		collected.emit(self)


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -_hop), 0.0, Vector2.ONE)
	TrashItems.draw_placeholder(self, kind)
