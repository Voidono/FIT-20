extends Area2D

enum Activation { WALK_IN, INTERACT }
@export_group("Destination")
@export_file("*.tscn") var target_scene := "res://scenes/mapsides/t_2.tscn"
## Coordinates relative to the destination scene's root, not this door.
@export var target_position := Vector2(2000, 100)
@export_group("Interaction")
@export var activation: Activation = Activation.INTERACT
@export var prompt_text := "Nhấn E / nút tương tác để mở cửa"
@export_group("Story Lock")
## 1 = no stone required; 2 = Stone #1 required; etc.
@export_range(1, 5) var required_chapter := 2
@export_multiline var locked_message := "Cửa Nhà C đang khóa. Hoàn thành thử thách và trở lại gặp giảng viên để nhận viên đá đầu tiên."
var _changing := false
var _armed := false
var _initializing := true
var _notice: Label
var _notice_layer: CanvasLayer
var _nearby_player: Node2D

func _ready() -> void:
	if activation == Activation.INTERACT:
		# Door artwork can be thin, mirrored or scaled into a wall. The trigger
		# must remain reachable from the floor on either side of that artwork.
		for child in get_children():
			if child is CollisionShape2D and child.shape is RectangleShape2D:
				var rect := child.shape.duplicate() as RectangleShape2D
				var world_scale: Vector2 = child.global_scale.abs().max(Vector2(0.01, 0.01))
				rect.size = rect.size.max(Vector2(80, 128) / world_scale)
				child.shape = rect
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# A player arriving on this same threshold must step away before re-entering.
	await get_tree().create_timer(0.25).timeout
	_armed = activation == Activation.INTERACT or not get_overlapping_bodies().any(func(body: Node2D) -> bool: return body.is_in_group("player"))
	_initializing = false
	if activation == Activation.INTERACT and is_instance_valid(_nearby_player):
		_show_notice(prompt_text)

func _on_body_exited(body: Node2D) -> void:
	if body == _nearby_player:
		_nearby_player = null
		if is_instance_valid(_notice):
			_notice_layer.queue_free()
			_notice = null
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
	if DialogueNPC.is_any_talking or ("can_move" in _nearby_player and not _nearby_player.can_move):
		return
	if event.is_action_pressed("interact") and _armed and not _initializing:
		if not SceneLoader.is_nearest_door(self, _nearby_player): return
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
	if error == OK:
		WorldSfx.play_door()
	if error != OK:
		_changing = false
		_show_notice("Không thể mở khu vực này. Vui lòng thử lại.")

func _show_notice(text: String) -> void:
	if is_instance_valid(_notice):
		_notice.text = text
		return
	var layer := CanvasLayer.new()
	_notice_layer = layer
	layer.layer = 50
	add_child(layer)
	var panel := PanelContainer.new()
	panel.theme = preload("res://scenes/UI/quests/quest_theme.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var margin := maxf(16, (get_viewport().get_visible_rect().size.x - 420) / 2)
	panel.offset_left = margin
	panel.offset_right = -margin
	panel.offset_top = -100
	panel.offset_bottom = -54
	_notice = Label.new()
	_notice.text = text
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_notice)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_color_override("font_color", Color("e9d7af"))
