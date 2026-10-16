class_name TrashBin
extends Area2D
## A bin zone. It only reports whether the runner is inside; the root does the banking
## (so the scoring rules live in one place). Detects physics layer 1 (the runner) only.

var bin := TrashItems.Bin.EWASTE
var rect := Rect2()  # world rectangle of the zone
var player_inside := false

var _shape := CollisionShape2D.new()
var _label := Label.new()


func _init() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))


func setup(bin_type: int, zone: Rect2) -> void:
	bin = bin_type
	rect = zone
	position = zone.get_center()
	(_shape.shape as RectangleShape2D).size = zone.size
	_label.size = zone.size
	_label.position = -zone.size * 0.5
	_label.text = TrashStrings.t(&"bin_ewaste" if bin_type == TrashItems.Bin.EWASTE else &"bin_general")
	queue_redraw()


func _on_body(body: Node2D, entered: bool) -> void:
	if body.is_in_group(&"trash_player"):
		player_inside = entered
		queue_redraw()


func _draw() -> void:
	var c := TrashItems.bin_color(bin)
	var r := Rect2(-rect.size * 0.5, rect.size)
	draw_rect(r, Color(c, 0.45 if player_inside else 0.25))
	draw_rect(r, c, false, 4.0)
