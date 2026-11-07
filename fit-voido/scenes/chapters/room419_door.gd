extends Area2D
## A conversation through the closed door; no interior scene transition.

var _player: Node2D
var _talking := false

func _ready() -> void:
	body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			_player = body
	)
	body_exited.connect(func(body: Node2D):
		if body == _player and not _talking:
			_player = null
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_player) or _talking or DialogueNPC.is_any_talking:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_talk()

func _talk() -> void:
	_talking = true
	DialogueNPC.is_any_talking = true
	_player.set_can_move(false)
	DialogueManager.show_dialogue_balloon_scene(
		preload("res://Dialogues/Bubbles/pixel_balloon.tscn"),
		load("res://Dialogues/chapter3_room419.dialogue"), "start")
	await DialogueManager.dialogue_ended
	_talking = false
	DialogueNPC.is_any_talking = false
	if is_instance_valid(_player):
		_player.set_can_move(true)

func _exit_tree() -> void:
	if _talking:
		DialogueNPC.is_any_talking = false
