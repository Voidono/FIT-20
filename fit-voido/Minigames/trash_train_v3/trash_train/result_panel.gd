class_name TrashResultPanel
extends Control
## End-of-run screen (placeholder look): title, stars, score, a detail line, and big buttons.
## Retry is always there; Continue only after a pass. While it is visible it blocks the pointer.

signal retry_pressed
signal continue_pressed

var retry_button: Button
var continue_button: Button

var _title: Label
var _stars: StarRow
var _score: Label
var _detail: Label
var _panel: PanelContainer


class StarRow:
	extends Control
	var lit := 0:
		set(value):
			lit = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(260.0, 68.0)

	func _draw() -> void:
		for i in 3:
			var pts := star(Vector2(50.0 + i * 80.0, 34.0), 29.0, 12.0)
			var closed := pts.duplicate()
			closed.append(pts[0])
			if i < lit:
				draw_colored_polygon(pts, Color("ffcf3a"))
				draw_polyline(closed, Color("a87b00"), 3.0)
			else:
				draw_colored_polygon(pts, Color(1, 1, 1, 0.10))
				draw_polyline(closed, Color(1, 1, 1, 0.45), 3.0)

	static func star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for i in 10:
			var r := outer if i % 2 == 0 else inner
			out.append(center + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * r)
		return out


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var scroll := ScrollContainer.new()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 12
	scroll.offset_top = 12
	scroll.offset_right = -12
	scroll.offset_bottom = -12
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(center)
	var panel := PanelContainer.new()
	_panel = panel
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	_title = _label(box, 38)
	_stars = StarRow.new()
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_stars)
	_score = _label(box, 30)
	_detail = _label(box, 18)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	retry_button = _button(row)
	continue_button = _button(row)
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var width := minf(480, size.x - 32)
	_panel.custom_minimum_size.x = width
	for button in [retry_button, continue_button]:
		button.custom_minimum_size = Vector2(maxf(100, (width - 64) * 0.5), 48)
		button.add_theme_font_size_override("font_size", 20)


func show_result(r: TrashRunResult, goal_points: float) -> void:
	_title.text = TrashStrings.t(&"result_pass" if r.passed else &"result_fail")
	_stars.lit = r.stars
	var score_text := "%s: %s" % [TrashStrings.t(&"score"), TrashStrings.num(r.banked_score)]
	if not r.passed:
		score_text += " / " + TrashStrings.num(goal_points)
	_score.text = score_text
	_detail.text = "%s: %d     %s: %s     %s: %d" % [TrashStrings.t(&"bumps_label"), r.bumps_taken, TrashStrings.t(&"unbanked"), TrashStrings.num(r.unbanked_points), "Power-ups", r.powerups_taken]
	retry_button.text = TrashStrings.t(&"retry")
	continue_button.text = TrashStrings.t(&"next")
	continue_button.visible = r.passed
	visible = true
	retry_button.grab_focus()


func hide_panel() -> void:
	visible = false


func _label(parent: Control, font_size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l


func _button(parent: Control) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(200.0, 64.0)
	b.add_theme_font_size_override("font_size", 24)
	b.focus_mode = Control.FOCUS_ALL
	parent.add_child(b)
	return b
