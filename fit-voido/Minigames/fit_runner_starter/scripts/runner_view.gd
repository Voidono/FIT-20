class_name RunnerView
extends Node2D
## Placeholder runner drawn from lines and circles (origin = feet). Used for the player and, translucent, for the ghost.

@export var is_ghost: bool = false

var pace: float = 0.0
var tint: Color = Color.WHITE
var _phase: float = 0.0


func set_pose(p_pace: float, p_tint: Color) -> void:
	pace = p_pace
	tint = p_tint


func _process(delta: float) -> void:
	_phase += delta * (3.0 + clampf(pace, 0.0, 1.3) * 11.0)
	queue_redraw()


func _draw() -> void:
	var a: float = 0.4 if is_ghost else 1.0
	var shirt: Color = Color(0.45, 0.85, 1.0, a) if is_ghost else UiTheme.CHALK.lerp(tint, 0.5)
	var shirt_dark: Color = shirt.darkened(0.25)
	var legs: Color = Color(0.3, 0.6, 0.9, a) if is_ghost else UiTheme.INK_SOFT
	var skin: Color = Color(0.8, 0.95, 1.0, a) if is_ghost else Color("e9b98f")
	var band: Color = Color(0.6, 0.9, 1.0, a) if is_ghost else UiTheme.ZONE_SPRINT
	var s: float = sin(_phase)
	var c: float = cos(_phase)
	var run_amount: float = clampf(pace, 0.0, 1.3)
	var stride: float = 3.0 + run_amount * 7.0
	var lean: float = run_amount * 3.0
	var hip := Vector2(0.0, -12.0)
	draw_line(hip, Vector2(-s * stride, -maxf(0.0, -c) * 5.0), legs.darkened(0.2), 3.0)
	draw_line(hip, Vector2(s * stride, -maxf(0.0, c) * 5.0), legs, 3.0)
	draw_line(hip, Vector2(lean, -26.0), shirt, 7.0)
	var shoulder := Vector2(lean, -25.0)
	draw_line(shoulder, shoulder + Vector2(-s * stride * 0.7, 7.0), shirt_dark, 2.5)
	draw_line(shoulder, shoulder + Vector2(s * stride * 0.7, 7.0), shirt, 2.5)
	draw_circle(Vector2(lean + 1.0, -33.0), 5.5, skin)
	draw_line(Vector2(lean - 4.0, -35.0), Vector2(lean + 6.0, -35.0), band, 2.0)
