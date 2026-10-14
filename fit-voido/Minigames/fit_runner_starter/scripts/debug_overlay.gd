class_name DebugOverlay
extends CanvasLayer
## Live tuning and readouts. Sliders write straight into the RunnerTuning resource.
## Toggle with the DBG button (top-left) or F1. Hide the button for release with RunnerTuning.show_debug_button.
## Rate and speed sliders act live; track length, mode and presets restart the run so par is rebuilt.

signal restart_requested
signal copy_log_requested

## [property, label, min, max, step]
const SLIDERS: Array = [
	["max_speed", "max speed px/s", 80.0, 260.0, 1.0],
	["track_length", "track length px", 4000.0, 16000.0, 100.0],
	["rise_rate", "A rise /s", 0.1, 2.0, 0.05],
	["fall_rate", "A fall /s", 0.1, 2.5, 0.05],
	["rest_floor", "A rest floor", 0.0, 0.5, 0.01],
	["stick_start", "A stick start", 0.1, 1.0, 0.05],
	["stick_end", "A stick end", 0.1, 1.0, 0.05],
	["tier_up_time", "B up time s", 0.2, 1.5, 0.05],
	["tier_down_time", "B down time s", 0.2, 1.5, 0.05],
	["speed_accel", "pace accel /s", 0.3, 4.0, 0.05],
	["speed_decel", "pace decel /s", 0.3, 4.0, 0.05],
	["rate_recover", "drain recover", 0.5, 8.0, 0.1],
	["rate_cruise", "drain cruise", -3.0, 0.0, 0.05],
	["rate_push", "drain push", -6.0, 0.0, 0.05],
	["rate_sprint", "drain sprint", -14.0, 0.0, 0.1],
	["wall_speed_cap", "wall pace cap", 0.2, 0.7, 0.01],
	["wall_release", "wall exit", 10.0, 70.0, 1.0],
	["water_amount", "water +", 0.0, 40.0, 1.0],
	["water_duration", "water time s", 0.5, 4.0, 0.1],
	["spurt_speed_cap", "spurt cap", 1.0, 1.3, 0.01],
	["spurt_drain_mult", "spurt drain x", 0.2, 1.0, 0.05],
	["uphill_drain_extra", "uphill drain +", 0.0, 3.0, 0.1],
	["uphill_speed_penalty", "uphill speed -", 0.0, 0.6, 0.01],
	["downhill_speed_bonus", "downhill speed +", 0.0, 0.6, 0.01],
	["cutoff_mult", "cutoff x par", 1.1, 2.5, 0.05],
	["star3_mult", "3 star x par", 1.0, 1.3, 0.01],
	["star2_mult", "2 star x par", 1.0, 1.6, 0.01],
]

const TEST_LINE: String = "Tiếng Việt: ắ ằ ẳ ẵ ặ ề ể ễ ệ ổ ỗ ộ ờ ở ỡ ợ ừ ử ữ ự ỳ ỷ ỹ ỵ"

var _tuning: RunnerTuning
var _root: Control
var _toggle: Button
var _panel: PanelContainer
var _readout: Label
var _mode_option: OptionButton
var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}
var _syncing: bool = false


func _ready() -> void:
	Strings.install()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.build_theme()
	add_child(_root)

	_toggle = Button.new()
	_toggle.text = "DBG"
	_toggle.focus_mode = Control.FOCUS_NONE
	_toggle.add_theme_font_size_override("font_size", 11)
	_toggle.offset_left = 4.0
	_toggle.offset_top = 4.0
	_toggle.offset_right = 44.0
	_toggle.offset_bottom = 26.0
	_toggle.pressed.connect(toggle_panel)
	_root.add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.58
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = 30.0
	_panel.offset_bottom = -4.0
	_panel.offset_right = -4.0
	_panel.visible = false
	_root.add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	scroll.add_child(box)

	_readout = Label.new()
	_readout.add_theme_font_size_override("font_size", 11)
	box.add_child(_readout)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	buttons.add_child(_small_button("Restart", func() -> void: restart_requested.emit()))
	buttons.add_child(_small_button("Copy log", func() -> void: copy_log_requested.emit()))

	var presets := HBoxContainer.new()
	box.add_child(presets)
	presets.add_child(_small_button("Your numbers", _on_original))
	presets.add_child(_small_button("Calibrated", _on_calibrated))

	_mode_option = OptionButton.new()
	_mode_option.add_item("A  hold / release", 0)
	_mode_option.add_item("B  hold-time tiers", 1)
	_mode_option.add_theme_font_size_override("font_size", 11)
	_mode_option.item_selected.connect(_on_mode_selected)
	box.add_child(_mode_option)

	for spec: Array in SLIDERS:
		_add_slider_row(box, spec[0], spec[1], spec[2], spec[3], spec[4])

	var test := Label.new()
	test.text = TEST_LINE
	test.add_theme_font_size_override("font_size", 11)
	test.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(test)


func setup(tuning: RunnerTuning) -> void:
	_tuning = tuning
	_toggle.visible = tuning.show_debug_button
	_mode_option.select(int(tuning.input_mode))
	_sync_sliders()


func toggle_panel() -> void:
	_panel.visible = not _panel.visible


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo and key.keycode == KEY_F1:
			toggle_panel()


func is_point_over_ui(pos: Vector2) -> bool:
	if _toggle.is_visible_in_tree() and _toggle.get_global_rect().has_point(pos):
		return true
	return _panel.is_visible_in_tree() and _panel.get_global_rect().has_point(pos)


func _small_button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 11)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(on_pressed)
	return b


func _add_slider_row(parent: Control, prop: String, label_text: String, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(88.0, 0.0)
	name_label.add_theme_font_size_override("font_size", 10)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(50.0, 16.0)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(40.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 10)
	slider.value_changed.connect(func(v: float) -> void: _on_slider(prop, v))
	row.add_child(name_label)
	row.add_child(slider)
	row.add_child(value_label)
	parent.add_child(row)
	_sliders[prop] = slider
	_value_labels[prop] = value_label


func _on_slider(prop: String, v: float) -> void:
	if _syncing or _tuning == null:
		return
	_tuning.set(prop, v)
	var value_label: Label = _value_labels[prop]
	value_label.text = _fmt(v)


func _sync_sliders() -> void:
	if _tuning == null:
		return
	_syncing = true
	for prop: String in _sliders:
		var slider: HSlider = _sliders[prop]
		var v: float = float(_tuning.get(prop))
		slider.value = v
		var value_label: Label = _value_labels[prop]
		value_label.text = _fmt(v)
	_syncing = false


func _signed(v: float) -> String:
	return ("+" if v >= 0.0 else "-") + "%.2f" % absf(v)


func _fmt(v: float) -> String:
	return "%.0f" % v if absf(v) >= 100.0 else "%.2f" % v


func _on_mode_selected(index: int) -> void:
	if _tuning == null:
		return
	_tuning.input_mode = index as RunnerTuning.InputMode
	restart_requested.emit()


func _on_original() -> void:
	if _tuning == null:
		return
	_tuning.apply_original_numbers()
	_sync_sliders()
	restart_requested.emit()


func _on_calibrated() -> void:
	if _tuning == null:
		return
	_tuning.apply_calibrated_numbers()
	_sync_sliders()
	restart_requested.emit()


func refresh(s: HudState) -> void:
	if not _panel.visible or s.model == null or s.tuning == null:
		return
	var m: RunnerModel = s.model
	var t: RunnerTuning = s.tuning
	var mode_name: String = "B tiers" if t.input_mode == RunnerTuning.InputMode.TIERS else "A hold/release"
	var zone: int = UiTheme.zone_for(m.pace, m.walled)
	var lines: PackedStringArray = []
	lines.append("fps %d | mode %s | attempt %d" % [Engine.get_frames_per_second(), mode_name, s.attempt])
	lines.append("pace %.2f  effort %.2f  zone %s" % [m.pace, s.effort, Strings.t(UiTheme.ZONE_KEYS[zone])])
	lines.append("stamina %.1f  rate %s/s  walls %d%s" % [m.stamina, _signed(m.rate), m.walls_hit, " WALLED" if m.walled else ""])
	lines.append("slope %s  speed %.0f px/s" % [_signed(m.slope_norm), m.ground_speed])
	lines.append("t %.1f  par %.1f  cutoff %.1f" % [m.elapsed, s.par_time, s.cutoff_time])
	lines.append("progress %.1f%%" % (m.progress() * 100.0))
	_readout.text = "\n".join(lines)
