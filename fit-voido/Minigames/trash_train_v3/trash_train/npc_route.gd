class_name TrashNpcRoute
extends Path2D
## An NPC patrol. Draw the curve with the Path2D tools (click to add points, drag handles to curve it).
## At game start it spawns `count` NPCs (from npc_scene, or the game's default) on PathFollow2D nodes
## spread evenly along the curve.
##   PING_PONG: walks to the end, turns round, walks back.
##   LOOP:      keeps going and wraps at the end. For a closed loop end the curve on its first point.

enum Mode { LOOP, PING_PONG }

@export var npc_scene: PackedScene  ## empty = the TrashTrain root's default NPC
@export_range(1, 8, 1) var count := 1
@export var mode: Mode = Mode.PING_PONG
@export_range(0.1, 3.0, 0.05) var speed_scale := 1.0  ## multiplies tuning.npc_speed
@export_range(0.0, 1.0, 0.01) var start_ratio := 0.0  ## where along the curve the first NPC starts
@export var enabled := true
@export var debug_color := Color(1, 1, 1, 0.25)

var show_route := false:
	set(value):
		show_route = value
		queue_redraw()

var _tuning: TrashTrainTuning
var _followers: Array[PathFollow2D] = []
var _dirs := PackedFloat32Array()


func _ready() -> void:
	add_to_group(&"trash_route")
	set_physics_process(false)


func npcs() -> Array[TrashNpc]:
	var out: Array[TrashNpc] = []
	for f in _followers:
		out.append(f.get_child(0) as TrashNpc)
	return out


func follower_of(npc: TrashNpc) -> PathFollow2D:
	return npc.get_parent() as PathFollow2D


## Called by the game once the tree is ready.
func setup(tuning: TrashTrainTuning, default_scene: PackedScene) -> void:
	_tuning = tuning
	if not enabled:
		return
	if curve == null or curve.point_count < 2:
		push_warning("TrashNpcRoute '%s' needs a curve with at least 2 points." % name)
		return
	var scene := npc_scene if npc_scene != null else default_scene
	for i in count:
		var follower := PathFollow2D.new()
		follower.rotates = false
		follower.loop = mode == Mode.LOOP
		add_child(follower)
		follower.progress_ratio = fposmod(start_ratio + float(i) / count, 1.0)
		var npc := scene.instantiate() as TrashNpc
		if npc == null:
			push_error("TrashNpcRoute '%s': the root of npc_scene must use trash_train/npc.gd (TrashNpc)." % name)
			follower.queue_free()
			return
		follower.add_child(npc)
		_followers.append(follower)
		_dirs.append(1.0)
	process_priority = 15
	set_physics_process(not _followers.is_empty())


func _physics_process(delta: float) -> void:
	var length := curve.get_baked_length()
	if length <= 0.0:
		return
	var step := _tuning.npc_speed * speed_scale * delta
	for i in _followers.size():
		var follower := _followers[i]
		var npc := follower.get_child(0) as TrashNpc
		if not npc.enabled or npc.frozen_left > 0.0:
			continue
		var before := npc.global_position
		if mode == Mode.LOOP:
			follower.progress = fposmod(follower.progress + step, length)
		else:
			var p := follower.progress + step * _dirs[i]
			if p >= length:
				p = length
				_dirs[i] = -1.0
			elif p <= 0.0:
				p = 0.0
				_dirs[i] = 1.0
			follower.progress = p
		var moved := npc.global_position - before
		if moved.length_squared() > 0.0001:
			npc.set_facing(moved.normalized())


func _draw() -> void:
	if not show_route or curve == null:
		return
	var pts := curve.get_baked_points()
	if pts.size() >= 2:
		draw_polyline(pts, debug_color, 2.0)
	for i in curve.point_count:
		draw_circle(curve.get_point_position(i), 4.0, debug_color)
