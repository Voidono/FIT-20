extends Node
## The only bridge between standalone activities and persistent story progress.

const RUNNER_LAUNCHER = "res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd"
const RUNNER_CONFIG = "res://Minigames/minigames/fit_runner/scripts/api/fit_runner_config.gd"
const TRASH_SCENE = "res://Minigames/trash_train_v3/trash_train/trash_train.tscn"
const BOSS_SCENE = "res://Minigames/boss_fight/boss_fight.tscn"
const BOSS_CONFIG = "res://Minigames/boss_fight/boss_fight_config.gd"

var _id := ""
var _game: Node
var _leaving := false
var _exit_button: Button
var _message: Label


func _ready() -> void:
	_id = SceneLoader.activity_id
	_build_controls()
	GameState.save_failed.connect(_on_save_failed)
	if not GameState.can_start_activity(_id):
		_message.text = "Không thể bắt đầu thử thách. Hãy quay lại khuôn viên."
		return
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
			_game.failed_attempts = int(history.get("failures", 0))
			_game.run_finished.connect(_on_run_finished)
			_game.closed.connect(func(_result: Variant) -> void: _return_to_host())
		"boss_fight":
			var config = load(BOSS_CONFIG).new()
			config.skill_id = GameState.selected_skill()
			_game = load(BOSS_SCENE).instantiate()
			_game.config = config
			_game.finished.connect(_on_boss_finished)
	add_child(_game)


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 100
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.position = Vector2(get_viewport().get_visible_rect().size.x - 220, 8)
	layer.add_child(panel)
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
	# Proposal requires defeating CON BUG. Spare is retained as an outcome,
	# but does not award story completion until that design choice is approved.
	GameState.record_activity_result(_id, {
		"passed": result.won(), "outcome": String(result.outcome),
		"deaths": result.deaths, "seconds": result.seconds,
		"skill": String(GameState.selected_skill()),
	})
	_message.text = "Chiến thắng! Hãy trở về gặp giảng viên." if result.won() else "Đã kết thúc trận đấu."
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
