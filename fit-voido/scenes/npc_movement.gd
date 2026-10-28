@tool
class_name NPCMovement
extends Node2D
## Makes its parent (e.g. a DialogueNPC) walk around. Add it as a child of any NPC
## instance, pick a mode in the Inspector, done. NPCs without this node stay still.
##
## PATROL: add Marker2D children and drag them around in the editor as waypoints.
## WANDER: the NPC picks random spots around where it started (blue circle in editor).
## It pauses automatically while the parent is talking (interaction_started /
## interaction_finished signals), and can face the player while they talk.

signal started_moving
signal stopped_moving
## Emitted when the dominant walking direction changes (Vector2.RIGHT / LEFT / UP / DOWN).
signal facing_changed(direction: Vector2)

enum Mode { STATIONARY, WANDER, PATROL }

@export var mode: Mode = Mode.WANDER:
	set(value):
		mode = value
		queue_redraw()
		if Engine.is_editor_hint():
			if is_inside_tree():
				update_configuration_warnings()
		elif is_node_ready():
			_restart()

@export_group("Movement")
@export_range(5.0, 300.0, 1.0, "suffix:px/s") var speed: float = 40.0
## How close counts as "arrived".
@export_range(1.0, 20.0, 0.5, "suffix:px") var arrive_distance: float = 4.0

@export_group("Wander")
## Random targets are picked within this distance of the NPC's starting position.
@export_range(8.0, 1000.0, 1.0, "suffix:px") var wander_radius: float = 100.0:
	set(value):
		wander_radius = value
		queue_redraw()

@export_group("Patrol")
## Off = loop through the markers 1,2,3,1,2,3. On = 1,2,3,2,1,2,3...
@export var ping_pong: bool = false

@export_group("Waiting")
@export_range(0.0, 30.0, 0.1, "suffix:s") var min_wait: float = 1.5
@export_range(0.0, 30.0, 0.1, "suffix:s") var max_wait: float = 4.0

@export_group("Pathfinding")
## Off: walks in straight lines and skips targets that a wall blocks (uses Obstacle Mask).
## On: follows a baked NavigationRegion2D / TileMap navigation layer around obstacles.
@export var use_navigation: bool = false
## Navigation only: NPCs steer around each other (RVO avoidance).
@export var avoid_other_npcs: bool = false
## Straight-line mode only: physics layers that block the NPC (walls, water...).
## Leave the player and NPC layers off.
@export_flags_2d_physics var obstacle_mask: int = 1

@export_group("Interaction")
@export var pause_while_talking: bool = true
@export var face_player_when_talking: bool = true

@export_group("Visuals")
## Flip the Sprite2D left/right depending on walking direction.
@export var flip_sprite: bool = true
@export var sprite_faces_right: bool = true
## Little hop while walking, so a single static texture still looks alive. 0 = off.
@export_range(0.0, 8.0, 0.5, "suffix:px") var walk_bob_height: float = 1.5
@export_range(0.05, 0.5, 0.01, "suffix:s") var walk_bob_time: float = 0.12

var _body: Node2D
var _sprite: Sprite2D
var _agent: NavigationAgent2D
var _timer: Timer
var _home: Vector2
var _target: Vector2
var _moving := false
var _give_up_left := 0.0
var _patrol_points: Array[Vector2] = []
var _patrol_index := -1
var _patrol_step := 1
var _bob_tween: Tween
var _sprite_rest_y := 0.0
var _facing := Vector2.ZERO
var _warned_no_nav := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_process(false)
	set_physics_process(false)
	_body = get_parent() as Node2D
	if _body == null:
		push_warning("%s must be a child of a Node2D." % name)
		return
	# Children are ready before their parent, so wait for the NPC's @onready vars (sprite).
	if not _body.is_node_ready():
		await _body.ready
	_setup()


func _setup() -> void:
	_home = _body.global_position

	_sprite = _body.get(&"sprite") as Sprite2D
	if _sprite == null:
		_sprite = _body.find_child("Sprite", true, false) as Sprite2D
	if _sprite:
		_sprite_rest_y = _sprite.position.y

	for child in get_children():
		if child is Marker2D:
			_patrol_points.append((child as Marker2D).global_position)

	# Physics-process timer so the raycast in _is_path_clear() runs at a safe time.
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_timer.timeout.connect(_on_wait_finished)
	add_child(_timer)

	if use_navigation:
		_agent = NavigationAgent2D.new()
		_agent.path_desired_distance = arrive_distance
		_agent.target_desired_distance = arrive_distance
		_agent.max_speed = speed
		_agent.avoidance_enabled = avoid_other_npcs
		_agent.velocity_computed.connect(_apply_velocity)
		_body.add_child(_agent) # parent of the agent decides its position

	if _body.has_signal(&"interaction_started"):
		_body.connect(&"interaction_started", _on_interaction_started)
		_body.connect(&"interaction_finished", _on_interaction_finished)

	_schedule_wait(true)


## Call from cutscenes/quests to send the NPC somewhere right now.
## Returns false if the spot is blocked / unreachable. Use `await stopped_moving` to wait for arrival.
func walk_to(point: Vector2) -> bool:
	if _timer == null:
		return false
	_timer.stop()
	var ok := _try_go_to(point)
	if not ok:
		_schedule_wait()
	return ok


# --- Decision making -------------------------------------------------------

func _schedule_wait(first: bool = false) -> void:
	if mode == Mode.STATIONARY:
		return
	var t := randf_range(min_wait, maxf(min_wait, max_wait))
	if first:
		t = randf_range(0.1, maxf(0.1, max_wait)) # desync NPCs so they don't all start together
	_timer.start(maxf(t, 0.05))


func _on_wait_finished() -> void:
	match mode:
		Mode.WANDER:
			_pick_wander_target()
		Mode.PATROL:
			_pick_patrol_target()


func _pick_wander_target() -> void:
	for attempt in 8:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(wander_radius * 0.25, wander_radius)
		if _try_go_to(_home + offset):
			return
	_schedule_wait() # nothing reachable this time, try again later


func _pick_patrol_target() -> void:
	var count := _patrol_points.size()
	if count == 0:
		push_warning("%s: Patrol mode needs Marker2D children as waypoints." % get_path())
		return
	_patrol_index += _patrol_step
	if ping_pong:
		if _patrol_index >= count:
			_patrol_step = -1
			_patrol_index = maxi(count - 2, 0)
		elif _patrol_index < 0:
			_patrol_step = 1
			_patrol_index = mini(1, count - 1)
	else:
		_patrol_index = wrapi(_patrol_index, 0, count)
	if not _try_go_to(_patrol_points[_patrol_index]):
		_schedule_wait()


func _try_go_to(point: Vector2) -> bool:
	if use_navigation:
		var map := _agent.get_navigation_map()
		if NavigationServer2D.map_get_regions(map).is_empty():
			if not _warned_no_nav:
				_warned_no_nav = true
				push_warning("%s: Use Navigation is on but there is no NavigationRegion2D / baked navmesh." % get_path())
			return false
		point = NavigationServer2D.map_get_closest_point(map, point)
		_agent.target_position = point
	elif not _is_path_clear(_body.global_position, point):
		return false
	_target = point
	_start_moving()
	return true


func _is_path_clear(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, obstacle_mask)
	query.collide_with_areas = false
	if _body is CollisionObject2D:
		query.exclude = [(_body as CollisionObject2D).get_rid()]
	return _body.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


# --- Moving ----------------------------------------------------------------

func _start_moving() -> void:
	_moving = true
	# If something keeps the NPC from arriving (stuck on a corner), give up eventually.
	_give_up_left = _body.global_position.distance_to(_target) / speed * 2.5 + 1.0
	set_physics_process(true)
	_play_bob(true)
	started_moving.emit()


func _stop_moving() -> void:
	var was_moving := _moving
	_moving = false
	set_physics_process(false)
	_play_bob(false)
	if was_moving:
		stopped_moving.emit()
	_schedule_wait()


func _physics_process(delta: float) -> void:
	if not _moving:
		return
	_give_up_left -= delta
	if _give_up_left <= 0.0:
		_stop_moving()
		return

	var pos := _body.global_position
	var next := _target
	if use_navigation:
		if _agent.is_navigation_finished():
			_stop_moving()
			return
		next = _agent.get_next_path_position()
	elif pos.distance_to(_target) <= maxf(arrive_distance, speed * delta):
		_stop_moving()
		return

	var desired := pos.direction_to(next) * speed
	if use_navigation and _agent.avoidance_enabled:
		_agent.velocity = desired # result arrives via velocity_computed -> _apply_velocity
	else:
		_apply_velocity(desired)


func _apply_velocity(velocity: Vector2) -> void:
	if not _moving:
		return
	_body.global_position += velocity * get_physics_process_delta_time()
	_face(velocity)


func _restart() -> void:
	if _timer == null:
		return
	_moving = false
	set_physics_process(false)
	_play_bob(false)
	_timer.stop()
	_schedule_wait(true)


# --- Talking ---------------------------------------------------------------

func _on_interaction_started() -> void:
	if not pause_while_talking:
		return
	_set_paused(true)
	if face_player_when_talking:
		var group: StringName = _body.get(&"player_group") if "player_group" in _body else &"player"
		var player := get_tree().get_first_node_in_group(group) as Node2D
		if player:
			_face(player.global_position - _body.global_position)


func _on_interaction_finished() -> void:
	_set_paused(false)


func _set_paused(paused: bool) -> void:
	_timer.paused = paused
	set_physics_process(not paused and _moving)
	_play_bob(not paused and _moving)


# --- Visuals ---------------------------------------------------------------

func _face(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	if _sprite and flip_sprite and absf(direction.x) > 0.01:
		_sprite.flip_h = (direction.x < 0.0) == sprite_faces_right
	var cardinal := Vector2(signf(direction.x), 0.0) if absf(direction.x) >= absf(direction.y) \
			else Vector2(0.0, signf(direction.y))
	if cardinal != _facing:
		_facing = cardinal
		facing_changed.emit(cardinal)


func _play_bob(active: bool) -> void:
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null
	if _sprite == null:
		return
	_sprite.position.y = _sprite_rest_y
	if not active or walk_bob_height <= 0.0:
		return
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_sprite, "position:y", _sprite_rest_y - walk_bob_height, walk_bob_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bob_tween.tween_property(_sprite, "position:y", _sprite_rest_y, walk_bob_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# --- Editor helpers --------------------------------------------------------

func _process(_delta: float) -> void:
	# Editor only (disabled at runtime): keeps the gizmo in sync while you drag markers.
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var parent := get_parent() as Node2D
	var center := to_local(parent.global_position) if parent else Vector2.ZERO
	var color := Color(0.3, 0.8, 1.0)
	match mode:
		Mode.WANDER:
			draw_circle(center, wander_radius, Color(color, 0.08))
			draw_arc(center, wander_radius, 0.0, TAU, 64, Color(color, 0.8), 1.0)
		Mode.PATROL:
			var points := PackedVector2Array()
			for child in get_children():
				if child is Marker2D:
					points.append((child as Marker2D).position)
			if points.size() >= 2:
				draw_polyline(points, Color(color, 0.8), 1.0)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not (get_parent() is Node2D):
		warnings.append("Must be a child of a Node2D (for example your DialogueNPC).")
	if mode == Mode.PATROL and get_children().filter(func(c): return c is Marker2D).is_empty():
		warnings.append("Patrol mode needs Marker2D children as waypoints.")
	return warnings
