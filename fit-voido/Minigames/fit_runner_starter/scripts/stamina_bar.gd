class_name StaminaBar
extends Control
## Colour-coded stamina bar. Zone is also shown as a hatch pattern here and as glyph + name next to it,
## so it never relies on colour alone. The white notch marks where the wall lets go.

var value: float = 1.0  ## 0..1
var zone: int = 1
var walled: bool = false
var exit_mark: float = 0.35
var blink: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 16.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	draw_rect(full, UiTheme.INK, true)
	var inner_w: float = size.x - 4.0
	var inner_h: float = size.y - 4.0
	var fill_w: float = inner_w * clampf(value, 0.0, 1.0)
	var col: Color = UiTheme.zone_color(zone)
	if walled and int(blink * 4.0) % 2 == 0:
		col = col.lightened(0.3)
	draw_rect(Rect2(2.0, 2.0, fill_w, inner_h), col, true)
	# hatch: sparse stripes in Push, dense in Sprint, crosshatch-ish dots in Wall
	var step: float = 0.0
	if zone == UiTheme.ZONE_PUSH_ID:
		step = 10.0
	elif zone == UiTheme.ZONE_SPRINT_ID:
		step = 5.0
	elif zone == UiTheme.ZONE_WALL_ID:
		step = 7.0
	if step > 0.0:
		var x: float = 2.0
		while x + inner_h <= 2.0 + fill_w:
			draw_line(Vector2(x, 2.0 + inner_h), Vector2(x + inner_h, 2.0), Color(UiTheme.INK, 0.45), 1.0)
			x += step
	var mx: float = 2.0 + inner_w * clampf(exit_mark, 0.0, 1.0)
	draw_line(Vector2(mx, 0.0), Vector2(mx, size.y), UiTheme.CHALK, 1.0)
	draw_rect(full, UiTheme.CHALK_DIM, false, 1.0)
