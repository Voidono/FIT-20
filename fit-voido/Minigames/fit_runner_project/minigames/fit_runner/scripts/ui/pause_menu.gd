class_name FrPauseMenu
extends PanelContainer
## Pause panel. Buttons are connected to these handlers in pause_menu.tscn.

signal resume_pressed
signal retry_pressed
signal quit_pressed


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
