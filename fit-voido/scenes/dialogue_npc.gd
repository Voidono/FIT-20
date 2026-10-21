class_name DialogueNPC
extends Area2D
## A talkable NPC. When the player stands close, a little key prompt appears above
## the NPC. Pressing the interact action starts a conversation in one of the Ember
## balloons (story, quiz, tutorial card or UI tour), freezes the player while it
## runs, and brings the prompt back afterwards.
##
## Setup: put your player in the player group, give this NPC a dialogue file and a
## cue, and pick a balloon in the Inspector. To give each NPC its own look, make a
## New Inherited Scene from dialogue_npc.tscn and swap the Visual node for your sprite.
##
## The balloon scenes are expected in res://dialogue/ (see BALLOON_SCENES).

## The conversation has started and the player is frozen
signal interaction_started
## The conversation is over and the player is free again
signal interaction_finished

enum Balloon { STORY, QUIZ, TUTORIAL, UI_TOUR }

const BALLOON_SCENES: Dictionary = {
	Balloon.STORY: "res://dialogue/pixel_balloon.tscn",
	Balloon.QUIZ: "res://dialogue/quiz_balloon.tscn",
	Balloon.TUTORIAL: "res://dialogue/tutorial_balloon.tscn",
	Balloon.UI_TOUR: "res://dialogue/ui_tour_balloon.tscn",
}

## True while any NPC is mid-conversation, so two NPCs standing close together can't both start one
static var is_any_talking: bool = false

@export_group("Dialogue")
## The .dialogue file this NPC speaks from.
@export var dialogue: DialogueResource
## The cue to start from (the word after the ~ in the dialogue file).
@export var cue: String = "start"
## Optional cue to use after the first conversation, so the NPC says something different the second time.
@export var repeat_cue: String = ""
## Which balloon the conversation uses.
@export var balloon: Balloon = Balloon.STORY
## Optional: a balloon scene of your own. It overrides the choice above.
@export var custom_balloon: PackedScene

@export_group("Interaction")
## The input action that starts the conversation. If it doesn't exist yet it is created with the E key.
@export var interact_action: StringName = &"interact"
## Only bodies in this group can talk to the NPC.
@export var player_group: StringName = &"player"
## Stop the player moving while the conversation runs.
@export var freeze_player: bool = true
## The word next to the key in the prompt.
@export var prompt_text: String = "Talk"

var _player: Node
var _in_range: bool = false
var _is_talking: bool = false
var _has_talked: bool = false
var _prompt_rest_y: float = 0.0
var _hop_tween: Tween

## The key prompt above the NPC
@onready var prompt: Node2D = %Prompt
@onready var prompt_box: Control = %PromptBox
@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel


func _ready() -> void:
	_ensure_interact_action()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	key_label.text = _key_name()
	action_label.text = prompt_text
	_prompt_rest_y = prompt.position.y
	_setup_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _in_range and not _is_talking and not is_any_talking and event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		talk()


## Start the conversation (the player pressing interact calls this, but you can too)
func talk() -> void:
	if _is_talking or is_any_talking:
		return
	if dialogue == null:
		push_warning("%s has no dialogue file assigned." % name)
		return

	_is_talking = true
	is_any_talking = true
	_update_prompt()
	if freeze_player:
		_set_player_frozen(true)
	interaction_started.emit()

	var start_cue: String = repeat_cue if _has_talked and not repeat_cue.is_empty() else cue
	DialogueManager.show_dialogue_balloon_scene(_balloon_scene(), dialogue, start_cue)
	await DialogueManager.dialogue_ended

	_has_talked = true
	_is_talking = false
	is_any_talking = false
	if freeze_player:
		_set_player_frozen(false)
	_update_prompt()
	interaction_finished.emit()


func _balloon_scene() -> Variant:
	if custom_balloon:
		return custom_balloon
	return BALLOON_SCENES[balloon]


## Make the interact action exist, so the NPC works before you set up your own controls
func _ensure_interact_action() -> void:
	if InputMap.has_action(interact_action):
		return
	InputMap.add_action(interact_action)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	InputMap.action_add_event(interact_action, key)


## The name of the key bound to the interact action, for the prompt
func _key_name() -> String:
	for event in InputMap.action_get_events(interact_action):
		if event is InputEventKey:
			if event.physical_keycode != KEY_NONE:
				return event.as_text_physical_keycode().to_upper()
			return event.as_text_keycode().to_upper()
	return "E"


## Centre the prompt above the NPC once its size is known (it is invisible while that happens)
func _setup_prompt() -> void:
	prompt.modulate.a = 0.0
	prompt.show()
	await get_tree().process_frame
	prompt_box.position = Vector2(-prompt_box.size.x * 0.5, -prompt_box.size.y).round()
	prompt.hide()
	prompt.modulate.a = 1.0
	_update_prompt()


## Show the prompt (with a little two-frame hop) while the player is close and nobody is talking
func _update_prompt() -> void:
	if _hop_tween and _hop_tween.is_valid():
		_hop_tween.kill()
	var should_show: bool = _in_range and not _is_talking
	prompt.visible = should_show
	prompt.position.y = _prompt_rest_y
	if not should_show:
		return

	_hop_tween = create_tween().set_loops()
	_hop_tween.tween_callback(func(): prompt.position.y = _prompt_rest_y - 2.0)
	_hop_tween.tween_interval(0.4)
	_hop_tween.tween_callback(func(): prompt.position.y = _prompt_rest_y)
	_hop_tween.tween_interval(0.4)


## Stop or release the player. If your player has set_can_move() or a can_move variable,
## that is used. Otherwise its processing is switched off and it stops sliding.
func _set_player_frozen(frozen: bool) -> void:
	if not is_instance_valid(_player):
		return

	if _player.has_method(&"set_can_move"):
		_player.set_can_move(not frozen)
	elif "can_move" in _player:
		_player.can_move = not frozen
	else:
		_player.set_process(not frozen)
		_player.set_physics_process(not frozen)
		_player.set_process_input(not frozen)
		_player.set_process_unhandled_input(not frozen)

	if frozen and "velocity" in _player:
		_player.velocity = Vector2.ZERO


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(player_group):
		return
	_player = body
	_in_range = true
	_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body != _player or _is_talking:
		return
	_player = null
	_in_range = false
	_update_prompt()
