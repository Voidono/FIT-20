class_name FitRunner
extends Node2D
## FIT Runner minigame - self-contained scene (scenes/fit_runner.tscn).
##
##   var game := preload("res://scenes/fit_runner.tscn").instantiate() as FitRunner
##   add_child(game)
##   game.run_finished.connect(_on_run_finished)  # RunResult: passed, time_sec, stars, walls_hit, attempt, par_time
##   game.quit_requested.connect(_on_quit)  # the main game owns scene changes
##   game.start({"attempt": 1, "assist": 0})  # optional; _ready() already starts a run
##
## Everything the player does goes through one "push" action -> one effort value (0..1) -> pace -> stamina.
## The world, character and HUD are scenes: this script only moves nodes and feeds them values.
## It has its own Camera2D; enable the main game's camera again when you leave this scene.

signal run_finished(result: RunResult)
signal quit_requested

const DT: float = 1.0 / 60.0  ## fixed simulation step: the same run gives the same time on every device
const MAX_FRAME: float = 0.1
const ACTION_PUSH: StringName = &"push"
const PREDICT_INTERVAL: float = 0.5
const PREDICT_DT: float = 0.2
const LOG_INTERVAL: float = 0.5
const EFFORT_AVG_TIME: float = 1.5

@export var tuning: RunnerTuning
@export_range(0.1, 0.6, 0.01) var camera_anchor_x: float = 0.33  ## runner stays near the left third of the screen
@export_range(0.3, 0.9, 0.01) var camera_runner_y: float = 0.62  ## and 62% of the way down
@export_range(0.0, 5.0, 0.5) var countdown_seconds: float = 3.0

@onready var _camera: Camera2D = %Camera
@onready var _course: Course = %Course
@onready var _ghost: RunnerCharacter = %Ghost
@onready var _runner: RunnerCharacter = %Runner
@onready var _hud: Hud = %Hud
@onready var _debug: DebugOverlay = %DebugOverlay

var phase: int = RunState.Phase.READY
var model: RunnerModel
var profile: CourseProfile
var effort_input: EffortInput
var par_bot: ParBot
var par_time: float = 0.0
var cutoff_time: float = 0.0
var attempt: int = 1
var assist_level: int = 0
var last_result: RunResult

var _hud_state := HudState.new()
var _acc: float = 0.0
var _alpha: float = 1.0
var _push_held: bool = false
var _press_blocked: bool = false
var _release_timer: float = 0.0
var _countdown_left: float = 0.0
var _phase_before_pause: int = RunState.Phase.RUNNING
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


func _ready() -> void:
	_ensure_input_action()
	if tuning == null:
		tuning = RunnerTuning.new()
	_avg_k = 1.0 - exp(-DT / EFFORT_AVG_TIME)
	_debug.bind(tuning)
	_camera.make_current()
	get_window().size_changed.connect(_on_window_resized)
	_on_window_resized()
	start()  # the Hud and DebugOverlay signals are connected in fit_runner.tscn


# ---------------------------------------------------------------- public API

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
	if phase == RunState.Phase.RUNNING or phase == RunState.Phase.COUNTDOWN:
		_phase_before_pause = phase
		_push_held = false
		_set_phase(RunState.Phase.PAUSED)
	elif phase == RunState.Phase.PAUSED:
		_push_held = false
		_set_phase(_phase_before_pause)


func build_log_text() -> String:
	var lines: PackedStringArray = []
	lines.append("FIT Runner log %s" % Time.get_datetime_string_from_system())
	var mode_name: String = "B" if tuning.input_mode == RunnerTuning.InputMode.TIERS else "A"
	lines.append("mode=%s attempt=%d par=%.2f cutoff=%.2f" % [mode_name, attempt, par_time, cutoff_time])
	if last_result != null:
		lines.append("result passed=%s time=%.2f stars=%d walls=%d" % [str(last_result.passed), last_result.time_sec, last_result.stars, last_result.walls_hit])
	lines.append("--- tuning")
	lines.append(tuning.to_text())
	lines.append("--- t,progress,effort,pace,stamina,rate,walled,held")
	for row: PackedFloat32Array in _log_rows:
		lines.append("%.1f,%.3f,%.2f,%.2f,%.1f,%.2f,%d,%d" % [row[0], row[1], row[2], row[3], row[4], row[5], int(row[6]), int(row[7])])
	return "\n".join(lines)


# ---------------------------------------------------------------- setup

## One InputMap action for touch and mouse. A phone tap arrives as an emulated left click
## (Project Settings > Input Devices > Pointing > Emulate Mouse From Touch, on by default).
func _ensure_input_action() -> void:
	if InputMap.has_action(ACTION_PUSH):
		return
	InputMap.add_action(ACTION_PUSH)
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	InputMap.action_add_event(ACTION_PUSH, space)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event(ACTION_PUSH, click)


func _prepare() -> void:
	profile = CourseProfile.new(tuning)
	model = RunnerModel.new(tuning, profile)
	model.assist_level = assist_level
	effort_input = EffortFactory.create(tuning)
	var key: int = tuning.to_text().hash()
	if par_bot == null or key != _par_key:
		par_bot = ParBot.build(tuning)  # about 6000 simulated ticks, rebuilt only when a tuning value changed
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
	_cam_ready = false
	last_result = null
	_set_phase(RunState.Phase.READY)
	_update_views(0.0)
	_refresh_hud(0.0)


func _set_phase(p: int) -> void:
	phase = p
	_hud.set_phase(p, last_result)


func _start_countdown() -> void:
	_countdown_left = countdown_seconds
	_set_phase(RunState.Phase.COUNTDOWN)


func _begin_run() -> void:
	effort_input.reset()
	_effort_avg = effort_input.effort
	_push_held = Input.is_action_pressed(ACTION_PUSH) and not _press_blocked
	_acc = 0.0
	_set_phase(RunState.Phase.RUNNING)


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_PUSH):
		if _is_over_ui(event):
			_press_blocked = true  # a tap on a button or the debug panel is not "push"
		else:
			_press_blocked = false
			_on_push_pressed()
	elif event.is_action_released(ACTION_PUSH):
		_push_held = false
		_press_blocked = false
	elif event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.keycode == KEY_P):
			toggle_pause()


func _is_over_ui(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton):
		return false
	var mouse: InputEventMouseButton = event
	return _hud.is_point_over_ui(mouse.position) or _debug.is_point_over_ui(mouse.position)


func _on_push_pressed() -> void:
	if phase == RunState.Phase.READY:
		_start_countdown()
	elif phase == RunState.Phase.RUNNING:
		_push_held = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_push_held = false
		if phase == RunState.Phase.RUNNING or phase == RunState.Phase.COUNTDOWN:
			toggle_pause()


func _on_window_resized() -> void:
	var win_size: Vector2i = get_window().size
	var portrait: bool = win_size.y > win_size.x
	_hud.set_portrait(portrait)
	if portrait and (phase == RunState.Phase.RUNNING or phase == RunState.Phase.COUNTDOWN):
		toggle_pause()


func _on_quit_pressed() -> void:
	quit_requested.emit()


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	var frame: float = minf(delta, MAX_FRAME)
	if phase == RunState.Phase.COUNTDOWN:
		_countdown_left -= frame
		if _countdown_left <= 0.0:
			_begin_run()
	elif phase == RunState.Phase.RUNNING:
		_acc += frame
		while _acc >= DT and phase == RunState.Phase.RUNNING:
			_sim_tick()
			_acc -= DT
		_alpha = _acc / DT if phase == RunState.Phase.RUNNING else 1.0
	_update_views(frame)
	_refresh_hud(frame)


func _sim_tick() -> void:
	var progress: float = clampf(model.progress(), 0.0, 1.0)
	var effort: float = effort_input.update(DT, _push_held, progress)
	_effort_avg += (effort - _effort_avg) * _avg_k

	# water station: letting go inside the zone takes the cup
	if model.in_station() and not _push_held:
		_release_timer += DT
		if _release_timer >= tuning.water_release_delay:
			model.request_drink()
	else:
		_release_timer = 0.0

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
	var sim: RunnerModel = model.clone()
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
	var result := RunResult.new()
	result.attempt = attempt
	result.walls_hit = model.walls_hit
	result.par_time = par_time
	result.input_mode = int(tuning.input_mode)
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
	_set_phase(RunState.Phase.FINISHED)
	run_finished.emit(result)


# ---------------------------------------------------------------- views

func _visual_time() -> float:
	if phase == RunState.Phase.RUNNING:
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
	var s: HudState = _hud_state
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
	s.ghost_progress = minf(par_bot.position_at(_visual_time()), tuning.track_length) / tuning.track_length
	s.has_delta = phase == RunState.Phase.RUNNING and model.pos > 50.0
	if s.has_delta:
		s.delta_vs_par = par_bot.time_at(model.pos) - model.elapsed
	_hud.refresh(delta, s)
	_debug.refresh(s)


func _copy_log() -> void:
	DisplayServer.clipboard_set(build_log_text())
