class_name TrashPowerupPickup
extends Area2D
## A power-up lying on the map. Touch it and its effect switches on (no button). It pulses, shows a
## draining ring, and vanishes if nobody takes it in time. TrashPowerups creates and frees these.

signal collected(pickup: TrashPowerupPickup)
signal expired(pickup: TrashPowerupPickup)

const RADIUS := 18.0

var id: StringName = &"magnet"
var lifetime := 12.0

var _left := 12.0
var _t := 0.0
var _done := false


func _init() -> void:
	collision_layer = 0
	collision_mask = TrashLayers.RUNNER
	monitorable = false
	z_index = 90  # above the ground trash, below the tail
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS + 6.0
	cs.shape = circle
	add_child(cs)
	body_entered.connect(_on_body_entered)


func setup(power_id: StringName, seconds: float) -> void:
	id = power_id
	lifetime = maxf(seconds, 0.1)
	_left = lifetime


func seconds_left() -> float:
	return _left


func _process(delta: float) -> void:
	_t += delta
	_left -= delta
	if _left <= 0.0 and not _done:
		_done = true
		expired.emit(self)
		return
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not _done and body.is_in_group(&"trash_player"):
		_done = true
		collected.emit(self)


func _draw() -> void:
	var c := TrashPowerups.color_of(id)
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(Vector2.ZERO, RADIUS + 9.0 + 4.0 * pulse, Color(c, 0.16 + 0.12 * pulse))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.06, 0.07, 0.11, 0.92))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, c, 3.0)
	var f := clampf(_left / lifetime, 0.0, 1.0)  # the ring drains as the time runs out
	draw_arc(Vector2.ZERO, RADIUS + 5.0, -PI * 0.5, -PI * 0.5 + TAU * f, 32, Color(1, 1, 1, 0.85), 2.0)
	TrashPowerups.draw_icon(self, id, c, 1.25)
