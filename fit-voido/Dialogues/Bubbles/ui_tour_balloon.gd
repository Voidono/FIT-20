extends CanvasLayer
## A pixel-art UI tour for Nathan Hoad's Dialogue Manager, made for teaching the
## player the basic interface. The screen dims, a flashing frame lights up one
## part of the interface and a callout points at it, one step per dialogue line.
##
## Point a line at something with a target tag (see target_tag) whose value is
## the name of an interface node. That node has to be in the target_group group
## (Node dock > Groups) and be a Control or a Sprite2D. A line with no target dims
## the whole screen and puts the callout in the middle.
##
## It has the same extras as the tutorial card: capitals between < and > become
## key caps, "set locals.steps = 4" before the first line shows step pips, and the
## speaker name is the callout title.
##
## Laid out for a fixed 640x360 canvas. Show it with:
##   DialogueManager.show_dialogue_balloon_scene("res://dialogue/ui_tour_balloon.tscn", resource, "start")


## The action that advances the dialogue.
@export var next_action: StringName = &"ui_accept"

## The action that skips typing (only matters if you turn the typewriter on).
@export var skip_action: StringName = &"ui_cancel"

## Block all other input while the tour is showing.
@export var will_block_other_input: bool = true

@export_group("Tour")
## The tag that says which part of the interface a line is about. Its value is a node name.
@export var target_tag: String = "target"
## The group your interface nodes belong to. A tag value is matched against the node names in it.
@export var target_group: StringName = &"tutorial_target"
## Callout title for lines that have no speaker.
@export var default_title: String = "Tip"
## The hint at the bottom of the callout while waiting for the player. Put keys in capitals between < and >.
@export var continue_hint: String = "Press <ENTER> to continue"
## Key cap background colour, used for every key in the text and the hint.
@export var key_background: Color = Color(0.18, 0.071, 0.141)
## Key cap text colour.
@export var key_text: Color = Color(0.996, 0.682, 0.204)
## Extra space around the lit-up part of the interface, in pixels.
@export var spotlight_padding: float = 4.0

@export_group("Step pips")
## Style of a pip for a step that has been reached.
@export var pip_on: StyleBox
## Style of a pip for a step that is still to come.
@export var pip_off: StyleBox

@export_group("Animation")
## Seconds the pop-in (and the dimming) takes.
@export var pop_in_time: float = 0.18
## Seconds the pop-out takes.
@export var pop_out_time: float = 0.12
## How small the callout starts (pop-in) and ends (pop-out).
@export_range(0.1, 1.0) var pop_scale: float = 0.85
## Seconds the lit-up area takes to move from one part of the interface to the next.
@export var spotlight_time: float = 0.22
## Seconds between each blink of the frame around the lit-up area.
@export var blink_time: float = 0.4


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

## See if we are running a long mutation and should hide the tour
var will_hide_balloon: bool = false

## True while the tour is on screen (or animating onto it)
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

## A cooldown timer for delaying the tour hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The step pips in the callout header
var pips: Array[Control] = []

var _step: int = 0
var _seen_lines: Dictionary = {}
var _shown_spot: Rect2 = Rect2()
var _present_id: int = 0
var _callout_tween: Tween
var _spot_tween: Tween
var _blink_tween: Tween
var _dim_tween: Tween
var _arrow_tween: Tween
var _key_regex: RegEx = RegEx.new()
var _key_cap: String = ""

## Full-screen control that catches clicks and the "next" action
@onready var balloon: Control = %Balloon
## The four dark bands around the lit-up area
@onready var dim: Control = %Dim
@onready var dim_top: Control = %DimTop
@onready var dim_bottom: Control = %DimBottom
@onready var dim_left: Control = %DimLeft
@onready var dim_right: Control = %DimRight
## The flashing frame around the lit-up area
@onready var highlight_group: Control = %HighlightGroup
@onready var frame_outer: Control = %FrameOuter
@onready var frame_inner: Control = %FrameInner
## The speech box (title, text, hint, choices). This is what pops in and out.
@onready var callout: Control = %Callout
@onready var pointer_up: Node2D = %PointerUp
@onready var pointer_down: Node2D = %PointerDown
@onready var title_label: Label = %TitleLabel
@onready var pips_row: Control = %PipsRow
## The pip that gets copied once for every step
@onready var pip_template: Control = %PipTemplate
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var footer: Control = %Footer
@onready var hint_label: RichTextLabel = %HintLabel
## The little arrow that hops when the player can press next
@onready var continue_arrow: Polygon2D = %ContinueArrow
@onready var responses_panel: Control = %ResponsesPanel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu


func _ready() -> void:
	dim.modulate.a = 0.0
	highlight_group.hide()
	callout.hide()
	pip_template.hide()
	pips_row.hide()
	pointer_down.hide()
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


func _unhandled_input(_event: InputEvent) -> void:
	# Only the tour is allowed to handle input while it's showing
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


## Apply any changes to the tour given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	# Seeing a line again means the tour looped (like "Show me again"), so count from 1 again
	if _seen_lines.has(dialogue_line.id):
		_step = 0
		_seen_lines.clear()
	_seen_lines[dialogue_line.id] = true
	_step += 1

	# Title and step pips
	if dialogue_line.character.is_empty():
		title_label.text = default_title
	else:
		title_label.text = tr(dialogue_line.character, "dialogue")
	_update_pips()

	# Light up whatever this line is about and put the callout next to it
	_open()
	var target: Rect2 = _find_target_rect(dialogue_line.get_tag_value(target_tag))
	_move_spotlight(target)
	_present_callout(target)

	# Text (with <KEY> turned into key caps) and responses
	dialogue_line.text = _decorate_keys(dialogue_line.text)
	dialogue_label.dialogue_line = dialogue_line

	footer.visible = dialogue_line.responses.is_empty()
	responses_panel.hide()
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses
	if dialogue_line.responses.size() > 0:
		responses_panel.show()
		responses_menu.show()

	will_hide_balloon = false

	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
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


func _screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size


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


#region Targets


## Where on screen is the interface node with this name? An empty Rect2 if there isn't one.
func _find_target_rect(target_name: String) -> Rect2:
	if target_name.is_empty():
		return Rect2()

	for node in get_tree().get_nodes_in_group(target_group):
		if String(node.name).to_lower() != target_name.to_lower():
			continue
		if node is CanvasItem and not node.is_visible_in_tree():
			continue
		if node is Control:
			return node.get_global_rect()
		if node is Sprite2D:
			return node.get_global_transform() * node.get_rect()
	return Rect2()


## Slide the lit-up area to a new target (or back to the middle of the screen if there is none)
func _move_spotlight(target: Rect2) -> void:
	var has_target: bool = target.has_area()
	var end_rect: Rect2 = target.grow(spotlight_padding) if has_target else Rect2(_screen_size() * 0.5, Vector2.ZERO)
	var start_rect: Rect2 = _shown_spot
	highlight_group.visible = has_target

	if _spot_tween and _spot_tween.is_valid():
		_spot_tween.kill()
	_spot_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spot_tween.tween_method(
		func(t: float): _apply_spot(Rect2(start_rect.position.lerp(end_rect.position, t), start_rect.size.lerp(end_rect.size, t))),
		0.0, 1.0, spotlight_time)


## Put the four dark bands and the flashing frame around a rectangle
func _apply_spot(rect: Rect2) -> void:
	_shown_spot = rect
	var screen: Vector2 = _screen_size()
	var top_left: Vector2 = rect.position.round()
	var bottom_right: Vector2 = rect.end.round()
	var height: float = maxf(bottom_right.y - top_left.y, 0.0)

	dim_top.position = Vector2.ZERO
	dim_top.size = Vector2(screen.x, maxf(top_left.y, 0.0))
	dim_bottom.position = Vector2(0.0, bottom_right.y)
	dim_bottom.size = Vector2(screen.x, maxf(screen.y - bottom_right.y, 0.0))
	dim_left.position = Vector2(0.0, top_left.y)
	dim_left.size = Vector2(maxf(top_left.x, 0.0), height)
	dim_right.position = Vector2(bottom_right.x, top_left.y)
	dim_right.size = Vector2(maxf(screen.x - bottom_right.x, 0.0), height)

	frame_inner.position = top_left
	frame_inner.size = bottom_right - top_left
	frame_outer.position = top_left - Vector2(2.0, 2.0)
	frame_outer.size = frame_inner.size + Vector2(4.0, 4.0)


## Measure the callout once its text has settled, then pop it up beside the target
func _present_callout(target: Rect2) -> void:
	_present_id += 1
	var my_id: int = _present_id
	if _callout_tween and _callout_tween.is_valid():
		_callout_tween.kill()

	callout.modulate.a = 0.0
	callout.show()

	# A control only ever grows to fit its content, so let the new content size it,
	# shrink it back to its minimum, then give the text a couple of frames to re-wrap.
	await get_tree().process_frame
	callout.size = Vector2.ZERO
	await get_tree().process_frame
	await get_tree().process_frame
	if my_id != _present_id or not is_open:
		return

	_place_callout(target)
	callout.pivot_offset = callout.size * 0.5
	callout.scale = Vector2.ONE * pop_scale
	_callout_tween = create_tween().set_parallel(true)
	_callout_tween.tween_property(callout, "scale", Vector2.ONE, pop_in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_callout_tween.tween_property(callout, "modulate:a", 1.0, pop_in_time * 0.6)


## Below the target if it fits, otherwise above it; in the middle of the screen with no target.
func _place_callout(target: Rect2) -> void:
	var screen: Vector2 = _screen_size()
	var box: Vector2 = callout.size
	var margin: float = 8.0
	var gap: float = 14.0

	if not target.has_area():
		callout.position = ((screen - box) * 0.5).round()
		pointer_up.hide()
		pointer_down.hide()
		return

	var lit: Rect2 = target.grow(spotlight_padding + 2.0)
	var below_y: float = lit.end.y + gap
	var above_y: float = lit.position.y - gap - box.y
	var fits_below: bool = below_y + box.y <= screen.y - margin
	var fits_above: bool = above_y >= margin
	var show_below: bool = fits_below or not fits_above

	var x: float = clampf(lit.get_center().x - box.x * 0.5, margin, maxf(screen.x - margin - box.x, margin))
	var y: float = below_y if show_below else above_y
	callout.position = Vector2(x, y).round()

	# The pointer sits on the edge facing the target, as close to its middle as the corners allow
	var pointer_x: float = clampf(lit.get_center().x - x, 16.0, maxf(box.x - 16.0, 16.0))
	pointer_up.visible = show_below
	pointer_up.position = Vector2(pointer_x, 0.0).round()
	pointer_down.visible = not show_below
	pointer_down.position = Vector2(pointer_x, box.y).round()


#endregion


#region Animation


## Dim the screen and start the frame flashing
func _open() -> void:
	if is_open:
		return
	is_open = true
	_apply_spot(Rect2(_screen_size() * 0.5, Vector2.ZERO))

	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = create_tween()
	_dim_tween.tween_property(dim, "modulate:a", 1.0, pop_in_time)

	# A two-frame blink (instead of a smooth fade) keeps it looking like pixel art
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	highlight_group.modulate.a = 1.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func(): highlight_group.modulate.a = 0.35)
	_blink_tween.tween_interval(blink_time)
	_blink_tween.tween_callback(func(): highlight_group.modulate.a = 1.0)
	_blink_tween.tween_interval(blink_time)


## Show or hide the "press to continue" arrow
func _set_continue_arrow(is_shown: bool) -> void:
	if _arrow_tween and _arrow_tween.is_valid():
		_arrow_tween.kill()
	continue_arrow.visible = is_shown
	continue_arrow.position.y = 0.0
	if not is_shown:
		return

	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_callback(func(): continue_arrow.position.y = 3.0)
	_arrow_tween.tween_interval(0.4)
	_arrow_tween.tween_callback(func(): continue_arrow.position.y = 0.0)
	_arrow_tween.tween_interval(0.4)


## Shrink the callout away, lift the dimming and hide the frame
func _pop_out() -> void:
	if not is_open:
		return
	is_open = false
	_present_id += 1
	for tween in [_callout_tween, _spot_tween, _blink_tween, _dim_tween]:
		if tween and tween.is_valid():
			tween.kill()

	callout.pivot_offset = callout.size * 0.5
	_callout_tween = create_tween().set_parallel(true)
	_callout_tween.tween_property(callout, "scale", Vector2.ONE * pop_scale, pop_out_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_callout_tween.tween_property(callout, "modulate:a", 0.0, pop_out_time)
	_callout_tween.tween_property(dim, "modulate:a", 0.0, pop_out_time)
	_callout_tween.tween_property(highlight_group, "modulate:a", 0.0, pop_out_time)
	await _callout_tween.finished

	if not is_open:
		callout.hide()
		highlight_group.hide()


## The tour is over: pop out, then remove the balloon
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
