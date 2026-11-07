extends Node
## The only bridge between standalone activities and persistent story progress.

const RUNNER_LAUNCHER = "res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd"
const RUNNER_CONFIG = "res://Minigames/minigames/fit_runner/scripts/api/fit_runner_config.gd"
const TRASH_SCENE = "res://Minigames/trash_train_v3/trash_train/trash_train.tscn"
const BOSS_SCENE = "res://Minigames/boss_fight/boss_fight.tscn"
const BOSS_CONFIG = "res://Minigames/boss_fight/boss_fight_config.gd"
const INTRODUCTION = preload("res://Dialogues/activity_introductions.dialogue")

var _id := ""
var _game: Node
var _leaving := false
var _exit_button: Button
var _message: Label
var _intro_open := false
var _intro_balloon: Node


func _ready() -> void:
	_id = SceneLoader.activity_id
	_build_controls()
	GameState.save_failed.connect(_on_save_failed)
	if not GameState.can_start_activity(_id):
		_message.text = "Không thể bắt đầu thử thách. Hãy quay lại khuôn viên."
		return
	await _show_introduction()
	if _leaving:
		return
	_launch_game()


func _show_introduction() -> void:
	_intro_open = true
	var balloon = DialogueManager.show_dialogue_balloon_scene(preload("res://Dialogues/Bubbles/tutorial_balloon.tscn"), INTRODUCTION, _id)
	balloon.process_mode = Node.PROCESS_MODE_ALWAYS
	balloon.layer = 220
	_intro_balloon = balloon
	# Let the tutorial dim/card own the screen instead of the host overlay.
	_exit_button.get_parent().hide()
	await DialogueManager.dialogue_ended
	if is_instance_valid(balloon):
		await balloon.tree_exited
	_intro_open = false
	_intro_balloon = null
	_exit_button.get_parent().show()
	if is_instance_valid(_game) and _game.has_method("help_closed"):
		_game.help_closed()


func _launch_game() -> void:
	var history := GameState.activity_result(_id)
	match _id:
		"fit_runner", "fit_runner_race":
			var config = load(RUNNER_CONFIG).new()
			config.race_mode = 1 if _id == "fit_runner_race" else 0
			config.lock_mode = true
			config.attempt = int(history.get("attempts", 0)) + 1
			config.assist_level = 1 if int(history.get("failures", 0)) >= 2 else 0
			_game = load(RUNNER_LAUNCHER).create(config)
			_game.run_finished.connect(_on_run_finished)
			_game.quit_requested.connect(_return_to_host)
		"garbage_quest":
			_game = load(TRASH_SCENE).instantiate()
			_game.skip_tutorial = true # shared introduction replaces duplicate tutorial
			_game.failed_attempts = int(history.get("failures", 0))
			_game.run_finished.connect(_on_run_finished)
			_game.closed.connect(func(_result: Variant) -> void: _return_to_host())
		"boss_fight":
			var config = load(BOSS_CONFIG).new()
			config.skill_id = GameState.selected_skill()
			_game = load(BOSS_SCENE).instantiate()
			_game.config = config
			_game.finished.connect(_on_boss_finished)
			_game.help_requested.connect(_show_introduction)
			_game.quit_requested.connect(_return_to_host)
	add_child(_game)


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 100
	add_child(layer)
	var panel := VBoxContainer.new()
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -220
	panel.offset_right = -12
	panel.offset_top = 8
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_exit_button = Button.new()
	_exit_button.text = "Về khuôn viên"
	_exit_button.custom_minimum_size = Vector2(208, 48)
	_exit_button.pressed.connect(_return_to_host)
	panel.add_child(_exit_button)
	# FIT Runner provides Quit in its pause/results menus. Avoid placing the
	# host button over the race placement and pause controls.
	if _id in ["fit_runner", "fit_runner_race"]:
		_exit_button.hide()
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = 208
	panel.add_child(_message)


func _on_run_finished(result: Variant) -> void:
	GameState.record_activity_result(_id, result.to_dict())
	if _id in ["fit_runner", "fit_runner_race"] and is_instance_valid(_game):
		# The module reads this setting when rebuilding its next attempt.
		var history := GameState.activity_result(_id)
		_game.assist_level = 1 if int(history.get("failures", 0)) >= 2 else 0


func _on_boss_finished(result: Variant) -> void:
	# Both outcomes rescue the head; only combat victory earns battle points.
	GameState.record_activity_result(_id, {
		"passed": result.won() or result.spared(), "outcome": String(result.outcome),
		"deaths": result.deaths, "seconds": result.seconds,
		"skill": String(GameState.selected_skill()),
		"difficulty": String(result.difficulty.id) if result.difficulty != null else "normal",
		"score": result.score, "final_hp": result.final_hp, "max_hp": result.max_hp,
		"base_points": result.base_points, "health_bonus": result.health_bonus,
		"score_multiplier": result.score_multiplier,
	})
	_message.text = "Chiến thắng! Trở lại cửa 210C để gặp thầy Trưởng khoa và nhận viên đá cuối cùng." if result.won() else "Chưa giải cứu được thầy. Em có thể thử lại để đánh bại CON BUG."
	if result.won():
		_message.text += "\nĐiểm: %d = (%d + %d HP) × %.1f\nKỷ lục: %d" % [result.score, result.base_points, result.health_bonus, result.score_multiplier, int(GameState.activity_result(_id).get("best_score", 0))]
	elif result.spared():
		_message.text = "CON BUG đã dừng lại. Thầy Trưởng khoa an toàn! Trở lại cửa 210C để nhận viên đá cuối cùng."
	_exit_button.grab_focus()


func _on_save_failed(_error: int) -> void:
	_exit_button.show()
	_message.text = "Chưa lưu được tiến trình. Hãy thử lưu lại trước khi thoát."
	_exit_button.text = "Lưu lại và trở về"


func _return_to_host() -> void:
	if _leaving:
		return
	_leaving = true
	# Some modules can leave the tree paused when Quit is pressed.
	get_tree().paused = false
	GameState.save_game()
	if GameState.last_save_error != OK:
		_leaving = false
		return
	var error := SceneLoader.return_from_minigame()
	if error != OK:
		_leaving = false
		_exit_button.show()
		_message.text = "Không thể trở về. Vui lòng thử lại."
