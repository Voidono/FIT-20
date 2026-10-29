class_name FrEffortGauge
extends Control
## Effort gauge. The triangle is effort (what your thumb asks for), the thin line is pace (what the legs do).
## Scheme A shows the cruise band, scheme B shows its tier ticks. Every part is a node with a texture in the scene;
## positions are anchors (0..1 across the gauge), so it scales with the screen.

@onready var _band: Control = FrLookup.node(self, "CruiseBand") as Control
@onready var _ticks: Control = FrLookup.node(self, "Ticks") as Control
@onready var _pace: Control = FrLookup.node(self, "PaceMarker") as Control
@onready var _effort: Control = FrLookup.node(self, "EffortMarker") as Control


func apply(effort: float, pace: float, band_lo: float, band_hi: float, tiers_mode: bool, tier_values: PackedFloat32Array) -> void:
	_set_x(_effort, effort)
	_set_x(_pace, pace)
	_band.visible = not tiers_mode
	if not tiers_mode:
		_set_range(_band, band_lo, band_hi)
	_ticks.visible = tiers_mode
	if tiers_mode:
		var i: int = 0
		for child: Node in _ticks.get_children():
			var tick := child as Control
			if tick == null:
				continue
			tick.visible = i < tier_values.size()
			if tick.visible:
				_set_x(tick, tier_values[i])
			i += 1


func _set_x(c: Control, x: float) -> void:
	var v: float = clampf(x, 0.0, 1.0)
	if not is_equal_approx(c.anchor_left, v):
		c.anchor_left = v
		c.anchor_right = v


func _set_range(c: Control, lo: float, hi: float) -> void:
	if not is_equal_approx(c.anchor_left, lo) or not is_equal_approx(c.anchor_right, hi):
		c.anchor_left = lo
		c.anchor_right = hi
