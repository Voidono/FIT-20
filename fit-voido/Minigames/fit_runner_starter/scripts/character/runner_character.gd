class_name RunnerCharacter
extends Node2D
## The character (player and ghost use the same scene). All art lives in the scene: SpriteFrames on %Sprite,
## textures on %Shadow / %StatusIcon / the particle nodes. This script only picks an animation from pace and state.
## Your own SpriteFrames just need animations with the names below (missing ones fall back to "run").
## Origin = feet, so the sprite's offset puts the feet on (0, 0).

@export var anim_idle: StringName = &"idle"
@export var anim_jog: StringName = &"jog"  ## pace below the cruise zone
@export var anim_run: StringName = &"run"  ## cruise
@export var anim_push: StringName = &"push"
@export var anim_sprint: StringName = &"sprint"
@export var anim_stumble: StringName = &"stumble"  ## at the wall
@export var anim_drink: StringName = &"drink"
@export_range(0.0, 0.5, 0.01) var idle_below: float = 0.08
@export_range(0.1, 3.0, 0.05) var min_speed_scale: float = 0.7
@export_range(0.1, 3.0, 0.05) var max_speed_scale: float = 1.6
@export_range(0.0, 1.2, 0.01) var dust_above_pace: float = 0.65
@export var status_wall_texture: Texture2D
@export var status_drink_texture: Texture2D

@onready var _body: Node2D = Lookup.node(self, "Body") as Node2D
@onready var _sprite: AnimatedSprite2D = Lookup.node(self, "Sprite") as AnimatedSprite2D
@onready var _dust: CPUParticles2D = Lookup.node(self, "Dust") as CPUParticles2D
@onready var _splash: CPUParticles2D = Lookup.node(self, "Splash") as CPUParticles2D
@onready var _status: Sprite2D = Lookup.node(self, "StatusIcon") as Sprite2D

var _was_drinking: bool = false


## pace: fraction of max speed. slope_angle: radians, negative = nose up.
func apply(pace: float, walled: bool, drinking: bool, slope_angle: float) -> void:
	var anim: StringName = _animation_for(pace, walled, drinking)
	if _sprite.sprite_frames != null:
		if not _sprite.sprite_frames.has_animation(anim):
			anim = anim_run
		if _sprite.animation != anim and _sprite.sprite_frames.has_animation(anim):
			_sprite.play(anim)
	_sprite.speed_scale = lerpf(min_speed_scale, max_speed_scale, clampf(pace / 1.2, 0.0, 1.0))
	_body.rotation = slope_angle

	_status.visible = walled or drinking
	if walled:
		_status.texture = status_wall_texture
	elif drinking:
		_status.texture = status_drink_texture

	_dust.emitting = pace > dust_above_pace and not walled
	if drinking and not _was_drinking:
		_splash.restart()
		_splash.emitting = true
	_was_drinking = drinking


func _animation_for(pace: float, walled: bool, drinking: bool) -> StringName:
	if walled:
		return anim_stumble
	if drinking:
		return anim_drink
	if pace < idle_below:
		return anim_idle
	if pace < Zones.CRUISE_FROM:
		return anim_jog
	if pace < Zones.PUSH_FROM:
		return anim_run
	if pace < Zones.SPRINT_FROM:
		return anim_push
	return anim_sprint
