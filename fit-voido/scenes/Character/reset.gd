extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_key_pressed(KEY_F8):
		GameState.reset_progress()
		print("Dialogue progress reset.")
