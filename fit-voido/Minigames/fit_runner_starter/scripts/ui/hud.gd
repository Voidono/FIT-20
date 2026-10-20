class_name Hud
extends CanvasLayer
## Player-facing UI. Layout, art and theme live in hud.tscn and the scenes it instances (stamina_bar, effort_gauge,
## progress_strip, pause_menu, result_panel...). This script feeds them values and shows or hides panels.
## Everything the player must read sits in the centre 60%: the Row container splits 1 : 3 : 1.

signal pause_pressed
signal resume_pressed
signal retry_pressed
signal quit_pressed

@onready var _time_label: Label = Lookup.node(self, "TimeLabel") as Label
@onready var _zone_icon: TextureRect = Lookup.node(self, "ZoneIcon") as TextureRect
@onready var _zone_label: Label = Lookup.node(self, "ZoneLabel") as Label
@onready var _delta_label: Label = Lookup.node(self, "DeltaLabel") as Label
@onready var _stamina_bar: StaminaBar = Lookup.node(self, "StaminaBar") as StaminaBar
@onready var _effort_gauge: EffortGauge = Lookup.node(self, "EffortGauge") as EffortGauge
@onready var _outlook_label: Label = Lookup.node(self, "OutlookLabel") as Label
@onready var _progress: ProgressStrip = Lookup.node(self, "ProgressStrip") as ProgressStrip
@onready var _prompt: Label = Lookup.node(self, "PromptLabel") as Label
@onready var _ready_overlay: Control = Lookup.node(self, "ReadyOverlay") as Control
@onready var _countdown: Label = Lookup.node(self, "CountdownLabel") as Label
@onready var _pause_button: Button = Lookup.node(self, "PauseButton") as Button
@onready var _pause_menu: PauseMenu = Lookup.node(self, "PauseMenu") as PauseMenu
@onready var _result_panel: ResultPanel = Lookup.node(self, "ResultPanel") as ResultPanel
@onready var _rotate_overlay: Control = Lookup.node(self, "RotateOverlay") as Control
@onready var _zones: Node = Lookup.node(self, "Zones") as Node
@onready var _qte_prompt: QtePrompt = Lookup.node(self, "QtePrompt") as QtePrompt

var _blink: float = 0.0
var _last_zone: int = -1
var _last_outlook: int = -1
var _last_ahead: bool = true


func _ready() -> void:
	set_phase(RunState.Phase.READY, null)


func configure(tuning: RunnerTuning, profile: CourseProfile) -> void:
	_progress.configure(tuning, profile)


func set_phase(phase: int, result: RunResult) -> void:
	var is_ready: bool = phase == RunState.Phase.READY
	var counting: bool = phase == RunState.Phase.COUNTDOWN
	_pause_button.visible = counting or phase == RunState.Phase.RUNNING
	_pause_menu.visible = phase == RunState.Phase.PAUSED
	_result_panel.visible = phase == RunState.Phase.FINISHED
	_ready_overlay.visible = is_ready
	_countdown.visible = counting
	if phase == RunState.Phase.FINISHED and result != null:
		_result_panel.show_result(result)


func set_portrait(is_portrait: bool) -> void:
	_rotate_overlay.visible = is_portrait


## True when a point is on something clickable, so the runner does not treat that tap as "push".
func is_point_over_ui(pos: Vector2) -> bool:
	for c: Control in [_pause_button, _pause_menu, _result_panel]:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


func refresh(delta: float, s: HudState) -> void:
	var m: RunnerModel = s.model
	var t: RunnerTuning = s.tuning
	if m == null or t == null:
		return
	_blink += delta
	var running: bool = s.phase == RunState.Phase.RUNNING
	_time_label.text = Fmt.time(m.elapsed)

	var zone: int = Zones.for_pace(m.pace, m.walled)
	var style: ZoneStyle = _style(zone)
	if zone != _last_zone and style != null:
		_last_zone = zone
		_zone_label.text = style.label_key  # a translation key: the Label translates it, also when the language changes
		_zone_icon.texture = style.icon
		_zone_label.add_theme_color_override("font_color", style.color)

	if running and s.has_delta:
		var ahead: bool = s.delta_vs_par >= 0.0
		_delta_label.text = Fmt.signed(s.delta_vs_par)
		if ahead != _last_ahead:
			_last_ahead = ahead
			_delta_label.add_theme_color_override("font_color", _style(Zones.Id.CRUISE).color if ahead else _style(Zones.Id.SPRINT).color)
	else:
		_delta_label.text = ""

	_stamina_bar.apply(m.stamina / t.stamina_max, style, m.walled, t.wall_release / t.stamina_max, _blink)
	var band_hi: float = lerpf(t.band_hi_start, t.band_hi_end, clampf(m.progress(), 0.0, 1.0))
	_effort_gauge.apply(s.effort, m.pace, t.band_lo, band_hi, t.input_mode == RunnerTuning.InputMode.TIERS, t.tier_values)
	_progress.apply(m.progress(), s.ghost_progress)
	_qte_prompt.apply(s.qte_phase, s.qte_cursor, s.runner_screen_pos)

	if running and m.progress() < 0.97:
		if s.outlook != _last_outlook:
			_last_outlook = s.outlook
			var outlook_zone: int = Zones.Id.CRUISE
			if s.outlook == 2:
				outlook_zone = Zones.Id.SPRINT
			elif s.outlook == 1:
				outlook_zone = Zones.Id.PUSH
			_outlook_label.add_theme_color_override("font_color", _style(outlook_zone).color)
		if s.outlook == 2:
			_outlook_label.text = "OUTLOOK_WALL"
		elif s.outlook == 1:
			_outlook_label.text = "OUTLOOK_TIGHT"
		else:
			_outlook_label.text = tr("OUTLOOK_OK") % int(s.outlook_stamina)
	else:
		_outlook_label.text = ""

	if s.phase == RunState.Phase.COUNTDOWN:
		_countdown.text = str(maxi(ceili(s.countdown_left), 1))

	var prompt: String = ""
	if running:
		if m.elapsed < 0.8:
			prompt = "COUNT_GO"
		elif m.walled:
			prompt = "WALL_PROMPT"
		elif m.drinking:
			prompt = "DRINKING"
		elif m.in_station():
			prompt = "WATER_PROMPT"
		elif m.in_spurt() and m.progress() < t.spurt_start + 0.03:
			prompt = "SPURT_BANNER"
	_prompt.text = prompt  # keys again, translated by the Label


## Connected from the QteController in fit_runner.tscn.
func on_qte_started(target_center: float, perfect_width: float, good_width: float) -> void:
	_qte_prompt.begin(target_center, perfect_width, good_width)


func on_qte_resolved(grade: int, bonus: float, _streak: int) -> void:
	_qte_prompt.show_result(grade, bonus)


func on_qte_cancelled() -> void:
	_qte_prompt.visible = false


func _style(zone: int) -> ZoneStyle:
	return _zones.get_child(clampi(zone, 0, _zones.get_child_count() - 1)) as ZoneStyle


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
