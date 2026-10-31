class_name FrHud
extends CanvasLayer
## Player-facing UI. Layout, art and theme live in hud.tscn and the scenes it instances (stamina_bar, effort_gauge,
## progress_strip, pause_menu, result_panel...). This script feeds them values and shows or hides panels.
## Everything the player must read sits in the centre 60%: the Row container splits 1 : 3 : 1.

signal pause_pressed
signal resume_pressed
signal retry_pressed
signal quit_pressed
signal speed_button_down
signal speed_button_up
signal qte_button_pressed

@onready var _time_label: Label = FrLookup.node(self, "TimeLabel") as Label
@onready var _zone_icon: TextureRect = FrLookup.node(self, "ZoneIcon") as TextureRect
@onready var _zone_label: Label = FrLookup.node(self, "ZoneLabel") as Label
@onready var _delta_label: Label = FrLookup.node(self, "DeltaLabel") as Label
@onready var _stamina_bar: FrStaminaBar = FrLookup.node(self, "StaminaBar") as FrStaminaBar
@onready var _effort_gauge: FrEffortGauge = FrLookup.node(self, "EffortGauge") as FrEffortGauge
@onready var _outlook_label: Label = FrLookup.node(self, "OutlookLabel") as Label
@onready var _progress: FrProgressStrip = FrLookup.node(self, "ProgressStrip") as FrProgressStrip
@onready var _prompt: Label = FrLookup.node(self, "PromptLabel") as Label
@onready var _ready_overlay: Control = FrLookup.node(self, "ReadyOverlay") as Control
@onready var _countdown: Label = FrLookup.node(self, "CountdownLabel") as Label
@onready var _pause_button: Button = FrLookup.node(self, "PauseButton") as Button
@onready var _pause_menu: FrPauseMenu = FrLookup.node(self, "PauseMenu") as FrPauseMenu
@onready var _result_panel: FrResultPanel = FrLookup.node(self, "ResultPanel") as FrResultPanel
@onready var _rotate_overlay: Control = FrLookup.node(self, "RotateOverlay") as Control
@onready var _zones: Node = FrLookup.node(self, "Zones") as Node
@onready var _qte_prompt: FrQtePrompt = FrLookup.node(self, "QtePrompt") as FrQtePrompt
@onready var _speed_button: Button = FrLookup.node(self, "SpeedButton") as Button
@onready var _qte_button: Button = FrLookup.node(self, "QteButton") as Button

var _blink: float = 0.0
var _last_zone: int = -1
var _last_outlook: int = -1
var _last_ahead: bool = true


func _ready() -> void:
	set_phase(FrRunState.Phase.READY, null)


func configure(tuning: FrTuning, profile: FrCourseProfile) -> void:
	_progress.configure(tuning, profile)


func set_phase(phase: int, result: FitRunnerResult) -> void:
	var is_ready: bool = phase == FrRunState.Phase.READY
	var counting: bool = phase == FrRunState.Phase.COUNTDOWN
	var running: bool = phase == FrRunState.Phase.RUNNING
	_pause_button.visible = counting or running
	_pause_menu.visible = phase == FrRunState.Phase.PAUSED
	_result_panel.visible = phase == FrRunState.Phase.FINISHED
	_ready_overlay.visible = is_ready
	_countdown.visible = counting
	if _speed_button != null:
		_speed_button.visible = counting or running
	if _qte_button != null:
		_qte_button.visible = running
	if phase == FrRunState.Phase.FINISHED and result != null:
		_result_panel.show_result(result)


func set_portrait(is_portrait: bool) -> void:
	_rotate_overlay.visible = is_portrait


## True when a point is on something clickable, so the runner does not treat that tap as "push".
func is_point_over_ui(pos: Vector2) -> bool:
	var ui_elements: Array[Control] = [_pause_button, _pause_menu, _result_panel]
	if _speed_button != null:
		ui_elements.append(_speed_button)
	if _qte_button != null:
		ui_elements.append(_qte_button)
	for c: Control in ui_elements:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


func refresh(delta: float, s: FrHudState) -> void:
	var m: FrModel = s.model
	var t: FrTuning = s.tuning
	if m == null or t == null:
		return
	_blink += delta
	var running: bool = s.phase == FrRunState.Phase.RUNNING
	_time_label.text = FrFmt.time(m.elapsed)

	var zone: int = FrZones.for_pace(m.pace, m.walled)
	var style: FrZoneStyle = _style(zone)
	if zone != _last_zone and style != null:
		_last_zone = zone
		_zone_label.text = style.label_key  # a translation key: the Label translates it, also when the language changes
		_zone_icon.texture = style.icon
		_zone_label.add_theme_color_override("font_color", style.color)

	if running and s.has_delta:
		var ahead: bool = s.delta_vs_par >= 0.0
		_delta_label.text = FrFmt.signed(s.delta_vs_par)
		if ahead != _last_ahead:
			_last_ahead = ahead
			_delta_label.add_theme_color_override("font_color", _style(FrZones.Id.CRUISE).color if ahead else _style(FrZones.Id.SPRINT).color)
	else:
		_delta_label.text = ""

	_stamina_bar.apply(m.stamina / t.stamina_max, style, m.walled, t.wall_release / t.stamina_max, _blink)
	var band_hi: float = lerpf(t.band_hi_start, t.band_hi_end, clampf(m.progress(), 0.0, 1.0))
	_effort_gauge.apply(s.effort, m.pace, t.band_lo, band_hi, t.input_mode == FrTuning.InputMode.TIERS, t.tier_values)
	_progress.apply(m.progress(), s.ghost_progress)
	_qte_prompt.apply(s.qte_phase, s.qte_cursor, s.runner_screen_pos)

	if running and _qte_button != null:
		if s.qte_phase == 1:  # ACTIVE
			_qte_button.modulate = Color(1.0, 0.95, 0.2, 1.0) if fmod(_blink, 0.3) < 0.15 else Color.WHITE
		else:
			_qte_button.modulate = Color(0.85, 0.85, 0.9, 0.8)

	if running and m.progress() < 0.97:
		if s.outlook != _last_outlook:
			_last_outlook = s.outlook
			var outlook_zone: int = FrZones.Id.CRUISE
			if s.outlook == 2:
				outlook_zone = FrZones.Id.SPRINT
			elif s.outlook == 1:
				outlook_zone = FrZones.Id.PUSH
			_outlook_label.add_theme_color_override("font_color", _style(outlook_zone).color)
		if s.outlook == 2:
			_outlook_label.text = "FR_OUTLOOK_WALL"
		elif s.outlook == 1:
			_outlook_label.text = "FR_OUTLOOK_TIGHT"
		else:
			_outlook_label.text = tr("FR_OUTLOOK_OK") % int(s.outlook_stamina)
	else:
		_outlook_label.text = ""

	if s.phase == FrRunState.Phase.COUNTDOWN:
		_countdown.text = str(maxi(ceili(s.countdown_left), 1))

	var prompt: String = ""
	if running:
		if m.elapsed < 0.8:
			prompt = "FR_COUNT_GO"
		elif m.walled:
			prompt = "FR_WALL_PROMPT"
		elif m.drinking:
			prompt = "FR_DRINKING"
		elif m.in_station():
			prompt = "FR_WATER_PROMPT"
		elif m.in_spurt() and m.progress() < t.spurt_start + 0.03:
			prompt = "FR_SPURT_BANNER"
	_prompt.text = prompt  # keys again, translated by the Label


## Connected from the FrQteController in fit_runner.tscn.
func on_qte_started(target_center: float, perfect_width: float, good_width: float) -> void:
	_qte_prompt.begin(target_center, perfect_width, good_width)


func on_qte_resolved(grade: int, bonus: float, _streak: int, boost_mult: float = 1.0, _boost_dur: float = 0.0) -> void:
	_qte_prompt.show_result(grade, bonus, boost_mult > 1.0)


func on_qte_cancelled() -> void:
	_qte_prompt.visible = false


func _style(zone: int) -> FrZoneStyle:
	return _zones.get_child(clampi(zone, 0, _zones.get_child_count() - 1)) as FrZoneStyle


func _on_speed_button_down() -> void:
	speed_button_down.emit()


func _on_speed_button_up() -> void:
	speed_button_up.emit()


func _on_qte_button_pressed() -> void:
	qte_button_pressed.emit()


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
