class_name TrashPopups
extends Node2D
## Floating text ("+7.5", "FULL!", "Bump!"). One node draws all of them, so there is no node churn.

const MAX_POPUPS := 24
const LIFE := 0.9

var _items: Array[Dictionary] = []  # {text, pos, color, size, age}


func _init() -> void:
	z_index = 300
	set_process(false)


func add(text: String, pos: Vector2, color: Color = Color.WHITE, font_size: int = 22) -> void:
	if _items.size() >= MAX_POPUPS:
		_items.pop_front()
	_items.append({"text": text, "pos": pos, "color": color, "size": font_size, "age": 0.0})
	set_process(true)


func count() -> int:
	return _items.size()


func _process(delta: float) -> void:
	for i in range(_items.size() - 1, -1, -1):
		_items[i]["age"] += delta
		if _items[i]["age"] >= LIFE:
			_items.remove_at(i)
	if _items.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for it in _items:
		var t: float = it["age"] / LIFE
		var alpha := 1.0 - t * t
		var p: Vector2 = it["pos"] + Vector2(-100.0, -56.0 * t)  # box is 200 wide, so centre on pos
		var c: Color = it["color"]
		c.a = alpha
		draw_string_outline(font, p, it["text"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, it["size"], 6, Color(0, 0, 0, alpha * 0.85))
		draw_string(font, p, it["text"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, it["size"], c)
