class_name TrashNpcs
extends Node2D
## Phone-walker students on fixed waypoint routes. They never chase.
## ONE node moves them all and runs the bump test, so there are no per-NPC physics bodies.
##
## Bump rule: an NPC that overlaps the runner or any tail item cuts the tail at the item closest to
## the runner that it touches (touching the runner = index 0 = everything drops). The touched item
## and everything behind it is dropped. Then bump_invulnerability seconds of immunity follow.
## A hit on an empty tail does nothing. Frozen NPCs (Time Pulse, step 5) are harmless.
##
## Process priority 20: runs after the runner (0) and the tail (10) have moved this frame.

signal bumped(cut_index: int)

## Edit these to reshape the level. Points are world px; an NPC walks them in order and wraps to the
## first, so a two-point route is a back-and-forth patrol. "speed" multiplies tuning.npc_speed.
## (A Path2D can feed these later: PackedVector2Array of curve.get_baked_points().)
const ROUTES := [
	{"points": [Vector2(300, 405), Vector2(1140, 405)], "speed": 0.9},  # the highway between the bins
	{"points": [Vector2(420, 140), Vector2(1020, 140), Vector2(1020, 300), Vector2(420, 300)], "speed": 1.0},
	{"points": [Vector2(1020, 670), Vector2(420, 670), Vector2(420, 510), Vector2(1020, 510)], "speed": 1.0},
	{"points": [Vector2(260, 90), Vector2(260, 720)], "speed": 0.8},  # guards the left bin's mouth
	{"points": [Vector2(1180, 720), Vector2(1180, 90)], "speed": 0.8},  # guards the right bin's mouth
]
const FROZEN_TINT := Color(0.55, 0.8, 1.0)


class Npc:
	extends Node2D
	var points := PackedVector2Array()
	var target := 1  # index of the waypoint being walked to
	var speed_scale := 1.0
	var frozen_left := 0.0
	var enabled := true
	var radius := 16.0
	var facing := Vector2.RIGHT

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color("c7554f"))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color("5b1f1c"), 2.5)
		draw_set_transform(facing * radius * 0.5, facing.angle(), Vector2.ONE)  # the phone, held in front
		draw_rect(Rect2(-3.5, -6.0, 7.0, 12.0), Color("cfeaff"))
		draw_rect(Rect2(-3.5, -6.0, 7.0, 12.0), Color("33546b"), false, 1.5)


var tuning: TrashTrainTuning
var player: Node2D
var tail: TrashTail
var invuln_left := 0.0
var show_routes := true:
	set(value):
		show_routes = value
		queue_redraw()

var _npcs: Array[Npc] = []


func setup(t: TrashTrainTuning, runner: Node2D, tl: TrashTail) -> void:
	tuning = t
	player = runner
	tail = tl
	process_priority = 20
	for route in ROUTES:
		var n := Npc.new()
		n.points = PackedVector2Array(route["points"])
		n.speed_scale = route["speed"]
		n.radius = tuning.npc_radius
		n.position = n.points[0]
		n.target = 1 % n.points.size()
		n.z_index = 150  # above the tail, below the runner
		_npcs.append(n)
		add_child(n)


func freeze_all(seconds: float) -> void:
	for n in _npcs:
		n.frozen_left = seconds


func active_count() -> int:
	var c := 0
	for n in _npcs:
		if n.enabled:
			c += 1
	return c


func frozen_count() -> int:
	var c := 0
	for n in _npcs:
		if n.enabled and n.frozen_left > 0.0:
			c += 1
	return c


func _physics_process(delta: float) -> void:
	if tuning == null:
		return
	invuln_left = maxf(0.0, invuln_left - delta)
	for i in _npcs.size():
		var n := _npcs[i]
		var on := i < tuning.npc_count
		if n.enabled != on:
			n.enabled = on
			n.visible = on
		if not on:
			continue
		if n.radius != tuning.npc_radius:
			n.radius = tuning.npc_radius
			n.queue_redraw()
		if n.frozen_left > 0.0:
			n.frozen_left = maxf(0.0, n.frozen_left - delta)
			n.modulate = FROZEN_TINT
			continue
		n.modulate = Color.WHITE
		_advance(n, tuning.npc_speed * n.speed_scale * delta)
	if invuln_left <= 0.0:
		_check_bump()


func _advance(n: Npc, dist: float) -> void:
	while dist > 0.0:
		var to := n.points[n.target]
		var d := n.position.distance_to(to)
		if d > 0.0001:
			var dir := (to - n.position) / d
			if not dir.is_equal_approx(n.facing):
				n.facing = dir
				n.queue_redraw()
		if d <= dist:
			n.position = to
			dist -= d
			n.target = (n.target + 1) % n.points.size()
		else:
			n.position += n.facing * dist
			dist = 0.0


func _check_bump() -> void:
	var count := tail.count()
	if count == 0:
		return
	var tail_pos := tail.positions()
	var tail_rad := tail.radii()
	var forgive := tuning.npc_hit_forgiveness
	var head_pos := player.global_position
	var head_r := maxf(tuning.player_radius - forgive, 0.0)
	var best := count  # count = nothing hit yet
	for n in _npcs:
		if not n.enabled or n.frozen_left > 0.0:
			continue
		var r := maxf(n.radius - forgive, 0.0)
		var p := n.global_position
		var reach := r + head_r
		if p.distance_squared_to(head_pos) < reach * reach:
			best = 0
			break
		for i in mini(best, count):
			var reach_i := r + maxf(tail_rad[i] - forgive, 0.0)
			if p.distance_squared_to(tail_pos[i]) < reach_i * reach_i:
				best = i
				break
	if best < count:
		invuln_left = tuning.bump_invulnerability
		bumped.emit(best)


func _draw() -> void:  # debug: the routes
	if not show_routes:
		return
	var col := Color(1, 1, 1, 0.22)
	for route in ROUTES:
		var pts := PackedVector2Array(route["points"])
		for p in pts:
			draw_circle(p, 4.0, col)
		if pts.size() > 2:
			pts.append(pts[0])
		draw_polyline(pts, col, 2.0)
