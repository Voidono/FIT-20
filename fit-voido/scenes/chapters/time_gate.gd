extends Control
## Shared final gate and two text epilogues. No art or music permissions assumed.
var _body: VBoxContainer
var _text: Label
var _activate: Button
var _slots: Array[Button] = []
var _lines: Array[String] = []
var _index := 0

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("111e25")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 16)
	scroll.add_child(_body)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 24)
	_body.add_child(_text)
	_text.text = "CÁNH CỬA THỜI GIAN — VĂN PHÒNG KHOA\nĐặt bốn viên đá để trở về năm 2006."
	for number in range(1, 5):
		var n := number
		var slot := button("", func():
			GameState.place_time_stone(n)
			_refresh()
		)
		_slots.append(slot)
	_activate = button("Mở cổng", _begin_ending)
	button("Trở lại Văn phòng Khoa", func(): SceneLoader.go_to_spawn("res://scenes/mapsides/t_2.tscn", Vector2(2572, 320)))
	_refresh()

func button(title: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 48
	b.pressed.connect(callback)
	_body.add_child(b)
	return b

func _refresh() -> void:
	var ready := true
	for i in range(4):
		var number := i + 1
		var placed := GameState.has_flag("gate_stone_%d" % number)
		_slots[i].text = "Viên đá %d — %s" % [number, "Đã đặt" if placed else "Đặt vào cổng" if GameState.has_time_stone(number) else "Chưa tìm thấy"]
		_slots[i].disabled = placed or not GameState.has_time_stone(number)
		ready = ready and placed
	_activate.disabled = not ready
	if GameState.last_save_error != OK:
		_text.text = "Chưa lưu được tiến trình. Hãy thử lưu lại trước khi mở cổng."
		_activate.disabled = true
		button("Thử lưu lại", func():
			GameState.save_game()
			_refresh()
		)

func _begin_ending() -> void:
	for number in range(1, 5):
		if not GameState.has_time_stone(number) or not GameState.has_flag("gate_stone_%d" % number):
			return
	for child in _body.get_children():
		if child != _text:
			child.queue_free()
	_lines = ["Bốn viên đá sáng lên. Một vệt sáng mở ra giữa hai mốc thời gian…"]
	if GameState.boss_resolution() == "spared":
		_lines.append_array([
			"Cánh cổng chợt khựng lại.\nCON BUG: Khoan! Còn một lỗi cuối cùng. Để tôi sửa.\nMột dòng chữ hiện lên: Exit code 0.",
			"2006.\nBạn trở lại trước cổng trường. Trong tay vẫn là tờ chương trình kỷ niệm FIT 2026, có một dòng chữ nhỏ: Cảm ơn vì đã sửa cùng tôi.",
			"Bạn: Hai mươi năm nữa chắc hết lỗi rồi.\nCON BUG: …\nBạn: Đừng trả lời."
		])
	else:
		_lines.append("2006.\nBạn trở lại trước cổng trường, kịp giờ nộp bài. Chuyến đi chỉ vừa kết thúc, nhưng ký ức về FIT hai mươi năm sau vẫn còn nguyên.")
	_lines.append("20 NĂM FIT – HÀNH TRÌNH ĐƯỢC VIẾT NÊN BỞI CHÚNG TA")
	_index = 0
	_text.text = _lines[0]
	button("Tiếp tục", _next)

func _next() -> void:
	_index += 1
	if _index < _lines.size():
		_text.text = _lines[_index]
		return
	GameState.complete_ending()
	if GameState.last_save_error != OK:
		_text.text = "Chưa lưu được kết thúc. Nhấn Tiếp tục để thử lưu lại."
		# complete_ending is idempotent; explicitly retry writing its in-memory state.
		GameState.save_game()
		return
	for child in _body.get_children():
		if child != _text:
			child.queue_free()
	_text.text = "CẢM ƠN BẠN ĐÃ ĐỒNG HÀNH CÙNG FIT\n\n" + ("KẾT THÚC ẨN — CÙNG NHAU DEBUG\nHuy hiệu đã mở khóa.\nKỷ vật: chương trình kỷ niệm FIT 2026." if GameState.boss_resolution() == "spared" else "KẾT THÚC — TRỞ VỀ NĂM 2006")
	button("Về menu chính", func(): SceneLoader.go_to(SceneLoader.MENU))
