extends Control
var panel: Control

func _ready() -> void:
	panel = preload("res://scenes/UI/audio_settings_panel.gd").new()
	add_child(panel)
	panel.closed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	SceneLoader.go_to(SceneLoader.MENU)
