class_name BossFight
extends Control
## THE entry point for the main game. Runs the whole boss fight (difficulty menu, fight, retry on
## death, win / spare) inside its own isolated 640x480 viewport, scaled to fit whatever space it
## is given. It works with any base resolution and any stretch settings of the host project, has
## its own physics world and canvas layers, and needs no autoloads or Project Settings.
##
##     const BOSS_FIGHT := preload("res://boss_fight/boss_fight.tscn")
##
##     var config := BossFightConfig.new()
##     config.skill_id = &"poison"                  # decided by the earlier part of your game
##     var fight := BOSS_FIGHT.instantiate() as BossFight
##     fight.config = config
##     some_canvas_layer.add_child(fight)           # it fills its parent; put it on top of your UI
##     var result: BossFightResult = await fight.finished
##
## It frees itself after `finished` (free_when_finished).

signal finished(result: BossFightResult)
## SFX / music hooks forwarded from the battle. See the README, "Cues".
signal cue(cue_name: StringName, data: Dictionary)

const DESIGN_SIZE := Vector2(640, 480)

@export var config: BossFightConfig
@export var battle_scene: PackedScene
## Scale by whole numbers when the space allows 2x or more (crisp pixels). Off = smooth fit.
@export var integer_scale := true
## Nearest-neighbour filtering when scaled up (pixel art). Off = smooth.
@export var pixel_filter := true
@export var letterbox_color := Color(0, 0, 0, 1)
@export var free_when_finished := true
## Keep running while get_tree().paused is true (your game may pause itself behind the fight).
@export var run_while_tree_paused := true
## Optional fight music, played until the fight ends. Set its bus on the Music node.
@export var music: AudioStream

@onready var letterbox: ColorRect = %Letterbox
@onready var frame: SubViewportContainer = %Frame
@onready var viewport: SubViewport = %Viewport
@onready var music_player: AudioStreamPlayer = %Music

var battle: BossBattle

var _started_msec := 0


func _ready() -> void:
	add_to_group(&"boss_fight")
	process_mode = Node.PROCESS_MODE_ALWAYS if run_while_tree_paused else Node.PROCESS_MODE_INHERIT
	letterbox.color = letterbox_color
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_filter \
			else CanvasItem.TEXTURE_FILTER_LINEAR
	# Own 2D world: the fight's physics never meets the host game's physics.
	viewport.world_2d = World2D.new()
	battle = battle_scene.instantiate() as BossBattle
	battle.auto_start = false
	_apply_config()
	viewport.add_child(battle)
	battle.cue.connect(func(cue_name: StringName, data: Dictionary) -> void: cue.emit(cue_name, data))
	battle.finished.connect(_on_battle_finished)
	resized.connect(_fit)
	_fit()
	_started_msec = Time.get_ticks_msec()
	if music != null:
		music_player.stream = music
		music_player.play()
	battle.begin()


## Converts a position inside the fight (640x480 space) to this node's canvas space, e.g. to put a
## Dialogue Manager balloon next to the boss.
func game_to_screen(game_position: Vector2) -> Vector2:
	return frame.get_global_transform() * game_position


func _apply_config() -> void:
	if config == null:
		return
	if config.skill != null:
		battle.skill = config.skill
	elif config.skill_id != &"":
		battle.skill_id = String(config.skill_id)
	if config.difficulty != null:
		battle.difficulty = config.difficulty
	elif config.difficulty_id != &"":
		battle.difficulty_id = String(config.difficulty_id)
	if config.enemy_scene != null:
		battle.enemy_scene = config.enemy_scene
	if config.player_name != "":
		battle.player_name = config.player_name


func _fit() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	if integer_scale and factor >= 2.0:
		factor = floorf(factor)
	frame.scale = Vector2(factor, factor)
	frame.position = ((size - DESIGN_SIZE * factor) * 0.5).floor()


func _on_battle_finished(outcome: StringName) -> void:
	var result := BossFightResult.new()
	result.outcome = outcome
	result.deaths = battle.deaths
	result.skill = battle.skill
	result.difficulty = battle.difficulty
	result.seconds = float(Time.get_ticks_msec() - _started_msec) / 1000.0
	music_player.stop()
	finished.emit(result)
	if free_when_finished:
		queue_free()
