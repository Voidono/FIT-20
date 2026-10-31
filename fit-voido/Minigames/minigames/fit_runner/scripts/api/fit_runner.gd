class_name FitRunner
extends Node2D
## FIT Runner minigame: one self-contained scene (minigames/fit_runner/fit_runner.tscn). Nothing else in the project is touched:
## no autoloads, no project settings, no input action of yours, and your camera is handed back when this scene leaves.
##
##   var config := FitRunnerConfig.new()  # optional
##   var game := FitRunnerLauncher.launch(self, config)  # instances the scene and adds it as a child of self
##   game.run_finished.connect(_on_run_finished)  # FitRunnerResult: passed, time_sec, stars, walls_hit, attempt, par_time, qte_*
##   game.quit_requested.connect(_on_quit)  # Continue / Quit pressed: you own scene changes, usually game.queue_free()
##
## Everything the player does goes through ONE input action (push_action) -> one effort value (0..1) -> pace -> stamina.
## The world, character and HUD are scenes: this script only moves nodes and feeds them values.

signal run_finished(result: FitRunnerResult)
signal quit_requested

const DT: float = 1.0 / 60.0  ## fixed simulation step: the same run gives the same time on every device
const MAX_FRAME: float = 0.1
const PREDICT_INTERVAL: float = 0.5
const PREDICT_DT: float = 0.2
const LOG_INTERVAL: float = 0.5
const EFFORT_AVG_TIME: float = 1.5

@export var tuning: FrTuning
@export_range(0.1, 0.6, 0.01) var camera_anchor_x: float = 0.33  ## runner stays near the left third of the screen
@export_range(0.3, 0.9, 0.01) var camera_runner_y: float = 0.62  ## and 62% of the way down
@export_range(0.0, 5.0, 0.5) var countdown_seconds: float = 3.0
@export var push_action: StringName = &"fr_push"  ## speed control: hold to push / accelerate
@export var qte_action: StringName = &"fr_qte"    ## QTE action tap: hit sweet spot at checkpoints
@export var debug_enabled: bool = false  ## shows the DBG tuning overlay; leave off in the real game
@export var require_landscape_window: bool = true  ## "rotate your phone" prompt when the window is portrait
@export var pause_keys_enabled: bool = true  ## Esc and P pause (turn off if your game owns those keys)
@export var autostart: bool = true  ## false: the host calls start() itself

@onready var _camera: Camera2D = FrLookup.node(self, "Camera") as Camera2D
@onready var _course: FrCourse = FrLookup.node(self, "Course") as FrCourse
@onready var _ghost: FrCharacter = FrLookup.node(self, "Ghost") as FrCharacter
@onready var _runner: FrCharacter = FrLookup.node(self, "Runner") as FrCharacter
@onready var _hud: FrHud = FrLookup.node(self, "Hud") as FrHud
@onready var _debug: FrDebugOverlay = FrLookup.node(self, "DebugOverlay") as FrDebugOverlay
@onready var _qte: FrQteController = FrLookup.node(self, "Qte") as FrQteController

var phase: int = FrRunState.Phase.READY
var model: FrModel
var profile: FrCourseProfile
var effort_input: FrEffortInput
var par_bot: FrParBot
var par_time: float = 0.0
var cutoff_time: float = 0.0
var attempt: int = 1
var assist_level: int = 0
var last_result: FitRunnerResult

var _hud_state := FrHudState.new()
var _acc: float = 0.0
var _alpha: float = 1.0
var _push_held: bool = false
var _press_blocked: bool = false
var _release_timer: float = 0.0
var _countdown_left: float = 0.0
var _phase_before_pause: int = FrRunState.Phase.RUNNING
var _effort_avg: float = 0.0
var _avg_k: float = 0.0
var _outlook: int = 0
var _outlook_stamina: float = 100.0
var _outlook_timer: float = 0.0
var _par_key: int = 0
var _cam_y: float = 0.0
var _cam_ready: bool = false
var _log_rows: Array[PackedFloat32Array] = []
var _log_timer: float = 0.0
var _press_is_qte: bool = false  ## the current press was spent on a QTE tap; holding on turns it into running
var _qte_press_time: float = 0.0
var _qte_log: PackedStringArray = PackedStringArray()
var _prev_camera: Camera2D
var _config_qte: FrQteSettings


func _ready() -> void:
	if FitRunnerStrings.install():
		propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)  # scene was instanced before the strings existed: refresh the labels
	_ensure_input_action()
	if tuning == null:
		tuning = FrTuning.new()
	if _config_qte != null:
		_qte.settings = _config_qte
	_avg_k = 1.0 - exp(-DT / EFFORT_AVG_TIME)
	if debug_enabled:
		_debug.bind(tuning)
		_debug.bind_qte(_qte.settings, _qte_preset_index())
	else:
		_debug.queue_free()
		_debug = null
	_prev_camera = get_viewport().get_camera_2d()  # remembered so the host's camera comes back on exit
	_camera.make_current()
	if _hud != null:
		_hud.speed_button_down.connect(_on_speed_button_down)
		_hud.speed_button_up.connect(_on_speed_button_up)
		_hud.qte_button_pressed.connect(_on_qte_button_pressed)
	get_window().size_changed.connect(_on_window_resized)
	_on_window_resized()
	if autostart:
		start()  # the Hud and debug overlay signals are connected in fit_runner.tscn


func _exit_tree() -> void:
	if is_instance_valid(_prev_camera) and _prev_camera != _camera and _prev_camera.is_inside_tree():
		_prev_camera.make_current()


# ---------------------------------------------------------------- public API

## Apply what the host passes in. Call it before add_child (FitRunnerLauncher does).
func configure(config: FitRunnerConfig) -> void:
	if config == null:
		return
	if config.tuning != null:
		tuning = config.tuning
	_config_qte = config.qte
	attempt = config.attempt
	assist_level = config.assist_level
	debug_enabled = config.debug_enabled
	push_action = config.push_action
	if config.qte_action != &"":
		qte_action = config.qte_action
	require_landscape_window = config.require_landscape_window
	pause_keys_enabled = config.pause_keys_enabled
	autostart = config.autostart


## (Re)start with a fresh run waiting for the first tap. config keys: attempt (int), assist (int, 0 = off).
func start(config: Dictionary = {}) -> void:
	if config.has("attempt"):
		attempt = int(config["attempt"])
	if config.has("assist"):
		assist_level = int(config["assist"])
	_prepare()


## Same attempt number, fresh run (used by the debug overlay).
func restart() -> void:
	start()


## Next attempt (used by the Retry buttons).
func retry() -> void:
	attempt += 1
	start()


func toggle_pause() -> void:
	if phase == FrRunState.Phase.RUNNING or phase == FrRunState.Phase.COUNTDOWN:
		_phase_before_pause = phase
		_push_held = false
		_press_is_qte = false
		_set_phase(FrRunState.Phase.PAUSED)
	elif phase == FrRunState.Phase.PAUSED:
		_push_held = false
		_set_phase(_phase_before_pause)


func build_log_text() -> String:
	var lines: PackedStringArray = []
	lines.append("FIT Runner log %s" % Time.get_datetime_string_from_system())
	var mode_name: String = "B" if tuning.input_mode == FrTuning.InputMode.TIERS else "A"
	lines.append("mode=%s attempt=%d par=%.2f cutoff=%.2f" % [mode_name, attempt, par_time, cutoff_time])
	if last_result != null:
		lines.append("result passed=%s time=%.2f stars=%d walls=%d" % [str(last_result.passed), last_result.time_sec, last_result.stars, last_result.walls_hit])
	lines.append("--- tuning")
	lines.append(tuning.to_text())
	if _qte.settings != null:
		lines.append("--- qte settings (enabled=%s)" % str(_qte.is_enabled()))
		lines.append(_qte.settings.to_text())
		lines.append("--- qte events: time,grade,bonus")
		lines.append("\n".join(_qte_log))
	lines.append("--- t,progress,effort,pace,stamina,rate,walled,held")
	for row: PackedFloat32Array in _log_rows:
		lines.append("%.1f,%.3f,%.2f,%.2f,%.1f,%.2f,%d,%d" % [row[0], row[1], row[2], row[3], row[4], row[5], int(row[6]), int(row[7])])
	return "\n".join(lines)


# ---------------------------------------------------------------- setup

## Setup InputMap actions for Speed (fr_push / fr_speed) and QTE (fr_qte).
func _ensure_input_action() -> void:
	if not InputMap.has_action(push_action):
		InputMap.add_action(push_action)
		var space := InputEventKey.new()
		space.physical_keycode = KEY_SPACE
		InputMap.action_add_event(push_action, space)
		var key_w := InputEventKey.new()
		key_w.physical_keycode = KEY_W
		InputMap.action_add_event(push_action, key_w)
		var key_up := InputEventKey.new()
		key_up.physical_keycode = KEY_UP
		InputMap.action_add_event(push_action, key_up)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(push_action, click)

	if not InputMap.has_action(qte_action):
		InputMap.add_action(qte_action)
		var enter := InputEventKey.new()
		enter.physical_keycode = KEY_ENTER
		InputMap.action_add_event(qte_action, enter)
		var key_j := InputEventKey.new()
		key_j.physical_keycode = KEY_J
		InputMap.action_add_event(qte_action, key_j)
		var key_k := InputEventKey.new()
		key_k.physical_keycode = KEY_K
		InputMap.action_add_event(qte_action, key_k)
		var key_down := InputEventKey.new()
		key_down.physical_keycode = KEY_DOWN
		InputMap.action_add_event(qte_action, key_down)


func _prepare() -> void:
	profile = FrCourseProfile.new(tuning)
	model = FrModel.new(tuning, profile)
	model.assist_level = assist_level
	effort_input = FrEffortFactory.create(tuning)
	var key: int = tuning.to_text().hash()
	if par_bot == null or key != _par_key:
		par_bot = FrParBot.build(tuning)  # about 6000 simulated ticks, rebuilt only when a tuning value changed
		_par_key = key
	par_time = tuning.par_time_override if tuning.par_time_override > 0.0 else par_bot.finish_time
	cutoff_time = par_time * tuning.cutoff_mult
	_course.setup(tuning, profile)
	_hud.configure(tuning, profile)
	_acc = 0.0
	_alpha = 1.0
	_push_held = false
	_press_blocked = false
	_release_timer = 0.0
	_effort_avg = effort_input.effort
	_outlook = 0
	_outlook_stamina = tuning.stamina_max
	_outlook_timer = 0.0
	_log_rows.clear()
	_log_timer = 0.0
	_press_is_qte = false
	_qte_press_time = 0.0
	_qte_log.clear()
	_qte.reset(attempt * 7919 + 13)
	_cam_ready = false
	last_result = null
	_set_phase(FrRunState.Phase.READY)
	_update_views(0.0)
	_refresh_hud(0.0)


func _set_phase(p: int) -> void:
	phase = p
	_hud.set_phase(p, last_result)


func _start_countdown() -> void:
	_countdown_left = countdown_seconds
	_set_phase(FrRunState.Phase.COUNTDOWN)


func _begin_run() -> void:
	effort_input.reset()
	_effort_avg = effort_input.effort
	_push_held = Input.is_action_pressed(push_action) and not _press_blocked
	_acc = 0.0
	_set_phase(FrRunState.Phase.RUNNING)


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(qte_action):
		_on_qte_button_pressed()
	elif event.is_action_pressed(push_action):
		if _is_over_ui(event):
			_press_blocked = true  # a tap on a button or the debug panel is not "push"
		else:
			_press_blocked = false
			_on_push_pressed()
	elif event.is_action_released(push_action):
		_push_held = false
		_press_blocked = false
	elif event is InputEventKey:
		var key: InputEventKey = event
		if pause_keys_enabled and key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.keycode == KEY_P):
			toggle_pause()


func _is_over_ui(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton):
		return false
	var mouse: InputEventMouseButton = event
	return _hud.is_point_over_ui(mouse.position) or (_debug != null and _debug.is_point_over_ui(mouse.position))


func _on_push_pressed() -> void:
	if model == null:
		return
	if phase == FrRunState.Phase.READY:
		_start_countdown()
	elif phase == FrRunState.Phase.RUNNING:
		_push_held = true


func _on_speed_button_down() -> void:
	if phase == FrRunState.Phase.READY:
		_start_countdown()
	elif phase == FrRunState.Phase.RUNNING:
		_push_held = true


func _on_speed_button_up() -> void:
	_push_held = false


func _on_qte_button_pressed() -> void:
	if phase == FrRunState.Phase.READY:
		_start_countdown()
	elif phase == FrRunState.Phase.RUNNING and _qte.is_active():
		_qte.on_tap(_acc)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_push_held = false
		if phase == FrRunState.Phase.RUNNING or phase == FrRunState.Phase.COUNTDOWN:
			toggle_pause()


func _on_window_resized() -> void:
	var win_size: Vector2i = get_window().size
	var portrait: bool = require_landscape_window and win_size.y > win_size.x
	_hud.set_portrait(portrait)
	if portrait and (phase == FrRunState.Phase.RUNNING or phase == FrRunState.Phase.COUNTDOWN):
		toggle_pause()


func _on_quit_pressed() -> void:
	quit_requested.emit()


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if model == null:
		return  # autostart is off and the host has not called start() yet
	var time_scale: float = 1.0
	if _qte.is_active() and _qte.settings != null:
		time_scale = _qte.settings.qte_time_scale
	var frame: float = minf(delta * time_scale, MAX_FRAME)
	if phase == FrRunState.Phase.COUNTDOWN:
		_countdown_left -= delta
		if _countdown_left <= 0.0:
			_begin_run()
	elif phase == FrRunState.Phase.RUNNING:
		_acc += frame
		while _acc >= DT and phase == FrRunState.Phase.RUNNING:
			_sim_tick()
			_acc -= DT
		_alpha = _acc / DT if phase == FrRunState.Phase.RUNNING else 1.0
	_update_views(frame)
	_refresh_hud(frame)


func _sim_tick() -> void:
	var progress: float = clampf(model.progress(), 0.0, 1.0)
	var effort: float = effort_input.update(DT, _push_held, progress)
	_effort_avg += (effort - _effort_avg) * _avg_k

	# Checkpoint QTE trigger
	var cp_index: int = model.poll_checkpoint()
	if cp_index >= 0:
		_qte.trigger_checkpoint(cp_index)

	_qte.tick(DT)

	var walls_before: int = model.walls_hit
	model.step(DT, effort)
	if model.walls_hit > walls_before and tuning.haptics:
		Input.vibrate_handheld(120)

	_outlook_timer -= DT
	if _outlook_timer <= 0.0:
		_outlook_timer = PREDICT_INTERVAL
		_update_outlook()
	_log_timer -= DT
	if _log_timer <= 0.0:
		_log_timer = LOG_INTERVAL
		_log_rows.append(PackedFloat32Array([model.elapsed, model.progress(), effort, model.pace, model.stamina, model.rate, 1.0 if model.walled else 0.0, 1.0 if _push_held else 0.0]))

	if model.finished and model.finish_time <= cutoff_time:
		_finish_run(true)
	elif model.finished or model.elapsed >= cutoff_time:
		_finish_run(false)


## "Will you make it?": runs a copy of the model forward at your recent average effort.
func _update_outlook() -> void:
	var sim: FrModel = model.clone()
	var walls_before: int = sim.walls_hit
	var steps: int = 0
	while (not sim.finished) and steps < 1500:
		sim.step(PREDICT_DT, _effort_avg)
		steps += 1
	_outlook_stamina = sim.stamina
	if sim.walls_hit > walls_before:
		_outlook = 2
	elif sim.stamina < 8.0:
		_outlook = 1
	else:
		_outlook = 0


func _stars_for(time_sec: float) -> int:
	if time_sec <= par_time * tuning.star3_mult:
		return 3
	if time_sec <= par_time * tuning.star2_mult:
		return 2
	return 1


func _finish_run(reached_finish: bool) -> void:
	var result := FitRunnerResult.new()
	result.attempt = attempt
	result.walls_hit = model.walls_hit
	result.par_time = par_time
	result.input_mode = int(tuning.input_mode)
	result.qte_perfect = _qte.perfect_count
	result.qte_good = _qte.good_count
	result.qte_miss = _qte.miss_count
	if reached_finish:
		result.passed = true
		result.time_sec = model.finish_time
		result.stars = _stars_for(model.finish_time)
	else:
		result.passed = false
		result.time_sec = minf(model.elapsed, cutoff_time)
		result.stars = 0
	last_result = result
	_push_held = false
	_set_phase(FrRunState.Phase.FINISHED)
	run_finished.emit(result)


# ---------------------------------------------------------------- QTE

func _on_qte_resolved(grade: int, bonus: float, _streak: int, boost_mult: float = 1.0, boost_dur: float = 0.0) -> void:
	model.add_stamina(bonus)
	if boost_mult > 1.0 and boost_dur > 0.0:
		model.apply_speed_boost(boost_mult, boost_dur)
	var names: Array[String] = ["MISS", "GOOD", "PERFECT"]
	_qte_log.append("%.1f,%s,%.1f" % [model.elapsed, names[clampi(grade, 0, 2)], bonus])
	if tuning.haptics and grade == FrQteController.Grade.PERFECT:
		Input.vibrate_handheld(30)


func _on_qte_preset_selected(index: int) -> void:
	_qte.apply_preset(index)
	if _debug != null:
		_debug.bind_qte(_qte.settings, index)


func _qte_preset_index() -> int:
	if _qte.settings == _qte.preset_easy:
		return 1
	if _qte.settings == _qte.preset_hard:
		return 3
	return 2


# ---------------------------------------------------------------- views

func _visual_time() -> float:
	if phase == FrRunState.Phase.RUNNING:
		return model.elapsed + _alpha * DT
	return model.elapsed


func _update_views(delta: float) -> void:
	var view: Vector2 = get_viewport_rect().size
	var px: float = lerpf(model.prev_pos, model.pos, _alpha)
	var ground: float = _course.ground_y_at(px)
	var target_y: float = ground - view.y * (camera_runner_y - 0.5)
	if not _cam_ready:
		_cam_y = target_y
		_cam_ready = true
	else:
		_cam_y = lerpf(_cam_y, target_y, 1.0 - exp(-5.0 * delta))
	_camera.global_position = Vector2(px + view.x * (0.5 - camera_anchor_x), _cam_y)

	_runner.position = Vector2(px, ground)
	_runner.apply(model.pace, model.walled, model.drinking, clampf(atan(-profile.slope_at(px)), -0.35, 0.35))

	var t_visual: float = _visual_time()
	var gp: float = minf(par_bot.position_at(t_visual), tuning.track_length)
	var g_pace: float = (par_bot.position_at(t_visual + 0.1) - par_bot.position_at(t_visual)) / 0.1 / tuning.max_speed
	_ghost.position = Vector2(gp, _course.ground_y_at(gp))
	_ghost.apply(g_pace, false, false, clampf(atan(-profile.slope_at(gp)), -0.35, 0.35))


func _refresh_hud(delta: float) -> void:
	var s: FrHudState = _hud_state
	s.phase = phase
	s.model = model
	s.tuning = tuning
	s.countdown_left = _countdown_left
	s.effort = effort_input.effort
	s.outlook = _outlook
	s.outlook_stamina = _outlook_stamina
	s.par_time = par_time
	s.cutoff_time = cutoff_time
	s.attempt = attempt
	s.qte_phase = _qte.phase
	s.qte_cursor = _qte.cursor()
	s.runner_screen_pos = get_viewport().get_canvas_transform() * _runner.global_position
	s.ghost_progress = minf(par_bot.position_at(_visual_time()), tuning.track_length) / tuning.track_length
	s.has_delta = phase == FrRunState.Phase.RUNNING and model.pos > 50.0
	if s.has_delta:
		s.delta_vs_par = par_bot.time_at(model.pos) - model.elapsed
	_hud.refresh(delta, s)
	if _debug != null:
		_debug.refresh(s)


func _copy_log() -> void:
	DisplayServer.clipboard_set(build_log_text())
