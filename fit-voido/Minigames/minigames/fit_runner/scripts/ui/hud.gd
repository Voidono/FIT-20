class_name FrHud
extends CanvasLayer
## Player-facing UI. Layout, art and theme live in hud.tscn and the scenes it instances (stamina_bar, effort_gauge,
## progress_strip, pause_menu, result_panel...). This script feeds them values and shows or hides panels.
## Everything the player must read sits in the centre 60%: the Row container splits 1 : 3 : 1.

const FrRunnerTouchButton = preload("runner_touch_button.gd")

signal pause_pressed
signal resume_pressed
signal retry_pressed
signal quit_pressed
signal speed_button_down
signal speed_button_up
signal qte_button_pressed
signal mode_selected(mode: int)

const CIRCUIT_MAP = preload("circuit_map.gd")
var _map: Control
var _race_info: Label
var _mode_buttons: Array[Button] = []
var _mode: int = 0

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
@onready var _speed_button: FrRunnerTouchButton = FrLookup.node(self, "SpeedButton") as FrRunnerTouchButton
@onready var _qte_button: FrRunnerTouchButton = FrLookup.node(self, "QteButton") as FrRunnerTouchButton

var _blink: float = 0.0
var _last_zone: int = -1
var _last_outlook: int = -1
var _last_ahead: bool = true


func _ready() -> void:
	_build_race_ui()
	set_phase(FrRunState.Phase.READY, null)
	_update_button_texts()
	_apply_device_ui()
	_result_panel.mode_menu_requested.connect(func() -> void: mode_selected.emit(_mode))


func _build_race_ui() -> void:
	var root: Control = get_node("Root")
	var theme: Theme = root.theme.duplicate(true)
	var normal := _panel_style(Color("153b33"), Color("416357"))
	var hover := _panel_style(Color("315c43"), Color("d7f59a"))
	var pressed := _panel_style(Color("4b6b3d"), Color("d7f59a"))
	theme.set_stylebox("panel", "PanelContainer", _panel_style(Color("102c28"), Color("628166")))
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, normal)
		theme.set_stylebox("hover", type, hover)
		theme.set_stylebox("pressed", type, pressed)
		theme.set_stylebox("focus", type, hover)
	theme.set_constant("outline_size", "Label", 0)
	root.theme = theme
	_ready_overlay.reparent(root)
	_ready_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ready_overlay.offset_left = -205
	_ready_overlay.offset_right = 205
	_ready_overlay.offset_top = -112
	_ready_overlay.offset_bottom = 112
	var ready_box := _ready_overlay.get_node("VBox") as VBoxContainer
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	ready_box.add_child(modes)
	ready_box.move_child(modes, 2)
	for i in range(2):
		var button := Button.new()
		button.text = "FR_MODE_PRACTICE" if i == 0 else "FR_MODE_RACE"
		button.custom_minimum_size = Vector2(0, 38)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: mode_selected.emit(i))
		modes.add_child(button)
		_mode_buttons.append(button)
	_map = CIRCUIT_MAP.new()
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_map.offset_left = -92
	_map.offset_right = 92
	_map.offset_top = -100
	_map.offset_bottom = -30
	root.add_child(_map)
	_race_info = Label.new()
	_race_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_race_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_race_info.add_theme_font_size_override("font_size", 12)
	_race_info.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_race_info.offset_left = -180
	_race_info.offset_right = 180
	_race_info.offset_top = -122
	_race_info.offset_bottom = -102
	_race_info.add_theme_color_override("font_color", Color("ecf5d4"))
	_race_info.add_theme_color_override("font_outline_color", Color("102c28"))
	_race_info.add_theme_constant_override("outline_size", 4)
	root.add_child(_race_info)
	_progress.hide()
	var title := ready_box.get_node("StoryLabel") as Label
	title.text = "FR_CIRCUIT_TITLE"
	title.add_theme_font_size_override("font_size", 20)
	ready_box.get_node("Logo").hide()
	var top: Control = get_node("Root/Margin/Row/Center/Top")
	var center: Control = top.get_parent()
	var scoreboard := PanelContainer.new()
	scoreboard.name = "Scoreboard"
	scoreboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(scoreboard)
	center.move_child(scoreboard, 0)
	top.reparent(scoreboard)
	for key in ["FR_ENERGY_METER", "FR_EFFORT_METER"]:
		var caption := Label.new()
		caption.text = key
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_size_override("font_size", 10)
		caption.add_theme_color_override("font_color", Color("9fb6a6"))
		top.add_child(caption)
		top.move_child(caption, _stamina_bar.get_index() if key == "FR_ENERGY_METER" else _effort_gauge.get_index())


func _panel_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func configure_mode(mode: int) -> void:
	_mode = mode
	for i in range(_mode_buttons.size()):
		_mode_buttons[i].modulate = Color("dcff98") if i == mode else Color("a8bbae")
	_ready_overlay.get_node("VBox/HowLabel").text = "FR_PRACTICE_BRIEF" if mode == 0 else "FR_RACE_BRIEF"


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_button_texts()


## Hide/show touch buttons based on device. Called once in _ready().
## On PC: buttons are hidden, a keyboard hint label is shown instead.
## On mobile: buttons remain visible (their default state).
func _apply_device_ui() -> void:
	var on_mobile: bool = _is_mobile()
	if _speed_button != null:
		_speed_button.visible = on_mobile
	if _qte_button != null:
		_qte_button.visible = on_mobile
	if not on_mobile:
		_spawn_keyboard_hint()


func _is_mobile() -> bool:
	var device := get_node_or_null("/root/DeviceInput")
	return bool(device.call("is_mobile")) if device != null else OS.has_feature("mobile")


func _spawn_keyboard_hint() -> void:
	var label := Label.new()
	label.text = "Space / W / Up Arrow : Push   |   Enter / J / Down Arrow : QTE   |   Esc / P: Pause"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_top = -28.0
	label.offset_bottom = -6.0
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Walk up to the CanvasLayer's root Control to add the hint there
	var root: Control = get_node_or_null("Root")
	if root != null:
		root.add_child(label)
	else:
		add_child(label)


func _update_button_texts() -> void:
	if _speed_button != null:
		_speed_button.set_texts(tr("FR_BTN_SPEED"), tr("FR_BTN_SPEED_SUB"))
	if _qte_button != null:
		_qte_button.set_texts(tr("FR_BTN_QTE"), tr("FR_BTN_QTE_SUB"))
		_qte_button.qte_active_title = tr("FR_BTN_QTE_ACTIVE_TITLE")
		_qte_button.qte_active_sub = tr("FR_BTN_QTE_ACTIVE_SUB")


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
	get_node("Root/Margin/Row/Center/Scoreboard").visible = counting or running or phase == FrRunState.Phase.PAUSED
	if _map != null:
		_map.visible = counting or running
		_race_info.visible = _map.visible
	## Touch buttons only shown on mobile AND during active phases.
	var on_mobile: bool = _is_mobile()
	if _speed_button != null:
		_speed_button.visible = on_mobile and (is_ready or counting or running)
	if _qte_button != null:
		_qte_button.visible = on_mobile and (is_ready or counting or running)
	if phase == FrRunState.Phase.FINISHED and result != null:
		_result_panel.show_result(result)


func set_portrait(is_portrait: bool) -> void:
	_rotate_overlay.visible = is_portrait


## True when a point is on something clickable, so the runner does not treat that tap as "push".
func is_point_over_ui(pos: Vector2) -> bool:
	var ui_elements: Array[Control] = [_pause_button, _pause_menu, _result_panel]
	ui_elements.append_array(_mode_buttons)
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
	var lap: int = mini(2, int(m.progress() * 2.0) + 1)
	_race_info.text = tr("FR_RACE_INFO") % [lap, int(clampf(m.progress(), 0, 1) * t.track_length / 10.0)]
	_map.update_race(m.progress(), s.rival_progress)

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
	if s.race_mode == 1:
		_delta_label.text = tr("FR_POSITION") % [s.placement, 6]
		_delta_label.add_theme_color_override("font_color", Color("dcff98"))

	_stamina_bar.apply(m.stamina / t.stamina_max, style, m.walled, t.wall_release / t.stamina_max, _blink)
	var band_hi: float = lerpf(t.band_hi_start, t.band_hi_end, clampf(m.progress(), 0.0, 1.0))
	_effort_gauge.apply(s.effort, m.pace, t.band_lo, band_hi, t.input_mode == FrTuning.InputMode.TIERS, t.tier_values)
	_progress.apply(m.progress(), s.ghost_progress)
	_qte_prompt.apply(s.qte_phase, s.qte_cursor, s.runner_screen_pos)
	_qte_prompt.visible = running and s.qte_phase != FrQteController.Phase.IDLE

	if _qte_button != null:
		_qte_button.set_qte_active(running and s.qte_phase == 1)

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
		elif m.progress() >= 0.5 and m.progress() < 0.52:
			prompt = "FR_FINAL_LAP"
		elif t.water_amount > 0 and m.in_station():
			prompt = "FR_WATER_PROMPT"
		elif m.in_spurt() and m.progress() < t.spurt_start + 0.03:
			prompt = "FR_SPURT_BANNER"
	_prompt.text = prompt  # keys again, translated by the Label
	if running and s.race_mode == 0 and prompt == "":
		if s.qte_phase == 1:
			_prompt.text = "FR_COACH_QTE"
		elif m.elapsed < 7:
			_prompt.text = "FR_COACH_PUSH"
		elif m.stamina < 35:
			_prompt.text = "FR_COACH_REST"
		elif m.in_spurt():
			_prompt.text = "FR_COACH_FINISH"
		else:
			_prompt.text = "FR_COACH_PACE"


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
