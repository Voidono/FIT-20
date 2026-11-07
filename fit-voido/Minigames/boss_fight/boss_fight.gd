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
signal help_requested
signal quit_requested
## SFX / music hooks forwarded from the battle. See the README, "Cues".
signal cue(cue_name: StringName, data: Dictionary)

const DESIGN_SIZE := Vector2(640, 480)
const INTRODUCTION = preload("res://Dialogues/activity_introductions.dialogue")

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
var _paused := false
var _previous_pause := false
var _pause_panel: Control
var _resume_button: Button
var _pause_started := 0
var _paused_msec := 0


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
	_build_pause_menu()
	if music != null:
		music_player.stream = music
		music_player.play()
	battle.begin()


func _build_pause_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 150
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var pause_button := Button.new()
	pause_button.text = "Ⅱ"
	pause_button.theme = preload("res://scenes/UI/quests/quest_theme.tres")
	pause_button.custom_minimum_size = Vector2(48, 44)
	layer.add_child(pause_button)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	pause_button.position = Vector2(12, 30)
	pause_button.pressed.connect(toggle_pause)
	_pause_panel = ColorRect.new()
	_pause_panel.color = Color(0.02, 0.04, 0.04, 0.95)
	_pause_panel.theme = preload("res://scenes/UI/quests/quest_theme.tres")
	layer.add_child(_pause_panel)
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_pause_panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 260
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var heading := Label.new()
	heading.text = "TẠM DỪNG — CON BUG"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	_resume_button = _pause_action(box, "Tiếp tục", toggle_pause)
	_pause_action(box, "Xem lại hướng dẫn", func():
		if help_requested.has_connections():
			_pause_panel.hide()
			help_requested.emit()
		else:
			_show_help()
	)
	_pause_action(box, "Về khuôn viên", func():
		_restore_pause()
		quit_requested.emit()
		if not quit_requested.has_connections():
			_on_battle_finished(&"quit")
	)
	_pause_panel.hide()


func _pause_action(box: VBoxContainer, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 48
	button.pressed.connect(callback)
	box.add_child(button)
	return button


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE, KEY_P]:
		# While help is open its bubble owns input; the pause state remains intact.
		if _paused and not _pause_panel.visible:
			return
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if _paused:
		_restore_pause()
		return
	_paused = true
	_pause_started = Time.get_ticks_msec()
	_previous_pause = get_tree().paused
	viewport.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = true
	music_player.stream_paused = true
	_pause_panel.show()
	_resume_button.grab_focus()


func _restore_pause() -> void:
	if not _paused:
		return
	get_tree().paused = _previous_pause
	_paused_msec += Time.get_ticks_msec() - _pause_started
	viewport.process_mode = Node.PROCESS_MODE_INHERIT
	music_player.stream_paused = false
	_paused = false
	_pause_panel.hide()


func help_closed() -> void:
	if _paused:
		_pause_panel.show()
		_resume_button.grab_focus()


func _show_help() -> void:
	_pause_panel.hide()
	var manager = get_node_or_null("/root/DialogueManager")
	if manager == null:
		help_closed()
		return
	var balloon = manager.show_dialogue_balloon_scene(load("res://Dialogues/Bubbles/tutorial_balloon.tscn"), INTRODUCTION, "boss_fight")
	balloon.process_mode = Node.PROCESS_MODE_ALWAYS
	balloon.layer = 220
	await manager.dialogue_ended
	if is_instance_valid(balloon):
		await balloon.tree_exited
	help_closed()


func _exit_tree() -> void:
	_restore_pause()


## Converts a position inside the fight (640x480 space) to this node's canvas space, e.g. to put a
## Dialogue Manager balloon next to the boss.
func game_to_screen(game_position: Vector2) -> Vector2:
	return frame.get_global_transform() * game_position


func _apply_config() -> void:
	if config == null:
		return
	battle.debug_enabled = config.debug_enabled
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
	result.final_hp = battle.stats.hp if battle.stats != null else 0
	result.max_hp = battle.stats.max_hp if battle.stats != null else 1
	result.calculate_score()
	result.seconds = float(Time.get_ticks_msec() - _started_msec - _paused_msec) / 1000.0
	music_player.stop()
	finished.emit(result)
	if free_when_finished:
		queue_free()
