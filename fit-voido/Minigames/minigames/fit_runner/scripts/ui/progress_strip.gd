class_name FrProgressStrip
extends Control
## Whole-course strip: elevation profile (a Line2D), water station and final spurt (TextureRects), you and the ghost
## (dots). The camera only shows about 400 px ahead, so this is how the player plans hills and the spurt.

@onready var _profile: Line2D = FrLookup.node(self, "Profile") as Line2D
@onready var _bar: TextureProgressBar = FrLookup.node(self, "Bar") as TextureProgressBar
@onready var _water: Control = FrLookup.node(self, "WaterZone") as Control
@onready var _spurt: Control = FrLookup.node(self, "SpurtZone") as Control
@onready var _player: Control = FrLookup.node(self, "PlayerDot") as Control
@onready var _ghost: Control = FrLookup.node(self, "GhostDot") as Control

var _tuning: FrTuning
var _course: FrCourseProfile


func configure(tuning: FrTuning, course: FrCourseProfile) -> void:
	_tuning = tuning
	_course = course
	if _water != null:
		_water.visible = false
	_spurt.anchor_left = tuning.spurt_start
	_spurt.anchor_right = 1.0
	_rebuild_profile()
	_setup_checkpoint_markers()


func _setup_checkpoint_markers() -> void:
	for child in _bar.get_children():
		if child.name.begins_with("CpMarker_"):
			child.queue_free()
	var cp: PackedFloat32Array = _tuning.checkpoint_fractions
	for i in range(cp.size()):
		var f: float = cp[i]
		var marker := ColorRect.new()
		marker.name = "CpMarker_%d" % i
		marker.color = Color(0.2, 0.95, 1.0, 0.85)
		marker.custom_minimum_size = Vector2(2, 8)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.anchor_left = f
		marker.anchor_right = f
		marker.anchor_top = 0.0
		marker.anchor_bottom = 1.0
		marker.offset_left = -1
		marker.offset_right = 1
		marker.offset_top = -2
		marker.offset_bottom = 2
		_bar.add_child(marker)


func apply(player_progress: float, ghost_progress: float) -> void:
	var p: float = clampf(player_progress, 0.0, 1.0)
	_bar.value = p * _bar.max_value
	_set_x(_player, p)
	_set_x(_ghost, clampf(ghost_progress, 0.0, 1.0))


func _on_resized() -> void:
	_rebuild_profile()


func _rebuild_profile() -> void:
	if _tuning == null or _course == null:
		return
	var max_h: float = 1.0
	for p: Vector2 in _tuning.course_points:
		max_h = maxf(max_h, absf(p.y))
	var base_y: float = size.y - 12.0
	var pts := PackedVector2Array()
	var steps: int = 64
	for i in range(steps + 1):
		var f: float = float(i) / float(steps)
		var h: float = _course.height_at(f * _tuning.track_length)
		pts.append(Vector2(f * size.x, base_y - (h / max_h) * (base_y - 2.0)))
	_profile.points = pts


func _set_x(c: Control, x: float) -> void:
	if not is_equal_approx(c.anchor_left, x):
		c.anchor_left = x
		c.anchor_right = x
