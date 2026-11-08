@tool
extends Node2D
## Native pixel-friendly HANU-style plaque: white nameplate and blue number tab.
@export var room_number := "417":
	set(value):
		room_number = value
		queue_redraw()
@export var room_title := "PHÒNG HỌC":
	set(value):
		room_title = value
		queue_redraw()
@export var subtitle := "NHÀ C":
	set(value):
		subtitle = value
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(-52, -14, 104, 28)
	draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size), Color(0, 0, 0, 0.28))
	draw_rect(rect, Color("e8e9e3"))
	draw_rect(Rect2(20, -14, 32, 28), Color("304e83"))
	draw_rect(rect, Color("829196"), false, 1)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-48, -1), room_title, HORIZONTAL_ALIGNMENT_CENTER, 64, 7, Color("30446a"))
	draw_string(font, Vector2(-48, 9), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 64, 6, Color("5f6e7c"))
	draw_string(font, Vector2(21, 6), room_number, HORIZONTAL_ALIGNMENT_CENTER, 30, 15, Color("ffffff"))
