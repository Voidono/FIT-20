extends Area2D
@export_file("*.dialogue") var dialogue_path := "res://Dialogues/chapter3_room419.dialogue"
## Tuấn steps out of 419, then stays by the door for follow-up conversations.

var _player: Node2D
var _talking := false
var _professor: DialogueNPC
var _entrance: Tween

func _ready() -> void:
	_professor = preload("res://scenes/Character/dialogue_npc.tscn").instantiate()
	_professor.name = "ProfessorTuan"
	_professor.npc_sprite = preload("res://assets/DrawAsset/NPC/Tuấn.png")
	_professor.npc_name = "Thầy Tuấn"
	_professor.dialogue = load(dialogue_path)
	_professor.mode = DialogueNPC.Mode.STATIONARY
	_professor.walk_bob_height = 0
	_professor.z_index = 3
	_professor.position = Vector2(50, 0)
	add_child(_professor)
	_professor.visible = GameState.has_flag("room419_lead_received")
	_professor.get_node("Body").collision_layer = 1 if _professor.visible else 0
	_professor.monitoring = _professor.visible
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
		if not SceneLoader.is_nearest_door(self, _player): return
		get_viewport().set_input_as_handled()
		_talk()

func _talk() -> void:
	_talking = true
	DialogueNPC.is_any_talking = true
	_player.set_can_move(false)
	_professor.monitoring = false
	_professor.prompt.hide()
	_professor.get_node("Body").collision_layer = 0
	if GameState.has_flag("room416_rescue_complete") and not _professor.visible:
		await _step_out()
	DialogueManager.show_dialogue_balloon_scene(
		preload("res://Dialogues/Bubbles/pixel_balloon.tscn"),
		load(dialogue_path), "start")
	await DialogueManager.dialogue_ended
	_talking = false
	DialogueNPC.is_any_talking = false
	_professor.monitoring = _professor.visible
	_professor.get_node("Body").collision_layer = 1 if _professor.visible else 0
	if is_instance_valid(_player):
		_player.set_can_move(true)

func _step_out() -> void:
	# Professor art has no walk cycle: a short doorway entrance, then a
	# stationary actor. The path ends on the clear corridor, away from the wall.
	_professor.position = Vector2(0, -8)
	_professor.show()
	WorldSfx.play_door()
	_entrance = create_tween().set_parallel(true)
	_entrance.tween_property(_professor, "position", Vector2(50, 0), 0.7).set_trans(Tween.TRANS_SINE)
	var rest_y := _professor.sprite.position.y
	_entrance.tween_method(func(progress: float):
		_professor.sprite.position.y = rest_y - absf(sin(progress * TAU * 2)) * 3.0
	, 0.0, 1.0, 0.7)
	await _entrance.finished
	_professor.position = Vector2(50, 0)
	_professor.sprite.position.y = rest_y

func _exit_tree() -> void:
	if _talking:
		DialogueNPC.is_any_talking = false
