class_name TrashDebugOverlay
extends Control
## Developer overlay: live readouts, test buttons (no keyboard needed on a phone) and tuning sliders
## bound straight to TrashTrainTuning properties, grouped into tabs.
## DBG button or F3 cycles: readouts -> readouts + sliders -> hidden.
## While a panel is visible it blocks steering underneath it, so steer from the free part of the screen.
## To add a slider, add one line to GROUPS: [property, min, max, step].

signal action_requested(action: StringName)

const GROUPS := [
	["Move", [
		["base_speed", 100.0, 500.0, 5.0],
		["min_speed_ratio", 0.3, 1.0, 0.05],
		["acceleration", 0.0, 6000.0, 100.0],
		["camera_zoom", 0.6, 2.0, 0.05],
	]],
	["Ptr", [
		["stick_radius", 30.0, 140.0, 5.0],
		["deadzone", 0.0, 40.0, 1.0],
		["ramp", 1.0, 100.0, 1.0],
	]],
	["Tail", [
		["tail_cap", 0, 30, 1],
		["tail_spacing", 12.0, 48.0, 1.0],
		["normal_slow", 0.0, 0.1, 0.005],
		["heavy_slow", 0.0, 0.2, 0.005],
		["multiplier_per_item", 0.0, 0.5, 0.01],
	]],
	["NPC", [
		["npc_count", 0, 12, 1],
		["npc_speed", 0.0, 240.0, 5.0],
		["bump_invulnerability", 0.0, 4.0, 0.1],
		["scatter_radius", 30.0, 250.0, 5.0],
	]],
	["Spawn", [
		["spawn_interval", 0.5, 8.0, 0.25],
		["glitch_lifetime", 1.0, 15.0, 0.5],
		["max_pickups", 10, 100, 1],
	]],
	["Run", [
		["run_duration", 20.0, 180.0, 1.0],
		["good_run_score", 10.0, 500.0, 5.0],
		["assist_bonus_seconds", 0.0, 30.0, 1.0],
		["assist_after_fails", 0, 6, 1],
	]],
]

const BUTTONS := [
	["Bank 1", &"bank_0"], ["Bank 2", &"bank_1"], ["Cut mid", &"cut"],
	["Freeze", &"freeze"], ["Routes", &"routes"], ["Mode", &"mode"],
	["End run", &"end"], ["New run", &"restart"],
]

var panel: PanelContainer
var toggle_button: Button
var info: Label

var _tuning: TrashTrainTuning
var _tabs: TabContainer
var _sliders := {}  # property name -> HSlider
var _state := 0  # 0 readouts, 1 readouts + sliders, 2 hidden


func setup(tuning: TrashTrainTuning) -> void:
	_tuning = tuning
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # only the panel and button catch the pointer

	toggle_button = Button.new()
	toggle_button.text = "DBG"
	toggle_button.position = Vector2(8, 8)
	toggle_button.custom_minimum_size = Vector2(64, 36)
	toggle_button.focus_mode = Control.FOCUS_NONE  # so Space (Pulse) never "clicks" a debug control
	toggle_button.pressed.connect(toggle)
	add_child(toggle_button)

	panel = PanelContainer.new()
	panel.position = Vector2(8, 50)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.self_modulate = Color(1, 1, 1, 0.85)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	info = Label.new()
	info.add_theme_font_size_override("font_size", 12)
	box.add_child(info)

	var grid := GridContainer.new()
	grid.columns = 3
	box.add_child(grid)
	for entry in BUTTONS:
		var b := Button.new()
		b.text = entry[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 30)
		b.pressed.connect(func() -> void: action_requested.emit(entry[1]))
		grid.add_child(b)

	_tabs = TabContainer.new()
	_tabs.focus_mode = Control.FOCUS_NONE
	_tabs.add_theme_font_size_override("font_size", 12)
	box.add_child(_tabs)
	for group in GROUPS:
		var page := VBoxContainer.new()
		page.name = group[0]
		page.add_theme_constant_override("separation", 2)
		_tabs.add_child(page)
		for spec in group[1]:
			_add_slider(page, spec[0], spec[1], spec[2], spec[3])
	_apply_state()


func toggle() -> void:
	_state = (_state + 1) % 3
	_apply_state()


func sliders_visible() -> bool:
	return _tabs.visible


func slider(prop: String) -> HSlider:
	return _sliders[prop]


func _apply_state() -> void:
	panel.visible = _state != 2
	_tabs.visible = _state == 1


func _add_slider(parent: Control, prop: String, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = prop
	name_label.custom_minimum_size.x = 128
	name_label.add_theme_font_size_override("font_size", 11)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 44
	value_label.add_theme_font_size_override("font_size", 11)
	var s := HSlider.new()
	s.focus_mode = Control.FOCUS_NONE
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.custom_minimum_size = Vector2(140, 20)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value = float(_tuning.get(prop))
	value_label.text = str(snappedf(s.value, 0.001))
	s.value_changed.connect(func(v: float) -> void:
		var current: Variant = _tuning.get(prop)
		_tuning.set(prop, int(v) if typeof(current) == TYPE_INT else v)
		value_label.text = str(snappedf(v, 0.001)))
	_sliders[prop] = s
	row.add_child(name_label)
	row.add_child(s)
	row.add_child(value_label)
	parent.add_child(row)
