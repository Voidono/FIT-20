@tool
class_name DialogueNPC
extends Area2D
## Reusable talkable-NPC template. Drag a texture, .dialogue resource, and balloon
## scene into the Content fields in the Inspector. Move Sprite and PromptAnchor
## in the editor to lay out each NPC without editing this template.

signal interaction_started
signal interaction_finished

static var is_any_talking: bool = false

@export_group("Content")
## Drag an image texture here; it is shown by the Sprite child.
@export var npc_sprite: Texture2D:
	set(value):
		npc_sprite = value
		_apply_sprite()
## Drag the .dialogue file this NPC should speak from here.
@export var dialogue: DialogueResource
@export var cue: String = "start"
@export var repeat_cue: String = ""
## Drag any compatible Dialogue Manager balloon .tscn here.
@export var dialogue_balloon: PackedScene = preload("res://Dialogues/Bubbles/pixel_balloon.tscn")

@export_group("Interaction")
@export var player_group: StringName = &"player"
@export var freeze_player: bool = true
@export var prompt_text: String = "Talk"

var _player: Node
var _in_range := false
var _is_talking := false
var _has_talked := false
var _prompt_rest_y := 0.0
var _hop_tween: Tween

@onready var sprite: Sprite2D = %Sprite
@onready var prompt: Node2D = %PromptAnchor
@onready var prompt_box: Control = %PromptBox
@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel


func _ready() -> void:
	_apply_sprite()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	key_label.text = _key_name()
	action_label.text = prompt_text
	_prompt_rest_y = prompt.position.y
	_setup_prompt()


## Returns true when the player can start this NPC's dialogue.
func can_talk() -> bool:
	return dialogue != null and dialogue_balloon != null and not _is_talking and not is_any_talking


## Starts the conversation; Character calls this after the player presses interact.
func talk() -> void:
	if not can_talk():
		return
	if dialogue == null:
		push_warning("%s has no Dialogue resource assigned." % name)
		return
	if dialogue_balloon == null:
		push_warning("%s has no Dialogue Balloon scene assigned." % name)
		return
	_is_talking = true
	is_any_talking = true
	_update_prompt()
	if freeze_player:
		_set_player_frozen(true)
	interaction_started.emit()
	var start_cue := repeat_cue if _has_talked and not repeat_cue.is_empty() else cue
	DialogueManager.show_dialogue_balloon_scene(dialogue_balloon, dialogue, start_cue)
	await DialogueManager.dialogue_ended
	_has_talked = true
	_is_talking = false
	is_any_talking = false
	if freeze_player:
		_set_player_frozen(false)
	_update_prompt()
	interaction_finished.emit()


func _apply_sprite() -> void:
	if is_instance_valid(sprite):
		sprite.texture = npc_sprite


func _key_name() -> String:
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			if event.physical_keycode != KEY_NONE:
				return event.as_text_physical_keycode().to_upper()
			return event.as_text_keycode().to_upper()
	return "E"


func _setup_prompt() -> void:
	prompt.modulate.a = 0.0
	prompt.show()
	await get_tree().process_frame
	prompt_box.position = Vector2(-prompt_box.size.x * 0.5, -prompt_box.size.y).round()
	prompt.hide()
	prompt.modulate.a = 1.0
	_update_prompt()


func _update_prompt() -> void:
	if _hop_tween and _hop_tween.is_valid():
		_hop_tween.kill()
	var should_show := _in_range and not _is_talking
	prompt.visible = should_show
	prompt.position.y = _prompt_rest_y
	if not should_show:
		return
	_hop_tween = create_tween().set_loops()
	_hop_tween.tween_callback(func(): prompt.position.y = _prompt_rest_y - 2.0)
	_hop_tween.tween_interval(0.4)
	_hop_tween.tween_callback(func(): prompt.position.y = _prompt_rest_y)
	_hop_tween.tween_interval(0.4)


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
	if body.is_in_group(player_group):
		_player = body
		_in_range = true
		if body.has_method(&"register_dialogue_npc"):
			body.register_dialogue_npc(self)
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		if body.has_method(&"unregister_dialogue_npc"):
			body.unregister_dialogue_npc(self)
		_player = null
		_in_range = false
		_update_prompt()
