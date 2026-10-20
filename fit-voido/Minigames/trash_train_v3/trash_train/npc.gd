class_name TrashNpc
extends Area2D
## A phone-walker (a scene: npc.tscn). Its HIT AREA is whatever CollisionShape2D / CollisionPolygon2D
## children you draw: touching the runner cuts the whole tail, touching a tail item cuts there.
## Routes (TrashNpcRoute) move it; it never chases. Give npc.tscn your own Sprite2D / AnimatedSprite2D
## and untick draw_placeholder. Frozen NPCs (Time Pulse) are harmless and tinted.

const FROZEN_TINT := Color(0.55, 0.8, 1.0)

@export var draw_placeholder := true
@export_range(6.0, 40.0, 0.5) var placeholder_radius := 16.0

var enabled := true
var frozen_left := 0.0
var facing := Vector2.RIGHT

var _tinted := false


func _ready() -> void:
	collision_layer = TrashLayers.NPC
	collision_mask = TrashLayers.RUNNER | TrashLayers.TAIL
	monitoring = true
	monitorable = false
	z_index = 150  # above the tail, below the runner
	add_to_group(&"trash_npc")


func _physics_process(delta: float) -> void:
	if frozen_left > 0.0:
		frozen_left = maxf(0.0, frozen_left - delta)
	var frozen := frozen_left > 0.0
	if frozen != _tinted:
		_tinted = frozen
		modulate = FROZEN_TINT if frozen else Color.WHITE


func freeze(seconds: float) -> void:
	frozen_left = seconds


func set_enabled(on: bool) -> void:
	enabled = on
	visible = on
	set_deferred("monitoring", on)


func is_harmful() -> bool:
	return enabled and frozen_left <= 0.0


func set_facing(dir: Vector2) -> void:
	if not dir.is_equal_approx(facing):
		facing = dir
		if draw_placeholder:
			queue_redraw()


## Closest-to-the-runner tail index this NPC overlaps (0 also when it touches the runner), -1 = no hit.
func hit_index() -> int:
	if not is_harmful() or not monitoring:  # `monitoring` flips one frame after set_enabled(true)
		return -1
	for b in get_overlapping_bodies():
		if b.is_in_group(&"trash_player"):
			return 0
	var best := -1
	for a in get_overlapping_areas():
		var item := a as TrashTailItem
		if item != null and item.in_use and (best == -1 or item.index < best):
			best = item.index
	return best


func _draw() -> void:
	if not draw_placeholder:
		return
	var r := placeholder_radius
	draw_circle(Vector2.ZERO, r, Color("c7554f"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color("5b1f1c"), 2.5)
	draw_set_transform(facing * r * 0.5, facing.angle(), Vector2.ONE)  # the phone, held in front
	draw_rect(Rect2(-3.5, -6.0, 7.0, 12.0), Color("cfeaff"))
	draw_rect(Rect2(-3.5, -6.0, 7.0, 12.0), Color("33546b"), false, 1.5)
