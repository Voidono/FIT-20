extends CanvasLayer
## A pixel-art tutorial card for Nathan Hoad's Dialogue Manager, made for
## explaining minigames: a centred "how to play" card over a dimmed screen, with
## a title bar, step pips, key caps and a "press to continue" hint. Choices
## (like "Start" or "Show me again") appear under the text.
##
## Write keys in capitals between < and > and they turn into key caps:
##   Press <SPACE> to jump and <ARROWS> to move.
## For step pips, say how many steps there are before the first line:
##   set locals.steps = 3
## The speaker name becomes the card title (default_title is used when a line
## has no speaker).
##
## Laid out for a fixed 640x360 canvas. To change the card's size, edit the Card
## node in the scene.
##
## Show it with:
##   DialogueManager.show_dialogue_balloon_scene("res://dialogue/tutorial_balloon.tscn", resource, "start")


## The action that advances the dialogue.
@export var next_action: StringName = &"ui_accept"

## The action that skips typing (only matters if you turn the typewriter on).
@export var skip_action: StringName = &"ui_cancel"

## Block all other input while the card is showing.
@export var will_block_other_input: bool = true

@export_group("Tutorial")
## Card title for lines that have no speaker.
@export var default_title: String = "How to play"
## The hint at the bottom of the card while waiting for the player. Put keys in capitals between < and >.
@export var continue_hint: String = "Press <ENTER> to continue"
## Key cap background colour, used for every key in the text and the hint.
@export var key_background: Color = Color(0.18, 0.071, 0.141)
## Key cap text colour.
@export var key_text: Color = Color(0.996, 0.682, 0.204)
## The text area always reserves this many lines so the card doesn't change height from step to step.
@export_range(1, 8) var min_text_lines: int = 3
## How dark the screen behind the card gets (0 turns the dimming off).
@export_range(0.0, 1.0) var dim_amount: float = 0.55

@export_group("Step pips")
## Style of a pip for a step that has been reached.
@export var pip_on: StyleBox
## Style of a pip for a step that is still to come.
@export var pip_off: StyleBox

@export_group("Animation")
## Seconds the pop-in takes.
@export var pop_in_time: float = 0.18
## Seconds the pop-out takes.
@export var pop_out_time: float = 0.12
## How small the card starts (pop-in) and ends (pop-out).
@export_range(0.1, 1.0) var pop_scale: float = 0.85


## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player (this also shows / hides the hint and the continue arrow)
var is_waiting_for_input: bool = false:
	set(value):
		is_waiting_for_input = value
		if is_node_ready():
			_set_waiting_visuals(value)

## See if we are running a long mutation and should hide the card
var will_hide_balloon: bool = false

## True while the card is on screen (or animating onto it)
var is_open: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			_close()
	get:
		return dialogue_line

## A cooldown timer for delaying the card hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The step pips in the title bar
var pips: Array[Control] = []

var _step: int = 0
var _seen_lines: Dictionary = {}
var _tween: Tween
var _arrow_tween: Tween
var _key_regex: RegEx = RegEx.new()
var _key_cap: String = ""

## Full-screen control that catches clicks and the "next" action
@onready var balloon: Control = %Balloon
## The dark layer behind the card
@onready var dim: ColorRect = %Dim
## Everything you see (title bar, text, hint, choices). This is what pops in and out.
@onready var card: Control = %Card
@onready var title_label: Label = %TitleLabel
@onready var pips_row: Control = %PipsRow
## The pip that gets copied once for every step
@onready var pip_template: Control = %PipTemplate
@onready var text_column: Control = %TextColumn
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var footer: Control = %Footer
@onready var hint_label: RichTextLabel = %HintLabel
## The little arrow that hops when the player can press next
@onready var continue_arrow: Polygon2D = %ContinueArrow
@onready var responses_panel: Control = %ResponsesPanel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu


func _ready() -> void:
	card.hide()
	dim.modulate.a = 0.0
	pip_template.hide()
	pips_row.hide()
	_set_waiting_visuals(false)

	# Anything like <SPACE> becomes a key cap
	_key_regex.compile("<([A-Z0-9][A-Z0-9 +/-]{0,11})>")
	_key_cap = "[bgcolor=#%s][color=#%s] $1 [/color][/bgcolor]" % [key_background.to_html(false), key_text.to_html(false)]
	hint_label.visible = not continue_hint.is_empty()
	hint_label.text = _decorate_keys(continue_hint)

	var manager = _get_dialogue_manager()
	if is_instance_valid(manager):
		manager.mutated.connect(_on_mutated)

	balloon.gui_input.connect(_on_balloon_gui_input)
	responses_menu.response_selected.connect(_on_responses_menu_response_selected)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	# The ResponseTemplate button is copied once for every response
	if not is_instance_valid(responses_menu.response_template):
		responses_menu.response_template = responses_menu.get_node_or_null("ResponseTemplate")
	if is_instance_valid(responses_menu.response_template):
		responses_menu.response_template.hide()

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	_reserve_text_height()


func _unhandled_input(_event: InputEvent) -> void:
	# Only the card is allowed to handle input while it's showing
	if will_block_other_input:
		get_viewport().set_input_as_handled()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, cue: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		resource = with_dialogue_resource
	show()
	dialogue_line = await resource.get_next_dialogue_line(cue, temporary_game_states)


## Apply any changes to the card given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	# Seeing a line again means the tutorial looped (like "Show me again"), so count from 1 again
	if _seen_lines.has(dialogue_line.id):
		_step = 0
		_seen_lines.clear()
	_seen_lines[dialogue_line.id] = true
	_step += 1

	# Title bar and step pips
	if dialogue_line.character.is_empty():
		title_label.text = default_title
	else:
		title_label.text = tr(dialogue_line.character, "dialogue")
	_update_pips()

	# Text (with <KEY> turned into key caps) and responses
	dialogue_line.text = _decorate_keys(dialogue_line.text)
	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	footer.visible = dialogue_line.responses.is_empty()
	responses_panel.hide()
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our card
	will_hide_balloon = false
	_pop_in()

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_panel.show()
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


func _get_dialogue_manager() -> Object:
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	return get_node_or_null("/root/DialogueManager")


## Keep the text area the same height for every step (min_text_lines tall).
func _reserve_text_height() -> void:
	var font: Font = dialogue_label.get_theme_font(&"normal_font")
	var font_size: int = dialogue_label.get_theme_font_size(&"normal_font_size")
	var line_height: float = font.get_height(font_size) + dialogue_label.get_theme_constant(&"line_separation")
	text_column.custom_minimum_size.y = ceilf(line_height * min_text_lines)


## Turn every <KEY> in some text into a key cap
func _decorate_keys(text: String) -> String:
	return _key_regex.sub(text, _key_cap, true)


## Draw one pip per step (from locals.steps) and fill the ones reached so far
func _update_pips() -> void:
	var total: int = clampi(int(locals.get("steps", 0)), 0, 12)
	pips_row.visible = total > 0

	# Rebuild the pips only when the number of steps changes
	if pips.size() != total:
		for old_pip in pips:
			pips_row.remove_child(old_pip)
			old_pip.queue_free()
		pips.clear()
		for i in total:
			var new_pip: Control = pip_template.duplicate()
			new_pip.unique_name_in_owner = false
			pips_row.add_child(new_pip)
			new_pip.show()
			pips.append(new_pip)

	for i in pips.size():
		var style: StyleBox = pip_on if i < _step else pip_off
		if style:
			pips[i].add_theme_stylebox_override(&"panel", style)


## Show the hint and the arrow while waiting for the player (the footer keeps its space either way)
func _set_waiting_visuals(is_waiting: bool) -> void:
	footer.modulate.a = 1.0 if is_waiting else 0.0
	_set_continue_arrow(is_waiting)


#region Animation


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


## Show or hide the "press to continue" arrow
func _set_continue_arrow(is_shown: bool) -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	continue_arrow.visible = is_shown
	continue_arrow.position.y = 0.0
	if not is_shown:
		return

	# A two-frame hop (instead of a smooth slide) keeps it looking like pixel art
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_callback(func(): continue_arrow.position.y = 3.0)
	_arrow_tween.tween_interval(0.4)
	_arrow_tween.tween_callback(func(): continue_arrow.position.y = 0.0)
	_arrow_tween.tween_interval(0.4)


## Pop the card up from the middle of the screen while the backdrop darkens
func _pop_in() -> void:
	if is_open:
		return
	is_open = true
	_kill_tween()

	if not card.visible:
		card.modulate.a = 0.0
		card.scale = Vector2.ONE * pop_scale
		card.show()
		# Give the containers a frame to work out the card size so we can pivot from its centre
		await get_tree().process_frame
		if not is_open:
			return

	card.pivot_offset = card.size * 0.5
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(card, "scale", Vector2.ONE, pop_in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(card, "modulate:a", 1.0, pop_in_time * 0.6)
	_tween.tween_property(dim, "modulate:a", dim_amount, pop_in_time)


## Shrink the card back down, lighten the backdrop and hide it all
func _pop_out() -> void:
	if not is_open:
		return
	is_open = false
	_kill_tween()

	card.pivot_offset = card.size * 0.5
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(card, "scale", Vector2.ONE * pop_scale, pop_out_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(card, "modulate:a", 0.0, pop_out_time)
	_tween.tween_property(dim, "modulate:a", 0.0, pop_out_time)
	await _tween.finished

	if not is_open:
		card.hide()


## The dialogue is over: pop out, then remove the balloon
func _close() -> void:
	is_waiting_for_input = false
	await _pop_out()
	if owner == null:
		queue_free()
	else:
		hide()


#endregion


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		_pop_out()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.get("is_inline", false):
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion
