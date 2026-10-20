@tool
class_name AssetSlot
extends Node2D
## Art slot. Draws a coloured placeholder until `texture` is set.
## For animated art: add an AnimatedSprite2D child and untick `show_placeholder`.

enum Shape { RECT, CIRCLE, HEART }

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export_group("Placeholder")
@export var show_placeholder: bool = true:
	set(value):
		show_placeholder = value
		queue_redraw()
@export var shape: Shape = Shape.RECT:
	set(value):
		shape = value
		queue_redraw()
@export var draw_shape: bool = true:
	set(value):
		draw_shape = value
		queue_redraw()
@export var placeholder_size: Vector2 = Vector2(32, 32):
	set(value):
		placeholder_size = value
		queue_redraw()
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
@export var label: String = "":
	set(value):
		label = value
		queue_redraw()
@export var label_color: Color = Color.BLACK:
	set(value):
		label_color = value
		queue_redraw()
@export var label_size: int = 16:
	set(value):
		label_size = value
		queue_redraw()


func _draw() -> void:
	if texture != null:
		draw_texture(texture, -texture.get_size() * 0.5)
		return
	if not show_placeholder:
		return
	if draw_shape:
		match shape:
			Shape.RECT:
				draw_rect(Rect2(-placeholder_size * 0.5, placeholder_size), color)
			Shape.CIRCLE:
				draw_circle(Vector2.ZERO, minf(placeholder_size.x, placeholder_size.y) * 0.5, color)
			Shape.HEART:
				draw_colored_polygon(_heart_points(), color)
	if label != "":
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size)
		var baseline := (font.get_ascent(label_size) - font.get_descent(label_size)) * 0.5
		draw_string(font, Vector2(-text_size.x * 0.5, baseline), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, label_color)


func _heart_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 36
	var s := minf(placeholder_size.x, placeholder_size.y) / 34.0
	for i in steps:
		var t := TAU * float(i) / float(steps)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(Vector2(x, y - 2.5) * s)
	return points
