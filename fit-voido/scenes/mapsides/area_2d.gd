extends Area2D

enum Activation { WALK_IN, INTERACT }
@export_group("Destination")
@export_file("*.tscn") var target_scene := "res://scenes/mapsides/t_2.tscn"
## Coordinates relative to the destination scene's root, not this door.
@export var target_position := Vector2(2000, 100)
@export_group("Interaction")
@export var activation: Activation = Activation.WALK_IN
@export var prompt_text := "Nhấn E / nút tương tác để mở cửa"
@export_group("Story Lock")
## 1 = no stone required; 2 = Stone #1 required; etc.
@export_range(1, 5) var required_chapter := 2
@export_multiline var locked_message := "Cửa Nhà C đang khóa. Hoàn thành thử thách và trở lại gặp giảng viên để nhận viên đá đầu tiên."
var _changing := false
var _armed := false
var _initializing := true
var _notice: Label
var _nearby_player: Node2D

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# A player arriving on this same threshold must step away before re-entering.
	await get_tree().create_timer(0.25).timeout
	_armed = not get_overlapping_bodies().any(func(body: Node2D) -> bool: return body.is_in_group("player"))
	_initializing = false

func _on_body_exited(body: Node2D) -> void:
	if body == _nearby_player:
		_nearby_player = null
	if body.is_in_group("player") and not _initializing:
		_armed = true

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_nearby_player = body
	if activation == Activation.INTERACT:
		if not _initializing:
			_show_notice(prompt_text)
		return
	_try_use(body)

func _unhandled_input(event: InputEvent) -> void:
	if activation != Activation.INTERACT or not is_instance_valid(_nearby_player):
		return
	if event.is_action_pressed("interact") and _armed and not _initializing:
		get_viewport().set_input_as_handled()
		_try_use(_nearby_player)

func _try_use(body: Node2D) -> void:
	if not body.is_in_group("player") or _changing or not _armed or _initializing:
		return
	if not GameState.is_chapter_unlocked(required_chapter):
		_show_notice(locked_message)
		return
	_changing = true
	_change_scene.call_deferred()

func _change_scene() -> void:
	var error := SceneLoader.go_to_spawn(target_scene, target_position)
	if error != OK:
		_changing = false
		_show_notice("Không thể mở khu vực này. Vui lòng thử lại.")

func _show_notice(text: String) -> void:
	if is_instance_valid(_notice):
		_notice.text = text
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_notice = Label.new()
	_notice.text = text
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_notice.position = Vector2(-260, -90)
	_notice.size = Vector2(520, 80)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_color_override("font_outline_color", Color.BLACK)
	_notice.add_theme_constant_override("outline_size", 6)
	layer.add_child(_notice)
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(layer):
		layer.queue_free()
