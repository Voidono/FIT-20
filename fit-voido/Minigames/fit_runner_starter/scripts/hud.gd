class_name Hud
extends CanvasLayer
## Player-facing UI. Everything the player must read sits in the centre 60% of the screen:
## the top box, the progress strip and the messages all use anchors 0.2 - 0.8.

signal pause_pressed
signal resume_pressed
signal retry_pressed
signal quit_pressed

var _root: Control
var _time_label: Label
var _zone_label: Label
var _delta_label: Label
var _stamina_bar: StaminaBar
var _effort_gauge: EffortGauge
var _outlook_label: Label
var _progress: ProgressTrack
var _message: Label
var _prompt: Label
var _logo_rect: TextureRect
var _pause_button: Button
var _pause_menu: PanelContainer
var _result_panel: PanelContainer
var _result_title: Label
var _result_stars: Label
var _result_lines: Label
var _result_hint: Label
var _stone: StoneGem
var _result_quit: Button
var _rotate_overlay: ColorRect
var _phase: int = RunState.Phase.READY
var _blink: float = 0.0
var _last_zone: int = -1
var _last_outlook: int = -1
var _last_ahead: bool = true


func _ready() -> void:
	Strings.install()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.build_theme()
	add_child(_root)
	_build_top()
	_build_bottom()
	_build_center()
	_build_pause()
	_build_result()
	_build_rotate()
	set_phase(RunState.Phase.READY, null)


# ---------------------------------------------------------------- building

func _make_label(text: String, font_size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(key: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = Strings.t(key)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0.0, 36.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_pressed)
	return button


func _center_panel(c: Control, w: float, h: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = -w * 0.5
	c.offset_right = w * 0.5
	c.offset_top = -h * 0.5
	c.offset_bottom = h * 0.5


func _build_top() -> void:
	var top := VBoxContainer.new()
	top.anchor_left = 0.2
	top.anchor_right = 0.8
	top.offset_top = 8.0
	top.offset_bottom = 8.0
	top.add_theme_constant_override("separation", 3)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)
	_time_label = _make_label("00:00.0", 20, HORIZONTAL_ALIGNMENT_LEFT)
	_zone_label = _make_label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	_delta_label = _make_label("", 16, HORIZONTAL_ALIGNMENT_RIGHT)
	_delta_label.add_theme_color_override("font_color", UiTheme.ZONE_CRUISE)
	for label: Label in [_time_label, _zone_label, _delta_label]:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

	_stamina_bar = StaminaBar.new()
	top.add_child(_stamina_bar)
	_effort_gauge = EffortGauge.new()
	top.add_child(_effort_gauge)
	_outlook_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER)
	top.add_child(_outlook_label)


func _build_bottom() -> void:
	_progress = ProgressTrack.new()
	_progress.anchor_left = 0.2
	_progress.anchor_right = 0.8
	_progress.anchor_top = 1.0
	_progress.anchor_bottom = 1.0
	_progress.offset_top = -40.0
	_progress.offset_bottom = -8.0
	_root.add_child(_progress)


func _build_center() -> void:
	_prompt = _make_label("", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.anchor_left = 0.2
	_prompt.anchor_right = 0.8
	_prompt.anchor_top = 0.26
	_prompt.anchor_bottom = 0.34
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_root.add_child(_prompt)

	_message = _make_label("", 18, HORIZONTAL_ALIGNMENT_CENTER)
	_message.anchor_left = 0.2
	_message.anchor_right = 0.8
	_message.anchor_top = 0.40
	_message.anchor_bottom = 0.72
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_message)

	var logo: Texture2D = UiTheme.logo()
	if logo != null:
		_logo_rect = TextureRect.new()
		_logo_rect.texture = logo
		_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo_rect.anchor_left = 0.4
		_logo_rect.anchor_right = 0.6
		_logo_rect.anchor_top = 0.14
		_logo_rect.anchor_bottom = 0.38
		_logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(_logo_rect)

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -48.0
	_pause_button.offset_right = -8.0
	_pause_button.offset_top = 8.0
	_pause_button.offset_bottom = 48.0
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_root.add_child(_pause_button)


func _build_pause() -> void:
	_pause_menu = PanelContainer.new()
	_center_panel(_pause_menu, 220.0, 170.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_pause_menu.add_child(box)
	box.add_child(_make_label(Strings.t("PAUSE_TITLE"), 20, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_button("BTN_RESUME", func() -> void: resume_pressed.emit()))
	box.add_child(_make_button("BTN_RESTART", func() -> void: retry_pressed.emit()))
	box.add_child(_make_button("BTN_QUIT", func() -> void: quit_pressed.emit()))
	_root.add_child(_pause_menu)


func _build_result() -> void:
	_result_panel = PanelContainer.new()
	_center_panel(_result_panel, 320.0, 250.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_result_panel.add_child(box)
	_result_title = _make_label("", 24, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_result_title)
	_result_stars = _make_label("", 28, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_result_stars)
	_result_lines = _make_label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_result_lines)
	_stone = StoneGem.new()
	_stone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_stone)
	_result_hint = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER)
	_result_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_result_hint)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	buttons.add_child(_make_button("BTN_RESTART", func() -> void: retry_pressed.emit()))
	_result_quit = _make_button("BTN_CONTINUE", func() -> void: quit_pressed.emit())
	buttons.add_child(_result_quit)
	_root.add_child(_result_panel)


func _build_rotate() -> void:
	_rotate_overlay = ColorRect.new()
	_rotate_overlay.color = Color(UiTheme.INK, 0.96)
	_rotate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rotate_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := _make_label(Strings.t("ROTATE"), 22, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rotate_overlay.add_child(label)
	_rotate_overlay.visible = false
	_root.add_child(_rotate_overlay)


# ---------------------------------------------------------------- state

func set_phase(phase: int, result: RunResult) -> void:
	_phase = phase
	var counting: bool = phase == RunState.Phase.COUNTDOWN
	var is_ready: bool = phase == RunState.Phase.READY
	_pause_button.visible = counting or phase == RunState.Phase.RUNNING
	_pause_menu.visible = phase == RunState.Phase.PAUSED
	_result_panel.visible = phase == RunState.Phase.FINISHED
	_message.visible = is_ready or counting
	if _logo_rect != null:
		_logo_rect.visible = is_ready or phase == RunState.Phase.FINISHED
	if is_ready:
		_message.add_theme_font_size_override("font_size", 18)
		_message.text = "%s\n\n%s\n%s" % [Strings.t("STORY_READY"), Strings.t("PROMPT_HOW"), Strings.t("PROMPT_READY")]
	elif counting:
		_message.add_theme_font_size_override("font_size", 44)
	if phase == RunState.Phase.FINISHED and result != null:
		_fill_result(result)


func set_portrait(is_portrait: bool) -> void:
	_rotate_overlay.visible = is_portrait


func _fill_result(r: RunResult) -> void:
	_result_title.text = Strings.t("RESULT_PASS") if r.passed else Strings.t("RESULT_FAIL")
	var stars: String = ""
	for i in range(3):
		stars += "★" if i < r.stars else "☆"
	_result_stars.text = stars if r.passed else ""
	var lines: PackedStringArray = []
	lines.append(Strings.t("RESULT_TIME") % UiTheme.format_time(r.time_sec))
	lines.append(Strings.t("RESULT_PAR") % UiTheme.format_time(r.par_time))
	lines.append(Strings.t("RESULT_WALLS") % r.walls_hit)
	_result_lines.text = "\n".join(lines)
	_stone.visible = r.passed
	_result_hint.text = Strings.t("STONE_GOT") if r.passed else Strings.t("FAIL_HINT")
	_result_quit.text = Strings.t("BTN_CONTINUE") if r.passed else Strings.t("BTN_QUIT")


## True when a screen point is on something clickable, so the runner doesn't treat it as "push".
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
	var running: bool = _phase == RunState.Phase.RUNNING
	_time_label.text = UiTheme.format_time(m.elapsed)

	var zone: int = UiTheme.zone_for(m.pace, m.walled)
	_zone_label.text = "%s %s" % [UiTheme.ZONE_GLYPHS[zone], Strings.t(UiTheme.ZONE_KEYS[zone])]
	if zone != _last_zone:
		_last_zone = zone
		_zone_label.add_theme_color_override("font_color", UiTheme.zone_color(zone))

	if running and s.has_delta:
		var d: float = s.delta_vs_par
		var ahead: bool = d >= 0.0
		_delta_label.text = ("+" if ahead else "-") + "%.1f" % absf(d)
		if ahead != _last_ahead:
			_last_ahead = ahead
			_delta_label.add_theme_color_override("font_color", UiTheme.ZONE_CRUISE if ahead else UiTheme.ZONE_SPRINT)
	else:
		_delta_label.text = ""

	_stamina_bar.value = m.stamina / t.stamina_max
	_stamina_bar.zone = zone
	_stamina_bar.walled = m.walled
	_stamina_bar.exit_mark = t.wall_release / t.stamina_max
	_stamina_bar.blink = _blink
	_stamina_bar.queue_redraw()

	_effort_gauge.effort = s.effort
	_effort_gauge.pace = m.pace
	_effort_gauge.band_lo = t.band_lo
	_effort_gauge.band_hi = lerpf(t.band_hi_start, t.band_hi_end, clampf(m.progress(), 0.0, 1.0))
	_effort_gauge.tiers_mode = t.input_mode == RunnerTuning.InputMode.TIERS
	_effort_gauge.tier_values = t.tier_values
	_effort_gauge.queue_redraw()

	_progress.tuning = t
	_progress.course = m.course
	_progress.player_progress = m.progress()
	_progress.ghost_progress = s.ghost_progress
	_progress.queue_redraw()

	if running and m.progress() < 0.97:
		if s.outlook != _last_outlook:
			_last_outlook = s.outlook
			if s.outlook == 2:
				_outlook_label.add_theme_color_override("font_color", UiTheme.ZONE_SPRINT)
			elif s.outlook == 1:
				_outlook_label.add_theme_color_override("font_color", UiTheme.ZONE_PUSH)
			else:
				_outlook_label.add_theme_color_override("font_color", UiTheme.ZONE_CRUISE)
		if s.outlook == 2:
			_outlook_label.text = Strings.t("OUTLOOK_WALL")
		elif s.outlook == 1:
			_outlook_label.text = Strings.t("OUTLOOK_TIGHT")
		else:
			_outlook_label.text = Strings.t("OUTLOOK_OK") % int(s.outlook_stamina)
	else:
		_outlook_label.text = ""

	if _phase == RunState.Phase.COUNTDOWN:
		_message.text = str(maxi(ceili(s.countdown_left), 1))

	var prompt: String = ""
	if running:
		if m.elapsed < 0.8:
			prompt = Strings.t("COUNT_GO")
		elif m.walled:
			prompt = Strings.t("WALL_PROMPT")
		elif m.drinking:
			prompt = Strings.t("DRINKING")
		elif m.in_station():
			prompt = Strings.t("WATER_PROMPT")
		elif m.in_spurt() and m.progress() < t.spurt_start + 0.03:
			prompt = Strings.t("SPURT_BANNER")
	_prompt.text = prompt


## Small diamond shown on the results screen when the Time Stone is earned (placeholder art).
class StoneGem extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(36.0, 36.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.45
		draw_circle(c, r * 1.2, Color(UiTheme.ZONE_RECOVER, 0.25))
		var pts := PackedVector2Array([c + Vector2(0.0, -r), c + Vector2(r * 0.8, 0.0), c + Vector2(0.0, r), c + Vector2(-r * 0.8, 0.0)])
		draw_colored_polygon(pts, UiTheme.ZONE_RECOVER)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), UiTheme.CHALK, 2.0)
