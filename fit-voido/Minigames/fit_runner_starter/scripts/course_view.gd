class_name CourseView
extends Node2D
## Placeholder world: sky, two parallax hill layers, ground that follows the course profile, signs and the
## finish arch. World px, the runner moves along +x. Replace the _draw code with sprites in the pixel-art pass.

const GROUND_Y: float = 250.0  ## world y of flat ground; terrain height is subtracted from it
const MARGIN: float = 48.0
const STEP: float = 8.0
const TRACK_DEPTH: float = 16.0

var _tuning: RunnerTuning
var _course: CourseProfile
var _cam: Vector2 = Vector2.ZERO
var _view: Vector2 = Vector2(640.0, 360.0)


func setup(tuning: RunnerTuning, course: CourseProfile) -> void:
	_tuning = tuning
	_course = course


func set_view(cam: Vector2, view_size: Vector2) -> void:
	_cam = cam
	_view = view_size
	queue_redraw()


func _draw() -> void:
	if _tuning == null or _course == null:
		return
	var left: float = _cam.x - MARGIN
	var right: float = _cam.x + _view.x + MARGIN
	var top: float = _cam.y - MARGIN
	var bottom: float = _cam.y + _view.y + MARGIN

	draw_polygon(
		PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)]),
		PackedColorArray([UiTheme.SKY_TOP, UiTheme.SKY_TOP, UiTheme.SKY_BOTTOM, UiTheme.SKY_BOTTOM])
	)
	_draw_hills(UiTheme.HILL_FAR, 0.35, 0.58, 26.0, 0.006, 0.0, left, right, bottom)
	_draw_hills(UiTheme.HILL_NEAR, 0.6, 0.70, 18.0, 0.011, 2.0, left, right, bottom)

	var top_pts := PackedVector2Array()
	var x: float = floorf(left / STEP) * STEP
	while x <= right + STEP:
		top_pts.append(Vector2(x, GROUND_Y - _course.height_at(x)))
		x += STEP
	var lawn := PackedVector2Array(top_pts)
	lawn.append(Vector2(top_pts[top_pts.size() - 1].x, bottom))
	lawn.append(Vector2(top_pts[0].x, bottom))
	draw_colored_polygon(lawn, UiTheme.LAWN)
	var strip := PackedVector2Array(top_pts)
	for i in range(top_pts.size() - 1, -1, -1):
		strip.append(top_pts[i] + Vector2(0.0, TRACK_DEPTH))
	draw_colored_polygon(strip, UiTheme.TRACK)
	draw_polyline(top_pts, UiTheme.CHALK, 2.0)
	_draw_signs(left, right)


func _draw_hills(color: Color, factor: float, base_frac: float, amp: float, freq: float, phase: float, left: float, right: float, bottom: float) -> void:
	var pts := PackedVector2Array()
	var x: float = floorf(left / 16.0) * 16.0
	while x <= right + 16.0:
		var u: float = (x - _cam.x) + _cam.x * factor
		var y: float = _cam.y + _view.y * base_frac + amp * sin(u * freq + phase) + amp * 0.5 * sin(u * freq * 2.3 + phase * 1.7)
		pts.append(Vector2(x, y))
		x += 16.0
	pts.append(Vector2(pts[pts.size() - 1].x, bottom))
	pts.append(Vector2(pts[0].x, bottom))
	draw_colored_polygon(pts, color)


func _draw_signs(left: float, right: float) -> void:
	var t: RunnerTuning = _tuning
	var length: float = t.track_length
	var font: Font = UiTheme.font()
	var post: float = 1000.0  # a distance post every 100 m (10 px = 1 m)
	var k: float = ceilf(left / post) * post
	while k <= right:
		if k > 0.0 and k < length:
			var gy: float = GROUND_Y - _course.height_at(k)
			draw_line(Vector2(k, gy), Vector2(k, gy - 18.0), UiTheme.CHALK, 2.0)
			draw_string(font, Vector2(k - 20.0, gy - 22.0), "%d m" % int(k / 10.0), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 10, UiTheme.CHALK)
		k += post
	_flag(0.0, Strings.t("SIGN_START"), UiTheme.CHALK, left, right)
	_flag(length * 0.25, Strings.t("SIGN_HILL"), UiTheme.ZONE_PUSH, left, right)
	_flag(length * t.spurt_start, Strings.t("SIGN_SPURT"), UiTheme.ZONE_SPRINT, left, right)
	var ws: float = length * t.station_start
	var we: float = length * t.station_end
	if we >= left and ws <= right:
		_flag(ws, Strings.t("SIGN_WATER"), UiTheme.WATER_BLUE, left, right)
		for i in range(3):
			var tx: float = lerpf(ws + 40.0, we - 40.0, float(i) / 2.0)
			var ty: float = GROUND_Y - _course.height_at(tx)
			draw_rect(Rect2(tx - 14.0, ty - 14.0, 28.0, 10.0), UiTheme.WATER_BLUE, true)
			draw_line(Vector2(tx - 12.0, ty - 4.0), Vector2(tx - 12.0, ty), UiTheme.CHALK, 2.0)
			draw_line(Vector2(tx + 12.0, ty - 4.0), Vector2(tx + 12.0, ty), UiTheme.CHALK, 2.0)
	_draw_finish(left, right)


func _flag(x: float, text: String, color: Color, left: float, right: float) -> void:
	if x < left - 80.0 or x > right + 80.0:
		return
	var gy: float = GROUND_Y - _course.height_at(x)
	var w: float = 78.0
	draw_line(Vector2(x, gy), Vector2(x, gy - 46.0), UiTheme.CHALK, 3.0)
	draw_rect(Rect2(x, gy - 46.0, w, 18.0), color, true)
	draw_string(UiTheme.font(), Vector2(x, gy - 33.0), text, HORIZONTAL_ALIGNMENT_CENTER, w, 11, UiTheme.INK)


func _draw_finish(left: float, right: float) -> void:
	var x: float = _tuning.track_length
	if x < left - 120.0 or x > right + 120.0:
		return
	var gy: float = GROUND_Y - _course.height_at(x)
	draw_line(Vector2(x - 40.0, gy), Vector2(x - 40.0, gy - 90.0), UiTheme.CHALK, 4.0)
	draw_line(Vector2(x + 40.0, gy), Vector2(x + 40.0, gy - 90.0), UiTheme.CHALK, 4.0)
	draw_rect(Rect2(x - 40.0, gy - 90.0, 80.0, 30.0), UiTheme.INK, true)
	var logo: Texture2D = UiTheme.logo()
	if logo != null:
		draw_texture_rect(logo, Rect2(x - 36.0, gy - 88.0, 72.0, 26.0), false)
	else:
		draw_string(UiTheme.font(), Vector2(x - 40.0, gy - 68.0), "FIT", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 18, UiTheme.CHALK)
	for i in range(8):
		var col: Color = UiTheme.CHALK if i % 2 == 0 else UiTheme.INK
		draw_rect(Rect2(x - 4.0, gy + float(i) * 2.0, 8.0, 2.0), col, true)
