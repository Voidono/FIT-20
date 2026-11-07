extends Control

var _design: Control

func _ready() -> void:
	# Preserve the authored pixel-art composition at every window aspect ratio.
	_design = Control.new()
	_design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var artwork := get_children()
	add_child(_design)
	_design.size = Vector2(960, 540)
	for child in artwork:
		child.reparent(_design, false)
	resized.connect(_fit_design)
	_fit_design()

func _fit_design() -> void:
	var factor := minf(size.x / 960.0, size.y / 540.0)
	_design.scale = Vector2.ONE * factor
	_design.position = (size - Vector2(960, 540) * factor) * 0.5




func _on_quit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_play_button_pressed() -> void:
	SceneLoader.go_to("res://scenes/mapsides/nửa đầu.tscn")


func _on_setting_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu & options/setting_game.tscn")
	pass # Replace with function body.
