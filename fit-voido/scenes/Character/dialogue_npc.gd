@tool
class_name DialogueNPC
extends Area2D
## Reusable talkable & moving NPC template.
## Drag a texture, .dialogue resource, and balloon scene in the Inspector.
## NPCs can walk around (Wander or Patrol) and automatically pause and face
## the player during conversations.

signal interaction_started
signal interaction_finished
signal started_moving
signal stopped_moving
## Emitted when the dominant walking direction changes (Vector2.RIGHT / LEFT / UP / DOWN).
signal facing_changed(direction: Vector2)

enum Mode { STATIONARY, WANDER, PATROL }

static var is_any_talking: bool = false

@export_group("Content")
## Drag an image texture here; it is shown by the Sprite child when no animation skin is set.
@export var npc_sprite: Texture2D:
	set(value):
		npc_sprite = value
		_apply_sprite()
## Animation skin ID (e.g. "NPC_1", "NPC_2"). Leave empty to use the static npc_sprite instead.
## Frames must follow the pattern: res://assets/DrawAsset/NPC/<skin>_<dir>_<n>.png
## where <dir> is up/down/left/right and <n> is 1, 2, 3...
@export var npc_skin: String = "":
	set(value):
		npc_skin = value
		_apply_sprite()
## FPS for walking animations.
@export_range(1, 30, 1, "suffix:fps") var animation_fps: int = 8
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

@export_group("Name Tag")
## The name shown above the NPC when the player walks close. Leave empty to hide the tag entirely.
@export var npc_name: String = "":
	set(value):
		npc_name = value
		_apply_name_tag()
## Whether to show the name tag at all (useful for NPCs that should stay anonymous).
@export var show_name_tag: bool = true
## Background colour of the name tag panel.
@export var name_tag_bg_color: Color = Color(0.18, 0.071, 0.141, 0.85):
	set(value):
		name_tag_bg_color = value
		_apply_name_tag()
## Border colour of the name tag panel.
@export var name_tag_border_color: Color = Color(0.969, 0.463, 0.133, 1):
	set(value):
		name_tag_border_color = value
		_apply_name_tag()
## Text colour of the name label.
@export var name_tag_font_color: Color = Color(1, 0.914, 0.722, 1):
	set(value):
		name_tag_font_color = value
		_apply_name_tag()
## Vertical pixel offset of the tag above the NPC's default anchor position.
@export_range(-100, 100, 1, "suffix:px") var name_tag_offset_y: int = 0:
	set(value):
		name_tag_offset_y = value
		_apply_name_tag()

@export_group("Collision")
## Size of the physical body capsule that blocks the player (width × height in px).
@export var body_capsule_radius: float = 10.0:
	set(value):
		body_capsule_radius = value
		_apply_body_shape()
@export var body_capsule_height: float = 20.0:
	set(value):
		body_capsule_height = value
		_apply_body_shape()

@export_group("Minigame / Scene Transition")
## If set, this NPC can change scene to this target.
@export_file("*.tscn") var target_scene_path: String = ""
## If true, interacting with this NPC changes scene directly without showing dialogue.
@export var change_scene_directly: bool = false

@export_group("Movement Mode")
## STATIONARY: stays in place.
## WANDER: randomly walks around its starting location.
## PATROL: follows Marker2D children or patrol_points waypoints.
@export var mode: Mode = Mode.WANDER:
	set(value):
		mode = value
		queue_redraw()
		if Engine.is_editor_hint():
			if is_inside_tree():
				update_configuration_warnings()
		elif is_node_ready():
			_restart_movement()

@export_group("Movement")
@export_range(5.0, 300.0, 1.0, "suffix:px/s") var speed: float = 40.0
## How close counts as "arrived".
@export_range(1.0, 20.0, 0.5, "suffix:px") var arrive_distance: float = 4.0

@export_group("Wander")
## Random targets are picked within this distance of the NPC's starting position.
@export_range(8.0, 1000.0, 1.0, "suffix:px") var wander_radius: float = 100.0:
	set(value):
		wander_radius = value
		queue_redraw()

@export_group("Patrol")
## Off = loop through waypoints 1,2,3,1,2,3. On = 1,2,3,2,1,2,3...
@export var ping_pong: bool = false
## Optional manual waypoints (offsets from spawn position). If empty, Marker2D children are used.
@export var patrol_points: Array[Vector2] = []

@export_group("Waiting")
@export_range(0.0, 30.0, 0.1, "suffix:s") var min_wait: float = 1.5
@export_range(0.0, 30.0, 0.1, "suffix:s") var max_wait: float = 4.0

@export_group("Pathfinding")
## Off: walks in straight lines and skips targets that a wall blocks (uses Obstacle Mask).
## On: follows a baked NavigationRegion2D / TileMap navigation layer around obstacles.
@export var use_navigation: bool = false
## Navigation only: NPCs steer around each other (RVO avoidance).
@export var avoid_other_npcs: bool = false
## Straight-line mode only: physics layers that block the NPC (walls, water...).
## Leave the player and NPC layers off.
@export_flags_2d_physics var obstacle_mask: int = 1

@export_group("Movement Interaction")
@export var pause_while_talking: bool = true
@export var face_player_when_talking: bool = true

@export_group("Visuals")
## Flip the Sprite2D left/right depending on walking direction.
@export var flip_sprite: bool = true
@export var sprite_faces_right: bool = true
## Little hop while walking, so a single static texture still looks alive. 0 = off.
@export_range(0.0, 8.0, 0.5, "suffix:px") var walk_bob_height: float = 1.5
@export_range(0.05, 0.5, 0.01, "suffix:s") var walk_bob_time: float = 0.12

var _player: Node
var _in_range := false
var _is_talking := false
var _has_talked := false
var _prompt_rest_y := 0.0
var _hop_tween: Tween

var _home: Vector2
var _target: Vector2
var _is_moving := false
var _give_up_left := 0.0
var _patrol_waypoints: Array[Vector2] = []
var _patrol_index := -1
var _patrol_step := 1
var _bob_tween: Tween
var _sprite_rest_y := 0.0
var _facing := Vector2.ZERO
var _warned_no_nav := false
var _wait_timer: Timer
var _nav_agent: NavigationAgent2D

@onready var sprite: Sprite2D = %Sprite
@onready var anim_sprite: AnimatedSprite2D = %AnimSprite
@onready var prompt: Node2D = %PromptAnchor
@onready var prompt_box: Control = %PromptBox
@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel
@onready var name_tag_anchor: Node2D = %NameTagAnchor
@onready var name_panel: PanelContainer = %NamePanel
@onready var name_label: Label = %NameLabel

## Maps facing direction to animation name suffix.
const _DIR_ANIM := {
	Vector2.RIGHT: "right",
	Vector2.LEFT:  "left",
	Vector2.UP:    "up",
	Vector2.DOWN:  "down",
}
## The folder that holds NPC frame PNGs (relative to res://).
const _NPC_ASSET_DIR := "res://assets/DrawAsset/NPC/"
## How many walk frames exist per direction in the asset files.
const _FRAME_COUNT := 3

var _has_anim: bool = false
var _current_anim_dir: String = ""


func _ready() -> void:
	_apply_sprite()
	_apply_name_tag()
	_apply_body_shape()
	if Engine.is_editor_hint():
		return
	set_process(false)
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	key_label.text = _key_name()
	action_label.text = prompt_text
	_prompt_rest_y = prompt.position.y
	_setup_prompt()
	_setup_animation()
	_setup_movement()


func _setup_movement() -> void:
	_home = global_position
	if is_instance_valid(sprite):
		_sprite_rest_y = sprite.position.y

	_patrol_waypoints.clear()
	for child in get_children():
		if child is Marker2D:
			_patrol_waypoints.append((child as Marker2D).global_position)
	if _patrol_waypoints.is_empty() and not patrol_points.is_empty():
		for pt in patrol_points:
			_patrol_waypoints.append(_home + pt)

	_wait_timer = Timer.new()
	_wait_timer.one_shot = true
	_wait_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_wait_timer.timeout.connect(_on_wait_finished)
	add_child(_wait_timer)

	if use_navigation:
		_nav_agent = NavigationAgent2D.new()
		_nav_agent.path_desired_distance = arrive_distance
		_nav_agent.target_desired_distance = arrive_distance
		_nav_agent.max_speed = speed
		_nav_agent.avoidance_enabled = avoid_other_npcs
		_nav_agent.velocity_computed.connect(_apply_velocity)
		add_child(_nav_agent)

	_schedule_wait(true)


# --- Interaction / Dialogue ------------------------------------------------

## Returns true when the player can start this NPC's dialogue or interaction.
func can_talk() -> bool:
	if not target_scene_path.is_empty() and (change_scene_directly or dialogue == null):
		return not _is_talking and not is_any_talking
	return dialogue != null and dialogue_balloon != null and not _is_talking and not is_any_talking


## Starts the conversation or interaction; Character calls this after the player presses interact.
func talk() -> void:
	if not can_talk():
		return
	if not target_scene_path.is_empty() and (change_scene_directly or dialogue == null):
		_change_to_target_scene()
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
	if pause_while_talking:
		_set_movement_paused(true)
	if face_player_when_talking and is_instance_valid(_player):
		_face((_player as Node2D).global_position - global_position)
	# Ensure the NPC enters their idle stance in whatever direction they are facing
	_play_anim(Vector2.ZERO)
	interaction_started.emit()
	var start_cue := repeat_cue if _has_talked and not repeat_cue.is_empty() else cue
	DialogueManager.show_dialogue_balloon_scene(dialogue_balloon, dialogue, start_cue)
	await DialogueManager.dialogue_ended
	_has_talked = true
	_is_talking = false
	is_any_talking = false
	if freeze_player:
		_set_player_frozen(false)
	if pause_while_talking:
		_set_movement_paused(false)
	_update_prompt()
	interaction_finished.emit()


func _apply_sprite() -> void:
	# Resolve sprite node (may be called before @onready)
	if sprite == null and has_node("%Sprite"):
		sprite = %Sprite
	var anim: AnimatedSprite2D = null
	if has_node("%AnimSprite"):
		anim = %AnimSprite

	# In the editor show the static sprite so you can see NPC placement.
	# At runtime: use AnimSprite when a skin is configured, Sprite otherwise.
	if is_instance_valid(anim):
		anim.visible = npc_skin != "" and not Engine.is_editor_hint()
	if is_instance_valid(sprite):
		sprite.visible = npc_skin == "" or Engine.is_editor_hint()
		sprite.texture = npc_sprite


## Applies name tag text and colours; works both in-editor and at runtime.
func _apply_name_tag() -> void:
	var anchor: Node2D = null
	var panel: PanelContainer = null
	var label: Label = null
	if has_node("%NameTagAnchor"):
		anchor = %NameTagAnchor
	if has_node("%NamePanel"):
		panel = %NamePanel
	if has_node("%NameLabel"):
		label = %NameLabel
	if not is_instance_valid(anchor):
		return

	# Position offset (base -52 + export tweak)
	anchor.position.y = -52 + name_tag_offset_y

	# Update label text
	if is_instance_valid(label):
		label.text = npc_name
		label.add_theme_color_override("font_color", name_tag_font_color)

	# Update panel style colours
	if is_instance_valid(panel):
		var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style:
			style.bg_color = name_tag_bg_color
			style.border_color = name_tag_border_color
			panel.add_theme_stylebox_override("panel", style)

	# In editor: always show when npc_name is set so you can preview it
	if Engine.is_editor_hint():
		anchor.visible = show_name_tag and npc_name != ""


## Applies the exported capsule size to the StaticBody child shape.
func _apply_body_shape() -> void:
	if not has_node("Body/BodyShape"):
		return
	var shape_node := get_node("Body/BodyShape") as CollisionShape2D
	if not is_instance_valid(shape_node):
		return
	var cap := shape_node.shape as CapsuleShape2D
	if cap == null:
		cap = CapsuleShape2D.new()
		shape_node.shape = cap
	cap.radius = body_capsule_radius
	cap.height = body_capsule_height


## Builds SpriteFrames from individual PNGs and attaches them to AnimSprite.
## Called once from _ready() when a skin is configured.
func _setup_animation() -> void:
	if not is_instance_valid(anim_sprite):
		return
	if npc_skin.is_empty():
		anim_sprite.visible = false
		sprite.visible = true
		_has_anim = false
		return

	var frames := SpriteFrames.new()
	frames.remove_animation("default")  # remove placeholder
	var loaded_any := false

	for dir in ["down", "up", "left", "right"]:
		var textures: Array[Texture2D] = []
		for n in range(1, _FRAME_COUNT + 1):
			var path := "%s%s_%s_%d.png" % [_NPC_ASSET_DIR, npc_skin, dir, n]
			if ResourceLoader.exists(path):
				textures.append(load(path) as Texture2D)
		if textures.is_empty():
			continue
		var anim_name := "walk_%s" % dir
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, float(animation_fps))
		frames.set_animation_loop(anim_name, true)
		for tex in textures:
			frames.add_frame(anim_name, tex)
		loaded_any = true

		# Idle animation for this direction (single frame).
		var idle_path := "%s%s_%s_Idle.png" % [_NPC_ASSET_DIR, npc_skin, dir]
		var idle_anim := "idle_%s" % dir
		frames.add_animation(idle_anim)
		frames.set_animation_speed(idle_anim, 1.0)
		frames.set_animation_loop(idle_anim, false)
		if ResourceLoader.exists(idle_path):
			frames.add_frame(idle_anim, load(idle_path) as Texture2D)
		else:
			# Fallback: reuse first walk frame when no idle sprite exists.
			frames.add_frame(idle_anim, textures[0])

	if not loaded_any:
		push_warning("DialogueNPC '%s': no frames found for skin '%s' in %s" % [name, npc_skin, _NPC_ASSET_DIR])
		anim_sprite.visible = false
		sprite.visible = true
		_has_anim = false
		return

	anim_sprite.sprite_frames = frames
	anim_sprite.visible = true
	sprite.visible = false
	_has_anim = true
	# Start in idle facing down.
	anim_sprite.play("idle_down")
	_current_anim_dir = ""


## Plays the walk animation for the given facing direction,
## or stops playing (shows idle frame) when direction is Vector2.ZERO.
func _play_anim(direction: Vector2) -> void:
	if not _has_anim or not is_instance_valid(anim_sprite):
		return
	if direction == Vector2.ZERO:
		# Idle: play the directional idle animation (derived from last facing).
		var idle_name := "idle_%s" % _DIR_ANIM.get(_facing, "down")
		anim_sprite.play(idle_name)
		_current_anim_dir = ""  # reset so next walk always triggers a fresh play
		return
	var anim_name := "walk_%s" % _DIR_ANIM.get(direction, "down")
	if anim_name != _current_anim_dir:
		_current_anim_dir = anim_name
		anim_sprite.play(anim_name)


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
	# Show name tag whenever the player is in range (even during dialogue).
	if is_instance_valid(name_tag_anchor):
		name_tag_anchor.visible = show_name_tag and npc_name != "" and _in_range
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


func _change_to_target_scene() -> void:
	if target_scene_path.is_empty():
		return
	if has_node("/root/SceneLoader"):
		get_node("/root/SceneLoader").go_to(target_scene_path)
	else:
		get_tree().change_scene_to_file(target_scene_path)


# --- Movement Logic --------------------------------------------------------

## Call from cutscenes/quests to send the NPC somewhere right now.
## Returns false if the spot is blocked / unreachable. Use `await stopped_moving` to wait for arrival.
func walk_to(point: Vector2) -> bool:
	if _wait_timer == null:
		return false
	_wait_timer.stop()
	var ok := _try_go_to(point)
	if not ok:
		_schedule_wait()
	return ok


## Pauses wandering or patrol movement (e.g. from a cutscene).
func pause_movement() -> void:
	_set_movement_paused(true)


## Resumes wandering or patrol movement.
func resume_movement() -> void:
	_set_movement_paused(false)


## Sets a new home position for wander mode.
func set_home(new_home: Vector2) -> void:
	_home = new_home


func _schedule_wait(first: bool = false) -> void:
	if mode == Mode.STATIONARY or _is_talking:
		return
	if _wait_timer == null:
		return
	var t := randf_range(min_wait, maxf(min_wait, max_wait))
	if first:
		t = randf_range(0.1, maxf(0.1, max_wait)) # desync NPCs so they don't all start together
	_wait_timer.start(maxf(t, 0.05))


func _on_wait_finished() -> void:
	if _is_talking or mode == Mode.STATIONARY:
		return
	match mode:
		Mode.WANDER:
			_pick_wander_target()
		Mode.PATROL:
			_pick_patrol_target()


func _pick_wander_target() -> void:
	for attempt in 8:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(wander_radius * 0.25, wander_radius)
		if _try_go_to(_home + offset):
			return
	_schedule_wait() # nothing reachable this time, try again later


func _pick_patrol_target() -> void:
	var count := _patrol_waypoints.size()
	if count == 0:
		push_warning("%s: Patrol mode needs Marker2D children or patrol_points as waypoints." % get_path())
		return
	_patrol_index += _patrol_step
	if ping_pong:
		if _patrol_index >= count:
			_patrol_step = -1
			_patrol_index = maxi(count - 2, 0)
		elif _patrol_index < 0:
			_patrol_step = 1
			_patrol_index = mini(1, count - 1)
	else:
		_patrol_index = wrapi(_patrol_index, 0, count)
	if not _try_go_to(_patrol_waypoints[_patrol_index]):
		_schedule_wait()


func _try_go_to(point: Vector2) -> bool:
	if use_navigation:
		if _nav_agent == null:
			return false
		var map := _nav_agent.get_navigation_map()
		if NavigationServer2D.map_get_regions(map).is_empty():
			if not _warned_no_nav:
				_warned_no_nav = true
				push_warning("%s: Use Navigation is on but there is no NavigationRegion2D / baked navmesh." % get_path())
			return false
		point = NavigationServer2D.map_get_closest_point(map, point)
		_nav_agent.target_position = point
	elif not _is_path_clear(global_position, point):
		return false
	_target = point
	_start_moving()
	return true


func _is_path_clear(from: Vector2, to: Vector2) -> bool:
	var world := get_world_2d()
	if world == null:
		return true
	var space_state := world.direct_space_state
	if space_state == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(from, to, obstacle_mask)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	return space_state.intersect_ray(query).is_empty()


func _start_moving() -> void:
	_is_moving = true
	# If something keeps the NPC from arriving (stuck on a corner), give up eventually.
	_give_up_left = global_position.distance_to(_target) / speed * 2.5 + 1.0
	set_physics_process(true)
	_play_bob(true)
	started_moving.emit()


func _stop_moving() -> void:
	var was_moving := _is_moving
	_is_moving = false
	set_physics_process(false)
	_play_bob(false)
	_play_anim(Vector2.ZERO)
	if was_moving:
		stopped_moving.emit()
	_schedule_wait()


func _physics_process(delta: float) -> void:
	if not _is_moving or _is_talking:
		return
	_give_up_left -= delta
	if _give_up_left <= 0.0:
		_stop_moving()
		return

	var pos := global_position
	var next := _target
	if use_navigation and _nav_agent != null:
		if _nav_agent.is_navigation_finished():
			_stop_moving()
			return
		next = _nav_agent.get_next_path_position()
	elif pos.distance_to(_target) <= maxf(arrive_distance, speed * delta):
		_stop_moving()
		return

	var desired := pos.direction_to(next) * speed
	if use_navigation and _nav_agent != null and _nav_agent.avoidance_enabled:
		_nav_agent.velocity = desired # result arrives via velocity_computed -> _apply_velocity
	else:
		_apply_velocity(desired)


func _apply_velocity(vel: Vector2) -> void:
	if not _is_moving or _is_talking:
		return
	global_position += vel * get_physics_process_delta_time()
	_face(vel)


func _restart_movement() -> void:
	if _wait_timer == null:
		return
	_is_moving = false
	set_physics_process(false)
	_play_bob(false)
	_wait_timer.stop()
	_schedule_wait(true)


func _set_movement_paused(paused: bool) -> void:
	if _wait_timer:
		_wait_timer.paused = paused
	set_physics_process(not paused and _is_moving)
	_play_bob(not paused and _is_moving)
	if paused:
		_play_anim(Vector2.ZERO)
	elif _is_moving:
		_play_anim(_facing)
	if not paused and not _is_moving and mode != Mode.STATIONARY:
		if _wait_timer and _wait_timer.is_stopped():
			_schedule_wait()


func _face(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	if is_instance_valid(sprite) and flip_sprite and absf(direction.x) > 0.01:
		sprite.flip_h = (direction.x < 0.0) == sprite_faces_right
	var cardinal := Vector2(signf(direction.x), 0.0) if absf(direction.x) >= absf(direction.y) \
			else Vector2(0.0, signf(direction.y))
	if cardinal != _facing:
		_facing = cardinal
		facing_changed.emit(cardinal)
	_play_anim(cardinal)


func _play_bob(active: bool) -> void:
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null
	if not is_instance_valid(sprite):
		return
	sprite.position.y = _sprite_rest_y
	if not active or walk_bob_height <= 0.0:
		return
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(sprite, "position:y", _sprite_rest_y - walk_bob_height, walk_bob_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bob_tween.tween_property(sprite, "position:y", _sprite_rest_y, walk_bob_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# --- Editor Helpers --------------------------------------------------------

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color(0.3, 0.8, 1.0)
	match mode:
		Mode.WANDER:
			draw_circle(Vector2.ZERO, wander_radius, Color(color, 0.08))
			draw_arc(Vector2.ZERO, wander_radius, 0.0, TAU, 64, Color(color, 0.8), 1.0)
		Mode.PATROL:
			var points := PackedVector2Array()
			for child in get_children():
				if child is Marker2D:
					points.append((child as Marker2D).position)
			if points.is_empty() and not patrol_points.is_empty():
				points.append(Vector2.ZERO)
				for pt in patrol_points:
					points.append(pt)
			if points.size() >= 2:
				draw_polyline(points, Color(color, 0.8), 1.5)
				for p in points:
					draw_circle(p, 3.0, Color(color, 0.9))


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if mode == Mode.PATROL:
		var has_markers := false
		for child in get_children():
			if child is Marker2D:
				has_markers = true
				break
		if not has_markers and patrol_points.is_empty():
			warnings.append("Patrol mode needs Marker2D children or patrol_points entries as waypoints.")
	return warnings
