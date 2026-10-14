extends CanvasLayer
## A pixel-art dialogue balloon for Nathan Hoad's Dialogue Manager.
##
## A fixed box at the bottom of the screen with a name tag, a portrait,
## response choices and pop-in / pop-out animations. The flow follows the
## example balloon that ships with Dialogue Manager.
##
## Show it with:
##   DialogueManager.show_dialogue_balloon_scene("res://dialogue/pixel_balloon.tscn", resource, "start")


## The action that advances the dialogue.
@export var next_action: StringName = &"ui_accept"

## The action that skips typing (only matters if you turn the typewriter on).
@export var skip_action: StringName = &"ui_cancel"

## Block all other input while the balloon is showing.
@export var will_block_other_input: bool = true

@export_group("Portraits")
## Folder that holds portraits named after the speaker, e.g. nathan.png.
## A line tagged #mood=happy will use nathan_happy.png if that file exists.
@export_dir var portrait_folder: String = "res://portraits"
## The tag that picks the expression.
@export var mood_tag: String = "mood"

@export_group("Layout")
## The text area always reserves this many lines so the box doesn't change height from line to line.
@export_range(1, 8) var min_text_lines: int = 3

@export_group("Animation")
## Seconds the pop-in takes.
@export var pop_in_time: float = 0.18
## Seconds the pop-out takes.
@export var pop_out_time: float = 0.12
## How small the box starts (pop-in) and ends (pop-out).
@export_range(0.1, 1.0) var pop_scale: float = 0.85


## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

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

var _tween: Tween
var _portrait_cache: Dictionary = {}

## Full-screen control that catches clicks and the "next" action
@onready var balloon: Control = %Balloon
## Everything you see (name tag, box, responses). This is what pops in and out.
@onready var dock: Control = %Dock
@onready var name_tag: Control = %NameTag
@onready var character_label: Label = %CharacterLabel
@onready var portrait: TextureRect = %Portrait
@onready var text_column: Control = %TextColumn
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_panel: Control = %ResponsesPanel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu


func _ready() -> void:
	dock.hide()

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

	# Name tag
	name_tag.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	# Portrait (looked up by the untranslated character name)
	portrait.texture = _find_portrait(dialogue_line.character, dialogue_line.get_tag_value(mood_tag))
	portrait.visible = portrait.texture != null

	# Text and responses
	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_panel.hide()
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
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


## Keep the text area the same height for every line (min_text_lines tall).
func _reserve_text_height() -> void:
	var font: Font = dialogue_label.get_theme_font(&"normal_font")
	var font_size: int = dialogue_label.get_theme_font_size(&"normal_font_size")
	var line_height: float = font.get_height(font_size) + dialogue_label.get_theme_constant(&"line_separation")
	text_column.custom_minimum_size.y = ceilf(line_height * min_text_lines)


## Find a portrait for a speaker: portrait_folder/name_mood.png, then portrait_folder/name.png
func _find_portrait(character: String, mood: String) -> Texture2D:
	if character.is_empty() or portrait_folder.is_empty():
		return null

	var base: String = character.strip_edges().to_lower().replace(" ", "_")
	var file_names: Array[String] = [base]
	if not mood.is_empty():
		file_names.push_front("%s_%s" % [base, mood.to_lower()])

	for file_name in file_names:
		for extension in ["png", "webp"]:
			var path: String = "%s/%s.%s" % [portrait_folder.trim_suffix("/"), file_name, extension]
			if _portrait_cache.has(path):
				return _portrait_cache[path]
			if ResourceLoader.exists(path):
				var texture: Texture2D = load(path) as Texture2D
				if texture:
					_portrait_cache[path] = texture
					return texture
	return null


#region Animation


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


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
