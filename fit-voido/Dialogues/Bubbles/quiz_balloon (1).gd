extends CanvasLayer
## A pixel-art multiple-choice quiz balloon for Nathan Hoad's Dialogue Manager.
##
## The question sits in a dark box with an orange frame and the answers are
## orange tiles in a two-column grid with A / B / C / D badges. Pick one with
## the mouse, the arrow keys / D-pad and your "next" action. The flow follows
## the example balloon that ships with Dialogue Manager.
##
## Tag the right answer with "correct" in your dialogue (see correct_tag) or set
## locals.correct_answer to its number before the question, and the tiles turn
## green / red when the player answers. If no right answer is marked, the pick
## is simply confirmed and the dialogue moves on.
##
## Laid out for a fixed 640x360 canvas. To move or resize things, edit the Dock
## node and the answer template in the scene.
##
## Show it with:
##   DialogueManager.show_dialogue_balloon_scene("res://dialogue/quiz_balloon.tscn", resource, "start")


## The action that advances the dialogue and picks the highlighted answer.
@export var next_action: StringName = &"ui_accept"

## The action that skips typing (only matters if you turn the typewriter on).
@export var skip_action: StringName = &"ui_cancel"

## Block all other input while the balloon is showing.
@export var will_block_other_input: bool = true

@export_group("Quiz")
## An answer carrying this tag counts as the right one.
@export var correct_tag: String = "correct"
## Seconds the result stays on screen before the dialogue moves on.
@export var reveal_time: float = 1.2
## The question area always reserves this many lines so the box doesn't change height from question to question.
@export_range(1, 6) var min_text_lines: int = 2

@export_group("Answer tiles")
## Style of an answer tile at rest.
@export var tile_normal: StyleBox
## Style of the highlighted answer tile.
@export var tile_focus: StyleBox
## Style of the right answer once it is revealed.
@export var tile_correct: StyleBox
## Style of a wrong pick once it is revealed.
@export var tile_wrong: StyleBox
## Answer text colour on a tile at rest, highlighted or right.
@export var answer_color: Color = Color(0.18, 0.071, 0.141)
## Answer text colour on a wrong tile.
@export var wrong_text_color: Color = Color(1, 0.914, 0.722)

@export_group("Animation")
## Seconds the pop-in takes.
@export var pop_in_time: float = 0.18
## Seconds the pop-out takes.
@export var pop_out_time: float = 0.12
## How small the box starts (pop-in) and ends (pop-out).
@export_range(0.1, 1.0) var pop_scale: float = 0.85
## Seconds between one answer tile popping in and the next.
@export var answer_stagger: float = 0.06


## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player (this also shows / hides the continue arrow)
var is_waiting_for_input: bool = false:
	set(value):
		is_waiting_for_input = value
		if is_node_ready():
			_set_continue_arrow(value)

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## True while the box is on screen (or animating onto it)
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

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The answer tiles for the current question
var tiles: Array[Control] = []

## True once the player has answered, so nothing else can be picked
var is_locked: bool = false

var _tween: Tween
var _arrow_tween: Tween
var _responses: Array = []
var _chosen: int = -1
var _revealed: Dictionary = {}

## Full-screen control that catches clicks and the "next" action
@onready var balloon: Control = %Balloon
## Everything you see (speaker tab, question, answers). This is what pops in and out.
@onready var dock: Control = %Dock
@onready var name_tag: Control = %NameTag
@onready var character_label: Label = %CharacterLabel
@onready var text_column: Control = %TextColumn
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var answers_panel: Control = %AnswersPanel
@onready var answers_grid: GridContainer = %AnswersGrid
## The tile that gets copied once for every answer
@onready var answer_template: Control = %AnswerTemplate
## The little arrow that hops when the player can press next
@onready var continue_arrow: Polygon2D = %ContinueArrow


func _ready() -> void:
	dock.hide()
	answer_template.hide()
	_set_continue_arrow(false)

	var manager = _get_dialogue_manager()
	if is_instance_valid(manager):
		manager.mutated.connect(_on_mutated)

	balloon.gui_input.connect(_on_balloon_gui_input)

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	_reserve_text_height()


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
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


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	# Speaker tab
	name_tag.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	# Question text
	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	# The answer tiles are built now but only appear once the question has been read
	_build_answers(dialogue_line.responses)

	# Show our balloon
	will_hide_balloon = false
	_pop_in()

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for the player
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		_show_answers()
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


## Keep the question area the same height for every question (min_text_lines tall).
func _reserve_text_height() -> void:
	var font: Font = dialogue_label.get_theme_font(&"normal_font")
	var font_size: int = dialogue_label.get_theme_font_size(&"normal_font_size")
	var line_height: float = font.get_height(font_size) + dialogue_label.get_theme_constant(&"line_separation")
	text_column.custom_minimum_size.y = ceilf(line_height * min_text_lines)


#region Answers


## Make one tile per answer (they stay hidden until _show_answers)
func _build_answers(responses: Array) -> void:
	for tile in tiles:
		answers_grid.remove_child(tile)
		tile.queue_free()
	tiles.clear()
	answers_panel.hide()

	_responses = responses
	_chosen = -1
	_revealed.clear()
	is_locked = false

	for i in responses.size():
		var response: DialogueResponse = responses[i]
		var tile: Control = answer_template.duplicate()
		tile.unique_name_in_owner = false
		tile.name = "Answer%d" % (i + 1)
		tile.get_node("Row/Badge/Letter").text = char(65 + i)
		tile.get_node("Row/Answer").text = response.text
		tile.focus_mode = Control.FOCUS_ALL
		tile.gui_input.connect(_on_tile_gui_input.bind(i))
		tile.mouse_entered.connect(_on_tile_mouse_entered.bind(i))
		tile.focus_entered.connect(_refresh_tile.bind(i))
		tile.focus_exited.connect(_refresh_tile.bind(i))
		answers_grid.add_child(tile)
		tile.show()
		tiles.append(tile)
		_refresh_tile(i)


## Fade the tiles in one after another, then highlight the first answer
func _show_answers() -> void:
	if tiles.is_empty():
		return

	for i in tiles.size():
		tiles[i].modulate.a = 0.0
		tiles[i].scale = Vector2.ONE * 0.9
	answers_panel.show()

	# Wait a frame so the grid has placed the tiles, then pop each one from its centre
	await get_tree().process_frame
	if tiles.is_empty():
		return

	for i in tiles.size():
		var tile: Control = tiles[i]
		var alpha: float = 1.0 if _responses[i].is_allowed else 0.45
		tile.pivot_offset = tile.size * 0.5
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(tile, "modulate:a", alpha, 0.12).set_delay(i * answer_stagger)
		tween.tween_property(tile, "scale", Vector2.ONE, 0.16).set_delay(i * answer_stagger).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var first: int = _first_allowed()
	if first >= 0:
		tiles[first].grab_focus()


func _first_allowed() -> int:
	for i in _responses.size():
		if _responses[i].is_allowed:
			return i
	return -1


## Which answer is the right one? -1 if the dialogue doesn't say.
func _find_correct_index() -> int:
	for i in _responses.size():
		var tags = _responses[i].get("tags")
		if tags != null and correct_tag in tags:
			return i

	# Or the dialogue can say it with: set locals.correct_answer = 2
	var number: int = int(locals.get("correct_answer", 0))
	if number >= 1 and number <= _responses.size():
		return number - 1
	return -1


## Give a tile the look of its current state (at rest, highlighted, right or wrong)
func _refresh_tile(index: int) -> void:
	if index >= tiles.size():
		return

	var tile: Control = tiles[index]
	var style: StyleBox = tile_normal
	var is_wrong: bool = false

	match _revealed.get(index, ""):
		"correct":
			style = tile_correct
		"wrong":
			style = tile_wrong
			is_wrong = true
		_:
			if index == _chosen or (tile.has_focus() and not is_locked):
				style = tile_focus

	if style:
		tile.add_theme_stylebox_override(&"panel", style)
	var answer: Label = tile.get_node("Row/Answer")
	answer.add_theme_color_override(&"font_color", wrong_text_color if is_wrong else answer_color)


func _refresh_all() -> void:
	for i in tiles.size():
		_refresh_tile(i)


## The player picked an answer: show whether it was right, then move on
func _choose(index: int) -> void:
	if is_locked or index >= _responses.size():
		return
	var response: DialogueResponse = _responses[index]
	if not response.is_allowed:
		return

	is_locked = true
	_chosen = index
	var correct_index: int = _find_correct_index()

	if correct_index < 0:
		# No right answer marked, so just confirm the pick
		_refresh_all()
		_pop_tile(tiles[index])
		await get_tree().create_timer(0.3).timeout
	else:
		_revealed[index] = "correct" if index == correct_index else "wrong"
		_refresh_all()
		if index == correct_index:
			_pop_tile(tiles[index])
		else:
			_blink_tile(tiles[index])
			# Show the right one a moment later
			await get_tree().create_timer(0.45).timeout
			_revealed[correct_index] = "correct"
			_refresh_all()
			_pop_tile(tiles[correct_index])
		await get_tree().create_timer(reveal_time).timeout

	next(response.next_id)


## A little bounce for the tile that is right (or just picked)
func _pop_tile(tile: Control) -> void:
	tile.pivot_offset = tile.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(tile, "scale", Vector2.ONE * 1.06, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "scale", Vector2.ONE, 0.12)


## Three quick flashes for a wrong pick
func _blink_tile(tile: Control) -> void:
	var tween: Tween = create_tween()
	for i in 3:
		tween.tween_property(tile, "modulate:a", 0.35, 0.06)
		tween.tween_property(tile, "modulate:a", 1.0, 0.06)


#endregion


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


## Pop the box up from the bottom centre of the screen
func _pop_in() -> void:
	if is_open:
		return
	is_open = true
	_kill_tween()

	if not dock.visible:
		dock.modulate.a = 0.0
		dock.scale = Vector2.ONE * pop_scale
		dock.show()
		# Give the containers a frame to work out the box size so we can pivot from its bottom centre
		await get_tree().process_frame
		if not is_open:
			return

	dock.pivot_offset = Vector2(dock.size.x * 0.5, dock.size.y)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(dock, "scale", Vector2.ONE, pop_in_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(dock, "modulate:a", 1.0, pop_in_time * 0.6)


## Shrink the box back down and hide it
func _pop_out() -> void:
	if not is_open:
		return
	is_open = false
	_kill_tween()

	dock.pivot_offset = Vector2(dock.size.x * 0.5, dock.size.y)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(dock, "scale", Vector2.ONE * pop_scale, pop_out_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(dock, "modulate:a", 0.0, pop_out_time)
	await _tween.finished

	if not is_open:
		dock.hide()


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

	# When there are no answers the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_tile_mouse_entered(index: int) -> void:
	if not is_locked and index < _responses.size() and _responses[index].is_allowed:
		tiles[index].grab_focus()


func _on_tile_gui_input(event: InputEvent, index: int) -> void:
	if is_locked:
		return
	var was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
	if was_clicked or event.is_action_pressed(next_action):
		get_viewport().set_input_as_handled()
		_choose(index)


#endregion
