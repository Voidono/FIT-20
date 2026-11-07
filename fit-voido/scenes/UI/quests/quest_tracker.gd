extends CanvasLayer
## A quiet journal: one next action and four stones, independent of the camera.
const GUIDANCE = preload("res://scenes/UI/quests/journey_guidance.gd")
@export var preferred_width := 308.0
@export var screen_margin := 14.0

var current_objective: Dictionary = {}
var _refresh_pending := false
var _in_dialogue := false
var _last_stones := -1
var _pulse: Tween
var _fold_preference_set := false

@onready var panel: PanelContainer = $Root/Panel
@onready var toggle: Button = $Root/Panel/Body/Header/Toggle
@onready var heading: Label = $Root/Panel/Body/Header/Label
@onready var chapter: Label = $Root/Panel/Body/Details/Chapter
@onready var title: Label = $Root/Panel/Body/Details/Title
@onready var objective: Label = $Root/Panel/Body/Details/Objective
@onready var location: Label = $Root/Panel/Body/Details/Location
@onready var counter: Label = $Root/Panel/Body/Details/Counter
@onready var details: VBoxContainer = $Root/Panel/Body/Details
@onready var count: Label = $Root/Panel/Body/Footer/Tally/Count
@onready var stones: HBoxContainer = $Root/Panel/Body/Footer/Stones
@onready var divider: HSeparator = $Root/Panel/Body/Divider

func _ready() -> void:
	GameState.quests_changed.connect(_queue_refresh)
	GameState.progression_changed.connect(_queue_refresh)
	GameState.quiz_result_recorded.connect(func(_id: String, _result: Dictionary): _queue_refresh())
	GameState.flag_changed.connect(func(_id: String, _value: bool): _queue_refresh())
	DialogueManager.dialogue_started.connect(_dialogue_started)
	DialogueManager.dialogue_ended.connect(_dialogue_ended)
	toggle.toggled.connect(func(_folded: bool):
		_fold_preference_set = true
		_apply_fold()
	)
	get_viewport().size_changed.connect(_resize)
	get_tree().root.child_entered_tree.connect(func(_node: Node): _update_scene.call_deferred())
	panel.minimum_size_changed.connect(func(): _fit_height.call_deferred())
	_refresh()
	_resize()
	_update_scene.call_deferred()
	var waypoint := preload("res://scenes/UI/quests/quest_waypoint.gd").new()
	add_child(waypoint)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _in_dialogue:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_J:
		toggle.button_pressed = not toggle.button_pressed
		get_viewport().set_input_as_handled()

func _queue_refresh() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	_refresh.call_deferred()

func _refresh() -> void:
	_refresh_pending = false
	if not is_node_ready():
		return
	current_objective = GUIDANCE.resolve(GameState)
	var data := current_objective
	title.text = str(data.get("title", "Một hành trình đang chờ"))
	objective.text = str(data.get("objective", "Khám phá khuôn viên. Những cuộc trò chuyện sẽ dẫn lối cho bạn."))
	var number := int(data.get("chapter", 0))
	chapter.text = "CHƯƠNG %02d  /  %s" % [number, GUIDANCE.CHAPTERS[number - 1]] if number > 0 else "GHI CHÉP HÀNH TRÌNH"
	if str(data.get("id", "")) == "journey_complete":
		chapter.text = "2006 — 2026  /  KÝ ỨC FIT"
	location.text = str(data.get("location", ""))
	location.visible = not location.text.is_empty()
	counter.visible = int(data.get("target", 1)) > 1
	counter.text = "%d / %d" % [int(data.get("progress", 0)), int(data.get("target", 1))]
	var collected := GameState.time_stone_count()
	count.text = "%d / 4" % collected
	for i in range(4):
		stones.get_child(i).display(GameState.has_time_stone(i + 1), GameState.has_flag("gate_stone_%d" % (i + 1)))
	if _last_stones >= 0 and collected > _last_stones and visible:
		if _pulse and _pulse.is_valid():
			_pulse.kill()
		stones.modulate = Color("ffe0a2")
		_pulse = create_tween()
		_pulse.tween_property(stones, "modulate", Color.WHITE, 0.6)
	_last_stones = collected
	_apply_fold()

func _dialogue_started(_resource: DialogueResource) -> void:
	_in_dialogue = true
	_apply_fold()

func _dialogue_ended(_resource: DialogueResource) -> void:
	_in_dialogue = false
	_apply_fold()

func _apply_fold() -> void:
	var folded := toggle.button_pressed or _in_dialogue
	heading.text = title.text if folded else "NHẬT KÝ THỜI GIAN"
	heading.add_theme_font_size_override("font_size", 13 if folded else 11)
	details.visible = not folded
	divider.visible = not folded
	toggle.text = "+" if folded else "−"
	toggle.disabled = _in_dialogue
	toggle.tooltip_text = "Mở nhật ký (J)" if folded else "Thu gọn nhật ký (J)"
	_fit_height.call_deferred()

func _update_scene() -> void:
	var scene := get_tree().current_scene
	visible = scene != null and (scene.scene_file_path.begins_with("res://scenes/mapsides/") or scene.is_in_group("quest_hud_host"))
	# Scene changes can interrupt the old balloon before it emits ended.
	# Clear that transient state while the journal is off screen.
	if not visible and _in_dialogue:
		_in_dialogue = false
		_apply_fold()

func _resize() -> void:
	if not is_node_ready():
		return
	var screen := get_viewport().get_visible_rect().size
	var compact := screen.x < 760
	if not _fold_preference_set:
		toggle.set_pressed_no_signal(screen.y < 420 or DeviceInput.is_mobile())
	var width := minf(272.0 if compact else preferred_width, screen.x - screen_margin * 2)
	panel.position = Vector2(screen_margin, screen_margin).round()
	panel.custom_minimum_size.x = width
	panel.size.x = width
	title.add_theme_font_size_override("font_size", 18 if compact else 20)
	objective.add_theme_font_size_override("font_size", 13 if compact else 14)
	_apply_fold()
	_fit_height.call_deferred()

func _fit_height() -> void:
	if not is_node_ready():
		return
	panel.size.y = panel.get_combined_minimum_size().y
