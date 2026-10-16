class_name TrashHud
extends Control
## Placeholder HUD: score at top centre (inside the middle 60% of the screen).
## The timer (step 4) and the Pulse button (step 5) get added here.

var _score := Label.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score.anchor_right = 1.0
	_score.offset_top = 6.0
	_score.offset_bottom = 52.0
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score.add_theme_font_size_override("font_size", 30)
	_score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_score.add_theme_constant_override("outline_size", 8)
	add_child(_score)
	set_score(0.0)


func set_score(v: float) -> void:
	_score.text = "%s: %s" % [TrashStrings.t(&"score"), TrashStrings.num(v)]


func score_text() -> String:
	return _score.text
