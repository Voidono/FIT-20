extends Control




func _on_quit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mapsides/level_choose_area.tscn")
	pass # Replace with function body.


func _on_setting_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu & options/setting_game.tscn")
	pass # Replace with function body.
