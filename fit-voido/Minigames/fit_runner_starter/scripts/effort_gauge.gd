class_name EffortGauge
extends Control
## Shows the single effort value: the triangle is effort (what your thumb is asking for), the thin line is
## pace (what the legs actually do, with inertia). Scheme A shows the cruise band, scheme B shows its tiers.

var effort: float = 0.0
var pace: float = 0.0
var band_lo: float = 0.5
var band_hi: float = 0.74
var tiers_mode: bool = false
var tier_values: PackedFloat32Array = PackedFloat32Array()


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 14.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(0.0, 3.0, w, h - 6.0), UiTheme.INK, true)
	if tiers_mode:
		for v: float in tier_values:
			var tx: float = w * clampf(v, 0.0, 1.0)
			draw_line(Vector2(tx, 3.0), Vector2(tx, h - 3.0), UiTheme.CHALK_DIM, 2.0)
	else:
		var x0: float = w * band_lo
		var x1: float = w * band_hi
		draw_rect(Rect2(x0, 3.0, maxf(x1 - x0, 1.0), h - 6.0), Color(UiTheme.ZONE_CRUISE, 0.55), true)
	var px: float = w * clampf(pace, 0.0, 1.0)
	draw_line(Vector2(px, 0.0), Vector2(px, h), UiTheme.CHALK_DIM, 2.0)
	var ex: float = w * clampf(effort, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(ex - 5.0, 0.0), Vector2(ex + 5.0, 0.0), Vector2(ex, 7.0)]), UiTheme.CHALK)
	draw_rect(Rect2(0.0, 3.0, w, h - 6.0), UiTheme.CHALK_DIM, false, 1.0)
