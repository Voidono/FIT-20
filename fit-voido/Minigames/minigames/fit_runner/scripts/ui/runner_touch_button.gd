class_name FrRunnerTouchButton
extends Control
## Dedicated, multi-touch friendly arcade button for mobile and desktop runner controls.
## Tracks distinct touch fingers (InputEventScreenTouch) and mouse clicks, providing
## high-contrast visual states, tactile press feedback, and pulsing QTE alerts.

signal button_down
signal button_up
signal button_pressed

@export var is_qte: bool = false
@export var title_text: String = ""
@export var sub_text: String = ""
@export var qte_active_title: String = "⚡ CHẠM NGAY!"
@export var qte_active_sub: String = "TAP NOW!"

@export var normal_bg: Color = Color(0.05, 0.22, 0.38, 0.9)
@export var pressed_bg: Color = Color(0.02, 0.14, 0.25, 0.95)
@export var normal_border: Color = Color(0.0, 0.88, 1.0, 1.0)
@export var pressed_border: Color = Color(0.3, 1.0, 1.0, 1.0)

@export var qte_normal_bg: Color = Color(0.38, 0.26, 0.04, 0.9)
@export var qte_pressed_bg: Color = Color(0.25, 0.17, 0.02, 0.95)
@export var qte_normal_border: Color = Color(1.0, 0.78, 0.1, 1.0)
@export var qte_active_border: Color = Color(1.0, 0.25, 0.25, 1.0)

var is_down: bool = false
var is_active_qte: bool = false

var _touch_id: int = -1
var _panel: Panel
var _box_style: StyleBoxFlat
var _title_lbl: Label
var _sub_lbl: Label
var _pulse_timer: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(140, 76)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Background panel
	_panel = Panel.new()
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_box_style = StyleBoxFlat.new()
	_box_style.corner_radius_top_left = 18
	_box_style.corner_radius_top_right = 18
	_box_style.corner_radius_bottom_left = 18
	_box_style.corner_radius_bottom_right = 18
	_box_style.border_width_left = 3
	_box_style.border_width_top = 3
	_box_style.border_width_right = 3
	_box_style.border_width_bottom = 3
	_box_style.shadow_size = 6
	_box_style.shadow_color = Color(0, 0, 0, 0.45)
	_panel.add_theme_stylebox_override("panel", _box_style)

	# Label container
	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 15)
	_title_lbl.add_theme_color_override("font_color", Color.WHITE)
	_title_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.15, 1.0))
	_title_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.add_theme_font_size_override("font_size", 11)
	_sub_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.15, 0.9))
	_sub_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(_sub_lbl)

	_update_visuals()


func _process(delta: float) -> void:
	if is_active_qte:
		_pulse_timer += delta * 10.0
		var pingpong: float = (sin(_pulse_timer) + 1.0) * 0.5
		var border_col: Color = qte_normal_border.lerp(qte_active_border, pingpong)
		_box_style.border_color = border_col
		var s: float = lerpf(1.02, 1.10, pingpong)
		scale = Vector2(s, s)
	else:
		pivot_offset = size * 0.5
		var target_s: float = 0.94 if is_down else 1.0
		scale = scale.lerp(Vector2(target_s, target_s), 1.0 - exp(-20.0 * delta))


func set_texts(title: String, sub: String) -> void:
	title_text = title
	sub_text = sub
	_update_visuals()


func set_qte_active(active: bool) -> void:
	if is_active_qte == active:
		return
	is_active_qte = active
	_pulse_timer = 0.0
	_update_visuals()


func _update_visuals() -> void:
	if _box_style == null:
		return

	if is_qte:
		if is_active_qte:
			_box_style.bg_color = Color(0.55, 0.18, 0.05, 0.95)
			_box_style.border_color = qte_active_border
			_title_lbl.text = qte_active_title
			_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
			_sub_lbl.text = qte_active_sub
			_sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
		else:
			_box_style.bg_color = qte_pressed_bg if is_down else qte_normal_bg
			_box_style.border_color = pressed_border if is_down else qte_normal_border
			_title_lbl.text = title_text
			_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
			_sub_lbl.text = sub_text
			_sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65, 0.85))
	else:
		_box_style.bg_color = pressed_bg if is_down else normal_bg
		_box_style.border_color = pressed_border if is_down else normal_border
		_title_lbl.text = title_text
		_title_lbl.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
		_sub_lbl.text = sub_text
		_sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 0.85))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			if _touch_id == -1:
				_touch_id = touch.index
				_on_press_down()
				accept_event()
		else:
			if touch.index == _touch_id:
				_touch_id = -1
				_on_press_up()
				accept_event()

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _touch_id:
			var margin := 35.0
			var rect := Rect2(Vector2(-margin, -margin), size + Vector2(margin * 2.0, margin * 2.0))
			if not rect.has_point(drag.position):
				_touch_id = -1
				_on_press_up()
			accept_event()

	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_on_press_down()
				accept_event()
			else:
				if is_down:
					_on_press_up()
					accept_event()


func _on_press_down() -> void:
	is_down = true
	_update_visuals()
	button_down.emit()
	button_pressed.emit()


func _on_press_up() -> void:
	if not is_down:
		return
	is_down = false
	_update_visuals()
	button_up.emit()
