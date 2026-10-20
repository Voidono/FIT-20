class_name QtePrompt
extends Control
## The recovery timing bar. Bar, sweet-spot zones and cursor are nodes with textures in qte_prompt.tscn.
## Where it sits: move this node in hud.tscn, or tick follow_runner to pin it above the runner.
## How hard it is, and where the sweet spot is on the bar: the QteSettings resource.

@export var follow_runner: bool = false
@export var follow_offset: Vector2 = Vector2(-110.0, -120.0)  ## from the runner's feet, top-left corner of the prompt
@export var color_perfect: Color = Color("ffd23f")
@export var color_good: Color = Color("a6d84a")
@export var color_miss: Color = Color("ee4266")

@onready var _bar: Control = Lookup.node(self, "Bar") as Control
@onready var _good: Control = Lookup.node(self, "GoodZone") as Control
@onready var _perfect: Control = Lookup.node(self, "PerfectZone") as Control
@onready var _cursor: Control = Lookup.node(self, "Cursor") as Control
@onready var _message: Label = Lookup.node(self, "Message") as Label


func _ready() -> void:
	visible = false
	if follow_runner:
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)


## A new event: place the two zones on the bar.
func begin(target_center: float, perfect_width: float, good_width: float) -> void:
	_place(_good, target_center, good_width)
	_place(_perfect, target_center, perfect_width)
	_message.text = "QTE_TAP"
	_message.add_theme_color_override("font_color", Color.WHITE)
	_cursor.visible = true
	_bar.modulate.a = 1.0


## The event ended with a grade (QteController.Grade) and a stamina bonus.
func show_result(grade: int, bonus: float) -> void:
	var key: String = "QTE_MISS"
	var color: Color = color_miss
	if grade == QteController.Grade.PERFECT:
		key = "QTE_PERFECT"
		color = color_perfect
	elif grade == QteController.Grade.GOOD:
		key = "QTE_GOOD"
		color = color_good
	_message.text = tr(key) + ("  +%d" % roundi(bonus) if bonus >= 0.5 else "")
	_message.add_theme_color_override("font_color", color)
	_cursor.visible = false
	_bar.modulate.a = 0.55


## Called every frame by the Hud. phase: QteController.Phase.
func apply(phase: int, cursor: float, runner_screen_pos: Vector2) -> void:
	visible = phase != QteController.Phase.IDLE
	if not visible:
		return
	if phase == QteController.Phase.ACTIVE and not is_equal_approx(_cursor.anchor_left, cursor):
		_cursor.anchor_left = cursor
		_cursor.anchor_right = cursor
	if follow_runner:
		position = runner_screen_pos + follow_offset


func _place(zone: Control, center: float, width: float) -> void:
	zone.anchor_left = clampf(center - width * 0.5, 0.0, 1.0)
	zone.anchor_right = clampf(center + width * 0.5, 0.0, 1.0)
