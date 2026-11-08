extends Control
## Original vector/pixel motifs for the title, Time Gate and result screens.
var backdrop := false
var placed := [false, false, false, false]
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	if size.x <= 0 or size.y <= 0: return
	if backdrop:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0b1718"))
		for x in range(0, int(size.x), 40):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.55, 0.46, 0.045))
		for y in range(0, int(size.y), 40):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.3, 0.55, 0.46, 0.045))
		for i in 50:
			var p := Vector2(fmod(i * 137.3 + 21, size.x), fmod(i * 79.7 + 13, size.y))
			draw_rect(Rect2(p, Vector2(2, 2)), Color(0.9, 0.8, 0.5, 0.14))
		return
	var c := size * 0.5
	var compact := size.y < 80
	var radius := minf(size.y * 0.32 if compact else size.y * 0.5 - 18, size.x * 0.2)
	for i in 3:
		draw_arc(c, radius + i * (3 if compact else 9), 0, TAU, 64, Color(0.7, 0.64, 0.4, 0.5 - i * 0.14), 1, true)
	draw_line(c + Vector2(-radius * 2.8, 0), c - Vector2(radius + 28, 0), Color("53604e"), 1)
	draw_line(c + Vector2(radius + 28, 0), c + Vector2(radius * 2.8, 0), Color("53604e"), 1)
	for i in 4:
		var p := c + Vector2.from_angle(-PI / 2 + i * PI / 2) * radius
		var d := 0.5 if compact else 1.0
		var diamond := PackedVector2Array([p + Vector2(0, -11) * d, p + Vector2(8, 0) * d, p + Vector2(0, 11) * d, p + Vector2(-8, 0) * d])
		draw_circle(p, 16 * d, Color("162824"))
		draw_colored_polygon(diamond, Color("e5c580") if placed[i] else Color("526d5e"))
		draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color("c1b38b"), 1, true)
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-110 - radius, 5), "2006", HORIZONTAL_ALIGNMENT_CENTER, 70, 18, Color("b8c5b2"))
	draw_string(font, c + Vector2(radius + 40, 5), "2026", HORIZONTAL_ALIGNMENT_CENTER, 70, 18, Color("b8c5b2"))
	var h := 0.55 if compact else 1.0
	draw_polyline(PackedVector2Array([c + Vector2(-10, -17) * h, c + Vector2(10, -17) * h, c + Vector2(-10, 17) * h, c + Vector2(10, 17) * h, c + Vector2(-10, -17) * h]), Color("e5c580"), 2, true)
