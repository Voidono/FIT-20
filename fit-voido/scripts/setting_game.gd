extends Control

func _ready() -> void:
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	var width := minf(640, size.x - 48)
	var left := (size.x - width) * 0.5
	var stacked := width < 520
	var top := maxf(90, (size.y - (220 if stacked else 160)) * 0.5)
	for i in 2:
		var label: Label = $Label if i == 0 else $Label2
		var slider: HSlider = $Label/HSlider if i == 0 else $Label2/Music
		label.position = Vector2(left, top + i * (100 if stacked else 80))
		label.size = Vector2(width, 44)
		label.add_theme_font_size_override("font_size", 24)
		slider.position = Vector2(0, 44) if stacked else Vector2(width * 0.48, 0)
		slider.size = Vector2(width if stacked else width * 0.52, 44)
	$Button.size = Vector2(56, 56)
	$Button.add_theme_font_size_override("font_size", 28)




func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu & options/menu.tscn")
	pass # Replace with function body.
