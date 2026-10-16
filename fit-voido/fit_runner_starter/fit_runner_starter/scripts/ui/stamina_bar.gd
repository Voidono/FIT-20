class_name StaminaBar
extends TextureProgressBar
## Stamina bar. Frame, fill, pattern and the exit notch are textures in stamina_bar.tscn. This script only sets
## the fill amount, the zone colour and pattern, and where the notch sits (where the wall lets go).

@onready var _pattern: TextureRect = $Pattern
@onready var _exit_mark: Control = $ExitMark


func apply(fraction: float, style: ZoneStyle, walled: bool, exit_fraction: float, blink: float) -> void:
	var f: float = clampf(fraction, 0.0, 1.0)
	value = f * max_value
	if style != null:
		tint_progress = style.color
		_pattern.texture = style.pattern
		_pattern.visible = style.pattern != null
	if not is_equal_approx(_pattern.anchor_right, f):
		_pattern.anchor_right = f
	var e: float = clampf(exit_fraction, 0.0, 1.0)
	if not is_equal_approx(_exit_mark.anchor_left, e):
		_exit_mark.anchor_left = e
		_exit_mark.anchor_right = e
	modulate.a = (0.75 + 0.25 * sin(blink * 12.0)) if walled else 1.0
