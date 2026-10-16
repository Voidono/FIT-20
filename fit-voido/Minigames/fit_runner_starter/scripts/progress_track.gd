class_name ProgressTrack
extends Control
## Whole-course strip: elevation profile, water station, final spurt, you and the ghost.
## The camera only shows about 400 px ahead, so this is how the player plans hills and the spurt.

var tuning: RunnerTuning
var course: CourseProfile
var player_progress: float = 0.0
var ghost_progress: float = 0.0
var show_ghost: bool = true


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 30.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if tuning == null or course == null:
		return
	var w: float = size.x
	var bar_y: float = size.y - 6.0
	var max_h: float = 1.0
	for p: Vector2 in tuning.course_points:
		max_h = maxf(max_h, absf(p.y))
	var pts := PackedVector2Array()
	var steps: int = 64
	for i in range(steps + 1):
		var f: float = float(i) / float(steps)
		var hgt: float = course.height_at(f * tuning.track_length)
		pts.append(Vector2(f * w, bar_y - 3.0 - (hgt / max_h) * (size.y - 14.0)))
	draw_polyline(pts, UiTheme.CHALK_DIM, 1.5)
	draw_line(Vector2(0.0, bar_y), Vector2(w, bar_y), UiTheme.INK_SOFT, 5.0)
	draw_line(Vector2(w * tuning.station_start, bar_y), Vector2(w * tuning.station_end, bar_y), UiTheme.WATER_BLUE, 5.0)
	draw_line(Vector2(w * tuning.spurt_start, bar_y), Vector2(w, bar_y), UiTheme.ZONE_SPRINT, 5.0)
	draw_line(Vector2(0.0, bar_y), Vector2(w * clampf(player_progress, 0.0, 1.0), bar_y), UiTheme.CHALK, 2.0)
	if show_ghost:
		draw_circle(Vector2(w * clampf(ghost_progress, 0.0, 1.0), bar_y), 3.0, Color(UiTheme.ZONE_RECOVER, 0.9))
	draw_circle(Vector2(w * clampf(player_progress, 0.0, 1.0), bar_y), 4.0, UiTheme.CHALK)
