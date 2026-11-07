@tool
extends Control
## Original, code-native journal emblem and faceted stones; no downloaded assets.
@export var hourglass := false
@export_range(1, 4) var number := 1
var owned := false
var placed := false

func display(is_owned: bool, is_placed: bool) -> void:
	owned = is_owned
	placed = is_placed
	tooltip_text = "Viên đá %d — %s" % [number, "đã đặt vào cổng" if placed else "đã tìm thấy" if owned else "chưa tìm thấy"]
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var gold := Color("d7b578")
	if hourglass:
		c = size * 0.5
		for sign_y in [-1, 1]:
			draw_line(c + Vector2(-7, sign_y * 9), c + Vector2(7, sign_y * 9), gold, 1)
		draw_polyline(PackedVector2Array([c + Vector2(-5, -7), c + Vector2(5, 7), c + Vector2(-5, 7), c + Vector2(5, -7), c + Vector2(-5, -7)]), gold, 1, true)
		draw_circle(c, 1.5, gold)
		return
	c.y -= 5
	var edge := gold if owned else Color("727e75")
	draw_circle(c, 14, Color("1b2626"))
	draw_arc(c, 14, 0, TAU, 32, Color("4b5650"), 1, true)
	var points := PackedVector2Array([c + Vector2(0, -10), c + Vector2(8, -3), c + Vector2(6, 5), c + Vector2(0, 10), c + Vector2(-6, 5), c + Vector2(-8, -3)])
	if owned:
		draw_colored_polygon(points, Color("9d7845"))
		draw_colored_polygon(PackedVector2Array([points[0], points[1], c, points[5]]), Color("e8cf93"))
		draw_colored_polygon(PackedVector2Array([c, points[1], points[2], points[3]]), Color("bd995c"))
	else:
		draw_colored_polygon(points, Color("2b3735"))
	draw_polyline(points + PackedVector2Array([points[0]]), edge, 1, true)
	draw_line(points[0], c, edge, 1, true)
	draw_line(c, points[3], edge, 1, true)
	if placed:
		draw_polyline(PackedVector2Array([c + Vector2(5, 9), c + Vector2(8, 12), c + Vector2(13, 6)]), Color("eee4c9"), 2, true)
	var roman: String = ["I", "II", "III", "IV"][number - 1]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(roman, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(c.x - width / 2, size.y - 1), roman, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, edge)
