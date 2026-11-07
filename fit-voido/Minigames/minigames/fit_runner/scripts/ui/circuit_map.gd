extends Control
## The overview is a circuit, while the race camera unfolds each section into a side view.
var player_progress: float = 0.0
var ghosts := PackedFloat32Array()
const COLORS: Array[Color] = [Color("8ce1f1"), Color("ffbf87"), Color("c3a8f5"), Color("f6db7b"), Color("f4a9c7")]

func update_race(progress: float, rivals: PackedFloat32Array) -> void:
	player_progress = progress
	ghosts = rivals
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(8, 8, size.x - 16, size.y - 16)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("112c28")
	panel.set_corner_radius_all(12)
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	var path: PackedVector2Array = _path(rect)
	draw_polyline(path, Color("69786d"), 13, true)
	draw_polyline(path, Color("d1d3b6"), 1, true)
	var inner: Rect2 = rect.grow(-12)
	draw_rect(inner, Color("527e40"))
	for col in range(2):
		for row in range(2):
			var pitch := Rect2(inner.position + Vector2(col * inner.size.x / 2, row * inner.size.y / 2), inner.size / 2)
			draw_rect(pitch.grow(-2), Color("c1d09d"), false, 1)
	for i in range(ghosts.size()):
		var p: Vector2 = _point(ghosts[i], rect)
		draw_circle(p, 4, COLORS[i % COLORS.size()])
	var you: Vector2 = _point(player_progress, rect)
	draw_circle(you, 7, Color("112c28"))
	draw_circle(you, 4.5, Color("ddff8a"))
	draw_line(Vector2(rect.position.x + 12, rect.end.y - 5), Vector2(rect.position.x + 12, rect.end.y + 5), Color.WHITE, 2)

func _path(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(129):
		points.append(_point(float(i) / 128.0 / 2.0, rect))
	return points

func _point(progress: float, rect: Rect2) -> Vector2:
	# Rounded rectangle with straight lengths proportional to the reference field.
	var radius: float = minf(14, rect.size.y * 0.25)
	var w: float = rect.size.x - radius * 2
	var h: float = rect.size.y - radius * 2
	var perimeter: float = 2 * w + 2 * h + TAU * radius
	var d: float = fposmod(progress * 2.0, 1.0) * perimeter
	var origin: Vector2 = rect.position + Vector2(radius, rect.size.y)
	if d < w: return origin + Vector2(d, 0)
	d -= w
	if d < PI * radius / 2: return rect.end - Vector2(radius, radius) + Vector2(sin(d / radius), cos(d / radius)) * radius
	d -= PI * radius / 2
	if d < h: return Vector2(rect.end.x, rect.end.y - radius - d)
	d -= h
	if d < PI * radius / 2: return Vector2(rect.end.x - radius, rect.position.y + radius) + Vector2(cos(d / radius), -sin(d / radius)) * radius
	d -= PI * radius / 2
	if d < w: return Vector2(rect.end.x - radius - d, rect.position.y)
	d -= w
	if d < PI * radius / 2: return rect.position + Vector2(radius, radius) + Vector2(-sin(d / radius), -cos(d / radius)) * radius
	d -= PI * radius / 2
	if d < h: return Vector2(rect.position.x, rect.position.y + radius + d)
	d -= h
	return Vector2(rect.position.x + radius, rect.end.y - radius) + Vector2(-cos(d / radius), sin(d / radius)) * radius
