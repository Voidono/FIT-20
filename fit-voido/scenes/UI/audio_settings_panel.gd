extends Control
## Shared settings card, used both from the title screen and over a paused map.
signal closed
var in_game := false
var _previous_pause := false
var _owns_pause := false
var _card: PanelContainer
var _status: Label
var sliders: Array[HSlider] = []
var resume_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://scenes/UI/quests/quest_theme.tres")
	if in_game:
		_previous_pause = get_tree().paused
		_owns_pause = true
		get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.04, 0.94 if not in_game else 0.8)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 12
	scroll.offset_right = -12
	scroll.offset_top = 12
	scroll.offset_bottom = -12
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_card = PanelContainer.new()
	center.add_child(_card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	_card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = "TẠM NGHỈ" if in_game else "CÀI ĐẶT ÂM THANH"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var note := Label.new()
	note.text = "Điều chỉnh âm lượng · Tự động lưu"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	_audio_row(box, "Âm lượng tổng", Setting.get_master_volume(), Setting.set_master_volume)
	_audio_row(box, "Nhạc nền", Setting.get_music_volume(), Setting.set_music_volume)
	_audio_row(box, "Hiệu ứng", Setting.get_effects_volume(), Setting.set_effects_volume)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.hide()
	box.add_child(_status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	resume_button = _button(actions, "Tiếp tục chơi" if in_game else "Trở lại", close)
	if in_game:
		_button(actions, "Về menu chính", return_to_menu)
		if DeviceInput.is_desktop() and not OS.has_feature("web"):
			_button(box, "Thoát trò chơi", quit_game)
	resized.connect(_layout)
	_layout()
	resume_button.grab_focus()

func _layout() -> void:
	_card.custom_minimum_size.x = minf(480, size.x - 32)

func _audio_row(parent: Control, title: String, value: float, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := Label.new()
	label.custom_minimum_size.x = 156
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	label.text = "%s    %d%%" % [title, roundi(value * 100)]
	var slider := HSlider.new()
	slider.max_value = 1
	slider.step = 0.01
	slider.custom_minimum_size.y = 44
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = value
	row.add_child(slider)
	sliders.append(slider)
	slider.value_changed.connect(func(level: float):
		setter.call(level)
		label.text = "%s    %d%%" % [title, roundi(level * 100)]
	)

func _button(parent: Control, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("26352e")
	style.border_color = Color("88774f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

func _restore_pause() -> void:
	if _owns_pause:
		for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
			Input.action_release(action)
		get_tree().paused = _previous_pause
		_owns_pause = false

func close() -> void:
	_restore_pause()
	closed.emit()
	queue_free()

func _save_progress() -> bool:
	GameState.save_game()
	if GameState.last_save_error != OK:
		_status.text = "Chưa lưu được tiến trình. Hãy thử lại."
		_status.show()
		return false
	return true

func return_to_menu() -> void:
	if not _save_progress(): return
	_restore_pause()
	var error := SceneLoader.go_to(SceneLoader.MENU)
	if error != OK:
		_status.text = "Không mở được menu. Em vẫn có thể tiếp tục chơi."
		_status.show()
	else:
		queue_free()

func quit_game() -> void:
	if _save_progress():
		_restore_pause()
		get_tree().quit()

func _exit_tree() -> void:
	_restore_pause()
