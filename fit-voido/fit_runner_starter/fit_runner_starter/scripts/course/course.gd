class_name Course
extends Node2D
## Terrain and props, all real nodes: %Ground (Polygon2D, tiled texture), %Track and %LaneLine (Line2D), %Props
## (prop scenes you instance and place in the Inspector) and %Posts (distance posts, spawned from post_scene).
## The terrain is rebuilt from the course profile in setup(), once per run, never per frame.

const GROUND_Y: float = 250.0  ## world y of flat ground; terrain height is subtracted from it

@export var edge_margin: float = 600.0  ## ground continues this far before the start and after the finish
@export var ramp_step: float = 16.0  ## px between points on a slope (flat stretches only get end points)
@export var ground_depth: float = 400.0
@export var post_scene: PackedScene
@export var post_every: float = 1000.0  ## px between distance posts (10 px = 1 m)

@onready var _ground: Polygon2D = $Ground
@onready var _track: Line2D = $Track
@onready var _lane: Line2D = $LaneLine
@onready var _props: Node2D = $Props
@onready var _posts: Node2D = $Posts

var _tuning: RunnerTuning
var _profile: CourseProfile


func setup(tuning: RunnerTuning, profile: CourseProfile) -> void:
	_tuning = tuning
	_profile = profile
	_build_terrain()
	_place_props()
	_place_posts()


func ground_y_at(x: float) -> float:
	return GROUND_Y - _profile.height_at(x)


func _build_terrain() -> void:
	var length: float = _tuning.track_length
	var cp: PackedVector2Array = _tuning.course_points
	var pts := PackedVector2Array()
	pts.append(Vector2(-edge_margin, ground_y_at(0.0)))
	for i in range(cp.size() - 1):
		var x0: float = cp[i].x * length
		var x1: float = cp[i + 1].x * length
		if is_equal_approx(cp[i].y, cp[i + 1].y):
			pts.append(Vector2(x0, ground_y_at(x0)))
		else:
			var x: float = x0
			while x < x1:
				pts.append(Vector2(x, ground_y_at(x)))
				x += ramp_step
	pts.append(Vector2(length, ground_y_at(length)))
	pts.append(Vector2(length + edge_margin, ground_y_at(length)))

	_track.points = pts
	_lane.points = pts
	var poly := PackedVector2Array(pts)
	var bottom: float = GROUND_Y + ground_depth
	poly.append(Vector2(length + edge_margin, bottom))
	poly.append(Vector2(-edge_margin, bottom))
	_ground.polygon = poly
	_ground.uv = poly  # 1 world px = 1 texture px, so the tile repeats at its own size


func _place_props() -> void:
	for child: Node in _props.get_children():
		var prop := child as CourseProp
		if prop != null:
			prop.place(_tuning, _profile, GROUND_Y)


func _place_posts() -> void:
	for child: Node in _posts.get_children():
		child.queue_free()
	if post_scene == null or post_every <= 0.0:
		return
	var x: float = post_every
	while x < _tuning.track_length - 1.0:
		var post := post_scene.instantiate() as CourseProp
		post.track_pixels = x
		post.label_key = "%d m" % int(x / 10.0)
		_posts.add_child(post)
		post.place(_tuning, _profile, GROUND_Y)
		x += post_every
