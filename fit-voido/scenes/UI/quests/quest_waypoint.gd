extends Control
## Screen-space marker; all positions come from live nodes, not copied coordinates.
const DESTINATION = preload("res://scenes/UI/quests/quest_destination.gd")
const GOLD := Color("e4c47c")
const INK := Color("14221f")
var targets: Array[Dictionary] = []
var _refresh_left := 0.0
var _scene: Node
var _id := ""
var _elapsed := 0.0
var marker_positions: Array[Vector2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DialogueManager.dialogue_started.connect(func(_resource: DialogueResource): hide())
	DialogueManager.dialogue_ended.connect(func(_resource: DialogueResource): visible = get_parent().visible)

func _process(delta: float) -> void:
	_elapsed += delta
	_refresh_left -= delta
	var journal := get_parent()
	visible = journal.visible and not journal._in_dialogue and not get_tree().paused
	if not visible: return
	var scene := get_tree().current_scene
	var id: String = journal.current_objective.get("id", "")
	if _refresh_left <= 0 or scene != _scene or id != _id:
		_scene = scene
		_id = id
		_refresh_left = 0.2
		targets = DESTINATION.resolve(scene, id)
	queue_redraw()

func _draw() -> void:
	marker_positions.clear()
	if not visible or targets.is_empty(): return
	var screen := get_viewport_rect().size
	var camera := get_viewport().get_canvas_transform()
	var safe := Rect2(Vector2(30, 84), screen - Vector2(60, 150))
	var center := screen * 0.5
	var nearest: Dictionary = {}
	var nearest_distance := INF
	var any_on_screen := false
	var journal_rect: Rect2 = get_parent().panel.get_global_rect().grow(20)
	for item in targets:
		if not is_instance_valid(item.node): continue
		var foot: Vector2 = camera * item.node.global_position
		var point: Vector2 = camera * (item.node.global_position + Vector2(0, -58))
		if Rect2(Vector2(24, 76), screen - Vector2(48, 130)).has_point(point) and not journal_rect.has_point(point):
			any_on_screen = true
			# The NPC's own name/E prompt takes over at interaction distance.
			if "_in_range" in item.node and item.node.get("_in_range"):
				continue
			point.y += sin(_elapsed * 2) * 3
			_draw_pin(point, item.label)
		else:
			var distance := foot.distance_squared_to(center)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = {"point": foot, "label": item.label}
	if not any_on_screen and not nearest.is_empty():
		var direction: Vector2 = (nearest.point - center).normalized()
		var reach := INF
		if absf(direction.x) > 0.001:
			reach = minf(reach, ((safe.end.x if direction.x > 0 else safe.position.x) - center.x) / direction.x)
		if absf(direction.y) > 0.001:
			reach = minf(reach, ((safe.end.y if direction.y > 0 else safe.position.y) - center.y) / direction.y)
		var point := center + direction * maxf(0, reach)
		if journal_rect.has_point(point):
			point.y = minf(screen.y - 64, journal_rect.end.y + 14)
		_draw_arrow(point, direction, nearest.label)

func _draw_pin(point: Vector2, title: String) -> void:
	marker_positions.append(point)
	draw_circle(point, 14, INK)
	var diamond := PackedVector2Array([point + Vector2(0, -9), point + Vector2(7, 0), point + Vector2(0, 9), point + Vector2(-7, 0), point + Vector2(0, -9)])
	draw_colored_polygon(diamond, GOLD)
	draw_line(point + Vector2(-5, 20), point + Vector2(0, 25), GOLD, 2, true)
	draw_line(point + Vector2(0, 25), point + Vector2(5, 20), GOLD, 2, true)
	_caption(point + Vector2(0, -34), title)

func _draw_arrow(point: Vector2, direction: Vector2, title: String) -> void:
	marker_positions.append(point)
	draw_circle(point, 17, INK)
	var side := direction.orthogonal()
	var points := PackedVector2Array([point + direction * 12, point - direction * 8 + side * 8, point - direction * 4, point - direction * 8 - side * 8])
	draw_colored_polygon(points, GOLD)
	_caption(point + Vector2(0, 30), title)

func _caption(point: Vector2, title: String) -> void:
	var font := ThemeDB.fallback_font
	var width := minf(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16, size.x - 32)
	var position := Vector2(clampf(point.x - width * 0.5, 16, size.x - width - 16), clampf(point.y - 18, 6, size.y - 28))
	draw_style_box(_caption_style(), Rect2(position, Vector2(width, 24)))
	draw_string(font, position + Vector2(8, 17), title, HORIZONTAL_ALIGNMENT_LEFT, width - 16, 13, GOLD)

func _caption_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.09, 0.94)
	style.set_corner_radius_all(4)
	return style
