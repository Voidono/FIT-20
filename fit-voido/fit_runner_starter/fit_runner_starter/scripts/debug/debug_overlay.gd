class_name DebugOverlay
extends CanvasLayer
## Live tuning and readouts. The layout is debug_overlay.tscn; every slider is a TuningSlider instance writing
## straight into the RunnerTuning resource. Toggle with the DBG button or F1.
## Rate and speed sliders act live; track length, mode and presets restart the run so par is rebuilt.

signal restart_requested
signal copy_log_requested

@onready var _toggle: Button = $Root/ToggleButton
@onready var _panel: PanelContainer = $Root/Panel
@onready var _readout: Label = $Root/Panel/Scroll/Box/Readout
@onready var _mode_option: OptionButton = $Root/Panel/Scroll/Box/ModeOption
@onready var _language_option: OptionButton = $Root/Panel/Scroll/Box/LanguageOption
@onready var _sliders: Control = $Root/Panel/Scroll/Box/Sliders

var _tuning: RunnerTuning


func bind(tuning: RunnerTuning) -> void:
	_tuning = tuning
	_toggle.visible = tuning.show_debug_button
	_mode_option.select(int(tuning.input_mode))
	_language_option.select(0 if TranslationServer.get_locale().begins_with("vi") else 1)
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


func _sync_sliders() -> void:
	for child: Node in _sliders.get_children():
		var row := child as TuningSlider
		if row != null:
			row.bind(_tuning)


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_copy_pressed() -> void:
	copy_log_requested.emit()


func _on_original_pressed() -> void:
	if _tuning == null:
		return
	_tuning.apply_original_numbers()
	_sync_sliders()
	restart_requested.emit()


func _on_calibrated_pressed() -> void:
	if _tuning == null:
		return
	_tuning.apply_calibrated_numbers()
	_sync_sliders()
	restart_requested.emit()


func _on_mode_selected(index: int) -> void:
	if _tuning == null:
		return
	_tuning.input_mode = index as RunnerTuning.InputMode
	restart_requested.emit()


func _on_language_selected(index: int) -> void:
	TranslationServer.set_locale("vi" if index == 0 else "en")


func refresh(s: HudState) -> void:
	if not _panel.visible or s.model == null or s.tuning == null:
		return
	var m: RunnerModel = s.model
	var t: RunnerTuning = s.tuning
	var mode_name: String = "B tiers" if t.input_mode == RunnerTuning.InputMode.TIERS else "A hold/release"
	var lines: PackedStringArray = []
	lines.append("fps %d | mode %s | attempt %d" % [Engine.get_frames_per_second(), mode_name, s.attempt])
	lines.append("pace %.2f  effort %.2f  zone %d" % [m.pace, s.effort, Zones.for_pace(m.pace, m.walled)])
	lines.append("stamina %.1f  rate %s/s  walls %d%s" % [m.stamina, Fmt.signed(m.rate, 2), m.walls_hit, " WALLED" if m.walled else ""])
	lines.append("slope %s  speed %.0f px/s" % [Fmt.signed(m.slope_norm, 2), m.ground_speed])
	lines.append("t %.1f  par %.1f  cutoff %.1f" % [m.elapsed, s.par_time, s.cutoff_time])
	lines.append("progress %.1f%%" % (m.progress() * 100.0))
	_readout.text = "\n".join(lines)
