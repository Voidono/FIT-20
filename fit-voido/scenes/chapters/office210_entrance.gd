extends Area2D
## The hallway door opens the actual office; the cutscene owns battle launch.
const OFFICE := "res://scenes/mapsides/phòng210.tscn"
var _player: Node2D
var _opening := false
var _talking := false

func _ready() -> void:
	body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"): _player = body
	)
	body_exited.connect(func(body: Node2D):
		if body == _player: _player = null
	)

func _unhandled_input(event: InputEvent) -> void:
	if _opening or _talking or not is_instance_valid(_player) or DialogueNPC.is_any_talking: return
	if not event.is_action_pressed("interact"): return
	if not SceneLoader.is_nearest_door(self, _player): return
	if "can_move" in _player and not _player.can_move: return
	get_viewport().set_input_as_handled()
	if not GameState.is_chapter_unlocked(4):
		_locked()
		return
	_opening = true
	var scene := get_tree().current_scene
	SceneLoader.office210_return = {"scene": scene.scene_file_path, "position": scene.to_local(_player.global_position)}
	var error := SceneLoader.go_to_spawn(OFFICE, Vector2(256, 280))
	if error == OK: WorldSfx.play_door()
	else: _opening = false

func _locked() -> void:
	_talking = true
	DialogueNPC.is_any_talking = true
	var player := _player
	player.set_can_move(false)
	var balloon = DialogueManager.show_dialogue_balloon_scene(preload("res://Dialogues/Bubbles/pixel_balloon.tscn"), preload("res://Dialogues/office210.dialogue"), "locked")
	await balloon.tree_exited
	_talking = false
	DialogueNPC.is_any_talking = false
	if is_instance_valid(player): player.set_can_move(true)

func _exit_tree() -> void:
	if _talking: DialogueNPC.is_any_talking = false
