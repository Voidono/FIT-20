extends Node2D
## Camera-visible section of the campus circuit. Native drawing keeps the art editable
## and crisp at different viewport sizes; the overview shows the actual four-pitch layout.
const INK := Color("e5e8cc")
var distance: float = 0.0
var race_length: float = 10000.0
var boost: bool = false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var width: float = get_viewport_rect().size.x
	var left: float = floorf((camera.global_position.x - width) / 80.0) * 80.0
	var right: float = camera.global_position.x + width
	draw_rect(Rect2(left, -1000, right - left, 1600), Color("a7aa96"))
	draw_rect(Rect2(left, -130, right - left, 360), Color("608e42"))
	for x in range(int(left), int(right) + 80, 80):
		draw_rect(Rect2(x, -125, 40, 350), Color("6c994a"))
		for y in range(-120, 220, 26):
			draw_line(Vector2(x, y), Vector2(x + 38, y), Color(0.65, 0.75, 0.35, 0.08))
	# Two rows of adjacent small football pitches, like the supplied campus field.
	var start: int = int(floorf(left / 580.0))
	var end: int = int(ceilf(right / 580.0))
	for tile in range(start, end + 1):
		for row in range(2):
			_pitch(Rect2(tile * 580 + 8, -104 + row * 160, 564, 152))
	# The near straight: five charcoal lanes, pale edge lines, paved outer path.
	draw_rect(Rect2(left, 230, right - left, 112), Color("777b72"))
	for lane in range(6):
		var y: float = 230.0 + lane * 22.0
		draw_line(Vector2(left, y), Vector2(right, y), INK, 1.0)
	draw_rect(Rect2(left, 343, right - left, 6), Color("d0cdb9"))
	for x in range(int(left), int(right) + 80, 80):
		draw_line(Vector2(x, 350), Vector2(x, 600), Color("8f9484"))
	# The campus field uses concrete paths and a perimeter fence.
	draw_line(Vector2(left, -116), Vector2(right, -116), Color("cbd5bd"), 3)
	for x in range(int(left), int(right) + 80, 80):
		draw_line(Vector2(x, -135), Vector2(x, -110), Color("cbd5bd"), 2)
	for tile in range(start, end + 1):
		# Paving joints replace the former tree line.
		draw_line(Vector2(tile * 580 + 80, -300), Vector2(tile * 580 + 80, -140), Color("92988a"), 1)
		draw_line(Vector2(tile * 580 + 140, 360), Vector2(tile * 580 + 140, 600), Color("92988a"), 1)
		_spectators(Vector2(tile * 580 + 260, 380))
		var section: int = posmod(tile, 4)
		var words: Array[String] = ["FIT  /  CAMPUS RUN", "KEEP YOUR RHYTHM", "ONE FIELD. ONE FINISH.", "MAKE YOUR MOVE"]
		draw_rect(Rect2(tile * 580 + 330, 354, 220, 24), Color("153d34"))
		draw_string(ThemeDB.fallback_font, Vector2(tile * 580 + 341, 371), words[section], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e7f4ba"))
	# The same start/finish line returns at the end of each lap.
	for lap in range(3):
		var x: float = lap * race_length * 0.5
		if x < left - 25 or x > right + 25:
			continue
		for col in range(2):
			for row in range(14):
				draw_rect(Rect2(x + col * 8, 230 + row * 8, 8, 8), Color("f4f0dc") if (col + row) % 2 == 0 else Color("263f39"))
	# Short streaks communicate a checkpoint boost without hiding the runners.
	if boost:
		for i in range(5):
			var x: float = distance - 38 - i * 13
			draw_line(Vector2(x - 30, 249 + i * 3), Vector2(x, 249 + i * 3), Color(0.75, 1, 0.48, 0.65), 2)

func _pitch(rect: Rect2) -> void:
	draw_rect(rect, INK, false, 1)
	draw_line(Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y), INK)
	draw_arc(rect.get_center(), 27, 0, TAU, 32, INK, 1)
	for side in range(2):
		var x: float = rect.position.x if side == 0 else rect.end.x - 55
		draw_rect(Rect2(x, rect.get_center().y - 43, 55, 86), INK, false, 1)
		var goal_x: float = rect.position.x - 6 if side == 0 else rect.end.x
		draw_rect(Rect2(goal_x, rect.get_center().y - 17, 6, 34), Color("d0d9c8"), false, 2)

func _tree(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 4, p.y - 25, 8, 27), Color("735c40"))
	draw_circle(p + Vector2(5, -33), 27, Color("285e46"))
	draw_circle(p + Vector2(-5, -43), 24, Color("38764b"))
	draw_circle(p + Vector2(-9, -51), 15, Color("4b8c50"))

func _spectators(p: Vector2) -> void:
	var colors: Array[Color] = [Color("f2cc66"), Color("80cbd4"), Color("e58e81"), Color("dbe6cd")]
	for i in range(6):
		var at: Vector2 = p + Vector2(i * 19, 0)
		draw_rect(Rect2(at.x - 4, at.y - 12, 9, 12), colors[i % colors.size()])
		draw_rect(Rect2(at.x - 3, at.y - 18, 7, 7), Color("dbaf86"))
		draw_line(at + Vector2(-2, 0), at + Vector2(-2, 7), Color("2d443f"), 3)
		draw_line(at + Vector2(4, 0), at + Vector2(4, 7), Color("2d443f"), 3)
