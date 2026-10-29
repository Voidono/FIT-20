class_name BattleBox
extends Panel
## The white-bordered box. Resizes around `anchor_point` (its bottom-centre).
## It also hosts the flavour text, the choice list, the fight bar and the BACK button.

@export var menu_size := Vector2(576, 140)
@export var anchor_point := Vector2(320, 390)
@export var border_width := 5.0
@export var resize_time := 0.25
## Show an on-screen BACK button while a list is open (touch screens have no X key).
@export var show_back_button := true

@onready var flavor: BattleText = %FlavorText
@onready var choices: BattleChoiceList = %ChoiceList
@onready var fight_bar: BattleFightBar = %FightBar
@onready var back_button: Button = %BackButton

var _tween: Tween


func _ready() -> void:
	_apply_size(menu_size)
	back_button.hide()
	choices.opened.connect(_on_choices_opened)
	choices.closed.connect(back_button.hide)
	back_button.pressed.connect(choices.cancel)


## Instantly back to the resting menu state (used when an attempt restarts).
func reset() -> void:
	if _tween != null:
		_tween.kill()
	_apply_size(menu_size)
	flavor.clear_text()
	flavor.show()


func resize_to(target: Vector2) -> void:
	if size.is_equal_approx(target):
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_size, size, target, resize_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _tween.finished


func start_dodge(dodge_size: Vector2) -> void:
	flavor.clear_text()
	flavor.hide()
	await resize_to(dodge_size)


func end_dodge() -> void:
	await resize_to(menu_size)
	flavor.show()


func get_inner_rect() -> Rect2:
	return Rect2(global_position, size).grow(-border_width)


func get_center() -> Vector2:
	return global_position + size * 0.5


func _apply_size(new_size: Vector2) -> void:
	size = new_size
	position = anchor_point - Vector2(new_size.x * 0.5, new_size.y)


func _on_choices_opened() -> void:
	back_button.visible = show_back_button
