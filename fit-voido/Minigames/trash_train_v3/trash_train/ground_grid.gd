@tool
class_name TrashGroundGrid
extends Node2D
## Placeholder ground: coloured yard, faint grid and a border. Delete it and add your own art.

@export var rect := Rect2(0.0, 0.0, 1440.0, 810.0):
	set(value):
		rect = value
		queue_redraw()
@export var outside_color := Color("1d3326")
@export var ground_color := Color("3d7a4c")
@export var grid_color := Color(1, 1, 1, 0.07)
@export var border_color := Color("e8e8e8")
@export_range(20.0, 600.0, 1.0) var grid_step := 120.0


func _draw() -> void:
	draw_rect(rect.grow(3000.0), outside_color)
	draw_rect(rect, ground_color)
	var x := rect.position.x + grid_step
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), grid_color, 2.0)
		x += grid_step
	var y := rect.position.y + grid_step
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), grid_color, 2.0)
		y += grid_step
	draw_rect(rect, border_color, false, 4.0)
