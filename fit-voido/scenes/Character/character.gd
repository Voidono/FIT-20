extends CharacterBody2D
## Top-down player controller for Godot 4.
## Move with WASD, a gamepad's left stick, or the D-pad.
##
## Scene setup: put this script on a CharacterBody2D that has an AnimatedSprite2D
## child (named "AnimatedSprite2D") with four animations:
##   walk_down, walk_up, walk_left, walk_right

@export var speed: float = 200.0
## Frame of the walk animation to show while standing still.
@export var idle_frame: int = 0
## Shared action used to speak with the closest DialogueNPC. Defaults to E.
@export var interact_action: StringName = &"interact"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing := "Down"
var can_move := true
var _nearby_dialogue_npcs: Array[DialogueNPC] = []


func _ready() -> void:
	add_to_group(&"player")
	motion_mode = MOTION_MODE_FLOATING  # top-down: no floor, ceiling or gravity logic
	_ensure_input_actions()
	_update_animation(false)


func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_update_animation(false)
		return
	# Length is capped at 1 and sticks get a circular deadzone, so keyboard and
	# joystick feel consistent and diagonals aren't faster.
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = dir * speed
	move_and_slide()

	var is_moving := dir != Vector2.ZERO
	if is_moving:
		_update_facing(dir)
	_update_animation(is_moving)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_action):
		var npc := _closest_dialogue_npc()
		if npc:
			get_viewport().set_input_as_handled()
			npc.talk()


## Called automatically by DialogueNPC when this player enters or leaves its range.
func register_dialogue_npc(npc: DialogueNPC) -> void:
	if npc not in _nearby_dialogue_npcs:
		_nearby_dialogue_npcs.append(npc)


func unregister_dialogue_npc(npc: DialogueNPC) -> void:
	_nearby_dialogue_npcs.erase(npc)


## Used by DialogueNPC while its balloon is open.
func set_can_move(value: bool) -> void:
	can_move = value
	if not can_move:
		velocity = Vector2.ZERO


func _closest_dialogue_npc() -> DialogueNPC:
	_nearby_dialogue_npcs = _nearby_dialogue_npcs.filter(is_instance_valid)
	var closest: DialogueNPC
	var closest_distance := INF
	for npc in _nearby_dialogue_npcs:
		if not npc.can_talk():
			continue
		var distance := global_position.distance_squared_to(npc.global_position)
		if distance < closest_distance:
			closest = npc
			closest_distance = distance
	return closest


func _update_facing(dir: Vector2) -> void:
	# The dominant axis wins. On an exact diagonal (keyboard W+D, etc.) keep the
	# current facing so the sprite doesn't flip back and forth.
	if absf(dir.x) > absf(dir.y):
		_facing = "Right" if dir.x > 0.0 else "Left"
	elif absf(dir.y) > absf(dir.x):
		_facing = "Down" if dir.y > 0.0 else "Up"


func _update_animation(is_moving: bool) -> void:
	var anim_name := _facing
	if is_moving:
		if _sprite.animation != anim_name or not _sprite.is_playing():
			_sprite.play(anim_name)
	else:
		# Standing still: freeze on one frame of the current direction's walk cycle.
		_sprite.animation = anim_name
		_sprite.stop()
		_sprite.frame = idle_frame


## Registers WASD + left stick + D-pad if the actions don't exist yet.
## If you define move_left/right/up/down in Project Settings > Input Map,
## those are used instead and this does nothing.
func _ensure_input_actions() -> void:
	_add_action("move_left", KEY_A, JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT)
	_add_action("move_right", KEY_D, JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT)
	_add_action("move_up", KEY_W, JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP)
	_add_action("move_down", KEY_S, JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN)
	_add_interact_action()


func _add_interact_action() -> void:
	if InputMap.has_action(interact_action):
		return
	InputMap.add_action(interact_action)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_E
	InputMap.action_add_event(interact_action, key_event)


func _add_action(action: StringName, key: Key, axis: JoyAxis, axis_dir: float, dpad: JoyButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)

	var key_event := InputEventKey.new()
	key_event.physical_keycode = key  # physical position, so WASD works on any layout

	var stick_event := InputEventJoypadMotion.new()
	stick_event.axis = axis
	stick_event.axis_value = axis_dir

	var dpad_event := InputEventJoypadButton.new()
	dpad_event.button_index = dpad

	for event in [key_event, stick_event, dpad_event]:
		event.device = -1  # any device, same as the Input Map editor's default
		InputMap.action_add_event(action, event)
