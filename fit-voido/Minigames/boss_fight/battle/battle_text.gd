class_name BattleText
extends RichTextLabel
## Typewriter text for the box's flavour text and the placeholder speech bubble.
## Optional child: an AudioStreamPlayer named "Blip" plays once per revealed character.
## While typing, X / Z / a tap skips to the end. When say() waits, Z / Enter / a tap advances.

signal finished_typing
signal _confirmed

@export var chars_per_second := 45.0
@export var allow_skip := true
@export var hide_when_cleared := false
## Seconds the text stays after typing when say() does not wait for confirm.
@export var linger_time := 1.2

var _typing := false
var _waiting := false
var _progress := 0.0
var _start_frame := -1
var _wait_frame := -1

@onready var _blip := get_node_or_null(^"Blip") as AudioStreamPlayer


func _ready() -> void:
	set_process(false)
	clear_text()


## Types the text and returns when it is fully shown.
func type_text(new_text: String) -> void:
	text = new_text
	visible_characters = 0
	_progress = 0.0
	_typing = true
	_start_frame = Engine.get_process_frames()
	show()
	set_process(true)
	await finished_typing


## Types the text, waits (confirm or linger_time), then clears it.
func say(new_text: String, wait_for_confirm := true) -> void:
	await type_text(new_text)
	if wait_for_confirm:
		_waiting = true
		_wait_frame = Engine.get_process_frames()
		await _confirmed
	else:
		await get_tree().create_timer(linger_time).timeout
	clear_text()


func clear_text() -> void:
	var was_typing := _typing
	var was_waiting := _waiting
	_typing = false
	_waiting = false
	set_process(false)
	text = ""
	visible_characters = -1
	if hide_when_cleared:
		hide()
	if was_typing:
		finished_typing.emit()
	if was_waiting:
		_confirmed.emit()


func _input(event: InputEvent) -> void:
	var frame := Engine.get_process_frames()
	if _waiting and frame > _wait_frame and BattleInput.is_confirm(event):
		_waiting = false
		get_viewport().set_input_as_handled()
		_confirmed.emit()
	elif _typing and allow_skip and frame > _start_frame \
			and (BattleInput.is_cancel(event) or BattleInput.is_confirm(event)):
		_progress = float(get_total_character_count())


func _process(delta: float) -> void:
	if not _typing:
		return
	var total := get_total_character_count()
	var before := int(_progress)
	_progress += chars_per_second * delta
	var shown := mini(int(_progress), total)
	visible_characters = shown
	if _blip != null and shown > before:
		_blip.play()
	if shown >= total:
		_typing = false
		set_process(false)
		visible_characters = -1
		finished_typing.emit()
