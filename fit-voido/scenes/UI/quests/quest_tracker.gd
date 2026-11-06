extends CanvasLayer
## Autoload HUD, independent of the player and camera. GameState is the manager.

const ROW = preload("res://scenes/UI/quests/quest_row.tscn")
@export var show_completed: bool = true
@export var preferred_width: float = 288.0
@export var screen_margin: float = 12.0
var _rows: Dictionary = {}
@onready var panel: PanelContainer = $Root/Panel
@onready var body: VBoxContainer = $Root/Panel/Body
@onready var toggle: Button = $Root/Panel/Body/Toggle
@onready var scroll: ScrollContainer = $Root/Panel/Body/Scroll
@onready var list: VBoxContainer = $Root/Panel/Body/Scroll/List
@onready var empty: Label = $Root/Panel/Body/Scroll/List/Empty

func _ready() -> void:
	GameState.quests_changed.connect(_refresh)
	toggle.toggled.connect(_toggle)
	get_viewport().size_changed.connect(_resize)
	list.minimum_size_changed.connect(func(): _resize.call_deferred())
	get_tree().root.child_entered_tree.connect(_root_child_entered)
	_refresh()
	_resize()
	_update_scene.call_deferred()

func _root_child_entered(_node: Node) -> void:
	_update_scene.call_deferred()

func _update_scene() -> void:
	var scene := get_tree().current_scene
	# Existing exploration maps. Menus, loading screens and standalone minigames
	# keep their own interfaces. New gameplay locations can opt in with this group.
	visible = scene != null and (scene.scene_file_path.begins_with("res://scenes/mapsides/") or scene.is_in_group("quest_hud_host"))

func _refresh() -> void:
	var present: Dictionary = {}
	var quests := GameState.tracked_quests()
	for data in quests:
		if bool(data["completed"]) and not show_completed:
			continue
		var id: String = data["id"]
		present[id] = true
		if not _rows.has(id):
			var row := ROW.instantiate()
			list.add_child(row)
			_rows[id] = row
		_rows[id].display(data)
	for id in _rows.keys():
		if not present.has(id):
			list.remove_child(_rows[id])
			_rows[id].queue_free()
			_rows.erase(id)
	empty.visible = present.is_empty()
	toggle.text = ("+" if toggle.button_pressed else "−") + " NHIỆM VỤ (%d)" % present.size()
	_resize.call_deferred()

func _toggle(collapsed: bool) -> void:
	scroll.visible = not collapsed
	_refresh()

func set_show_completed(enabled: bool) -> void:
	show_completed = enabled
	if is_node_ready():
		_refresh()

func _resize() -> void:
	var screen := get_viewport().get_visible_rect().size
	var margin := minf(screen_margin, screen.x * 0.03)
	# Bound width and list height; overflow scrolls rather than covering gameplay.
	var width := minf(preferred_width, screen.x - margin * 2.0)
	panel.position = Vector2(margin, margin).round()
	panel.custom_minimum_size.x = width
	panel.size.x = width
	scroll.custom_minimum_size.y = minf(list.get_combined_minimum_size().y, maxf(48.0, screen.y * 0.4 - 68.0))
	panel.reset_size()

