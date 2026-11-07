extends Area2D
## Place beside Room 416's door in the hallway. No room interior is required.

var _player: Node2D
var _panel: CanvasLayer
var _code: LineEdit
var _feedback: Label

func _ready() -> void:
	body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			_player = body
	)
	body_exited.connect(func(body: Node2D):
		if body == _player:
			_player = null
	)

func _unhandled_input(event: InputEvent) -> void:
	if _panel != null or not is_instance_valid(_player) or DialogueNPC.is_any_talking:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not GameState.is_chapter_unlocked(3):
			_show_dialogue()
		elif GameState.has_flag("room416_unlocked"):
			_show_dialogue()
		elif not GameState.has_flag("room416_help_requested"):
			GameState.start_quest("unlock_room_416")
			GameState.complete_quest("reach_room_416")
			_show_dialogue()
		else:
			_open_keypad()

func _show_dialogue() -> void:
	DialogueNPC.is_any_talking = true
	_player.set_can_move(false)
	DialogueManager.show_dialogue_balloon_scene(
		preload("res://Dialogues/Bubbles/pixel_balloon.tscn"),
		load("res://Dialogues/chapter3_room416.dialogue"), "start")
	await DialogueManager.dialogue_ended
	DialogueNPC.is_any_talking = false
	if is_instance_valid(_player):
		_player.set_can_move(true)

func _open_keypad() -> void:
	_panel = CanvasLayer.new()
	_panel.layer = 60
	add_child(_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)
	var box := PanelContainer.new()
	center.add_child(box)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(320, 0)
	box.add_child(list)
	var title := Label.new()
	title.text = "PHÒNG 416 — NHẬP MÃ\nHành trình của FIT bắt đầu từ năm nào?"
	list.add_child(title)
	_code = LineEdit.new()
	_code.max_length = 4
	_code.placeholder_text = "4 chữ số"
	list.add_child(_code)
	_feedback = Label.new()
	list.add_child(_feedback)
	var digits := GridContainer.new()
	digits.columns = 3
	list.add_child(digits)
	for digit in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]:
		var button := Button.new()
		button.text = digit
		button.custom_minimum_size = Vector2(90, 42)
		button.pressed.connect(func():
			if _code.text.length() < 4:
				_code.text += digit
		)
		digits.add_child(button)
	var submit := Button.new()
	submit.text = "Mở cửa"
	submit.pressed.connect(_submit)
	list.add_child(submit)
	_code.text_submitted.connect(func(_text: String): _submit())
	var clear := Button.new()
	clear.text = "Xóa mã"
	clear.pressed.connect(func(): _code.clear())
	list.add_child(clear)
	var back := Button.new()
	back.text = "Quay lại"
	back.pressed.connect(_close_keypad)
	list.add_child(back)
	_player.set_can_move(false)
	_code.grab_focus()

func _submit() -> void:
	if not GameState.try_room416_code(_code.text):
		_feedback.text = "Mã chưa đúng. Năm 2026, FIT tròn 20 tuổi."
		_code.clear()
		_code.grab_focus()
		return
	_close_keypad()
	_show_dialogue()

func _close_keypad() -> void:
	_panel.queue_free()
	_panel = null
	if is_instance_valid(_player):
		_player.set_can_move(true)

func _exit_tree() -> void:
	if _panel != null or DialogueNPC.is_any_talking:
		DialogueNPC.is_any_talking = false
