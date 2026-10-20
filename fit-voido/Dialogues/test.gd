extends Node

func _ready() -> void:
	var lines: DialogueResource = load('res://Dialogues/test.dialogue')
	DialogueManager.show_dialogue_balloon_scene("res://Dialogues/Bubbles/pixel_balloon.tscn", lines, 'start')
