class_name TrashHud
extends Control
## Placeholder HUD, kept inside the middle 60% of the screen: score and clock at the top centre,
## and the "tap to start" message. Active powerup bars are drawn below the clock.

var _score := Label.new()
var _time := Label.new()
var _message := Label.new()
var _sub := Label.new()
var _powerup_bar := PowerupBar.new()
var _last_secs := -1
var _low := false


class PowerupBar:
	extends Control
	## Draws a small horizontal bar for each active power-up (color + draining fill).
	var effects: Array[Dictionary] = []  # [{id, color, fraction}]

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(0, 28)

	func set_effects(list: Array[Dictionary]) -> void:
		var changed := list.size() != effects.size()
		if not changed:
			for i in list.size():
				if list[i]["id"] != effects[i]["id"]:
					changed = true
					break
		effects = list
		queue_redraw()

	func _draw() -> void:
		if effects.is_empty():
			return
		var bar_w := 100.0
		var bar_h := 10.0
		var gap := 8.0
		var total_w := effects.size() * bar_w + (effects.size() - 1) * gap
		var start_x := (size.x - total_w) * 0.5
		var y := 4.0
		for i in effects.size():
			var e: Dictionary = effects[i]
			var x := start_x + i * (bar_w + gap)
			draw_rect(Rect2(x, y, bar_w, bar_h), Color(1, 1, 1, 0.15))
			var c: Color = e["color"]
			var f: float = e["fraction"]
			draw_rect(Rect2(x, y, bar_w * f, bar_h), Color(c, 0.85))
			draw_rect(Rect2(x, y, bar_w, bar_h), Color(1, 1, 1, 0.5), false, 1.5)
			# icon to the left of the bar
			TrashPowerups.draw_icon(self, e["id"], c, 0.6)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup(_score, 30, 6.0, 52.0)
	_setup(_time, 24, 50.0, 86.0)
	_powerup_bar.anchor_right = 1.0
	_powerup_bar.offset_top = 88.0
	_powerup_bar.offset_bottom = 116.0
	add_child(_powerup_bar)
	_setup(_message, 40, 150.0, 210.0)
	_setup(_sub, 24, 214.0, 252.0)
	_message.visible = false
	_sub.visible = false
	set_score(0.0)


func set_score(v: float) -> void:
	_score.text = "%s: %s" % [TrashStrings.t(&"score"), TrashStrings.num(v)]


func set_time(seconds: float) -> void:
	var secs := ceili(maxf(seconds, 0.0))
	if secs == _last_secs:
		return
	_last_secs = secs
	_time.text = "%s: %d" % [TrashStrings.t(&"time"), secs]
	var low := secs <= 10
	if low != _low:
		_low = low
		if low:
			_time.add_theme_color_override("font_color", Color("ff6b5b"))
		else:
			_time.remove_theme_color_override("font_color")


func show_ready(goal_points: float) -> void:
	_message.text = TrashStrings.t(&"tap_to_start")
	_sub.text = "%s: %s" % [TrashStrings.t(&"goal"), TrashStrings.num(goal_points)]
	_message.visible = true
	_sub.visible = true


func show_running() -> void:
	_message.visible = false
	_sub.visible = false


func set_powerups(effects: Array[Dictionary]) -> void:
	_powerup_bar.set_effects(effects)


func score_text() -> String:
	return _score.text


func time_text() -> String:
	return _time.text


func message_text() -> String:
	return _message.text if _message.visible else ""


func sub_text() -> String:
	return _sub.text if _sub.visible else ""


func _setup(label: Label, font_size: int, top: float, bottom: float) -> void:
	label.anchor_right = 1.0
	label.offset_top = top
	label.offset_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
