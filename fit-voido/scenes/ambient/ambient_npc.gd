@tool
extends "res://scenes/Character/dialogue_npc.gd"
## Optional campus banter. No quest flags, rewards, or scene transitions.
@export var conversation_cues: PackedStringArray = []
var _last_conversation := -1

func talk() -> void:
	if not _in_range or _is_talking or is_any_talking:
		return
	if not conversation_cues.is_empty():
		# Shuffle the opening, then avoid hearing the same exchange twice in a row.
		var next := randi_range(0, conversation_cues.size() - 1)
		if next == _last_conversation and conversation_cues.size() > 1:
			next = (next + 1) % conversation_cues.size()
		_last_conversation = next
		cue = conversation_cues[next]
		repeat_cue = cue
	super.talk()

func _setup_animation() -> void:
	if npc_skin != "boykopho":
		super._setup_animation()
		return
	# Existing numbered student artwork: three walking frames per direction.
	# The right-facing sequence is mirrored for the matching left-facing walk.
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var directions := {"down": [1, 2, 3], "up": [4, 5, 6], "right": [7, 8, 9], "left": [7, 8, 9]}
	for direction in directions:
		frames.add_animation("walk_" + direction)
		frames.set_animation_speed("walk_" + direction, animation_fps)
		for number in directions[direction]:
			frames.add_frame("walk_" + direction, load("res://assets/DrawAsset/NPC/boykopho%d.png" % number))
		frames.add_animation("idle_" + direction)
		var idle_frame: int = 10 if direction == "left" else directions[direction][1]
		frames.add_frame("idle_" + direction, load("res://assets/DrawAsset/NPC/boykopho%d.png" % idle_frame))
	anim_sprite.sprite_frames = frames
	anim_sprite.visible = true
	sprite.visible = false
	_has_anim = true
	anim_sprite.play("idle_down")

func _play_anim(direction: Vector2) -> void:
	if npc_skin == "boykopho" and is_instance_valid(anim_sprite):
		var facing := _facing if direction == Vector2.ZERO else direction
		anim_sprite.flip_h = facing == Vector2.LEFT and direction != Vector2.ZERO
	super._play_anim(direction)

func _apply_body_shape() -> void:
	# Narrow ambient bodies without mutating the shared story-NPC capsule.
	if has_node("Body/BodyShape"):
		var body_shape := get_node("Body/BodyShape") as CollisionShape2D
		if body_shape.shape != null and not body_shape.shape.resource_local_to_scene:
			body_shape.shape = body_shape.shape.duplicate()
			body_shape.shape.resource_local_to_scene = true
	super._apply_body_shape()
