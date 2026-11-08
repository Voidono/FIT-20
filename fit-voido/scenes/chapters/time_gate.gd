extends Control
## Shared final gate and two text epilogues. No art or music permissions assumed.
var _body: VBoxContainer
var _text: Label
var _activate: Button
var _slots: Array[Button] = []
var _lines: Array[String] = []
var _index := 0
const STYLE = preload("res://scenes/UI/screen_style.gd")
var _art: Control
var _slot_grid: GridContainer

func _ready() -> void:
	_body = STYLE.frame(self, 700)
	_body.add_theme_constant_override("separation", 8)
	STYLE.label(_body, "CHẶNG CUỐI   /   VĂN PHÒNG KHOA", 12, STYLE.GOLD)
	STYLE.label(_body, "Cánh Cửa Thời Gian", 30)
	_art = preload("res://scenes/UI/time_screen_art.gd").new()
	_art.custom_minimum_size.y = 48 if get_viewport_rect().size.y < 420 else 96
	_body.add_child(_art)
	_text = STYLE.label(_body, "Đặt bốn viên đá để mở lối trở về năm 2006.", 15)
	_slot_grid = GridContainer.new()
	_slot_grid.columns = 4 if get_viewport_rect().size.y < 420 else 2
	_slot_grid.add_theme_constant_override("h_separation", 8)
	_slot_grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(_slot_grid)
	for number in range(1, 5):
		var n := number
		var slot := button("", func():
			GameState.place_time_stone(n)
			_refresh()
		)
		_slots.append(slot)
		slot.reparent(_slot_grid)
	_activate = button("Mở cổng", _begin_ending)
	var back := button("Trở lại văn phòng", func(): SceneLoader.go_to_spawn("res://scenes/mapsides/phòng210.tscn", Vector2(256, 280)))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_body.add_child(actions)
	_activate.reparent(actions)
	back.reparent(actions)
	_refresh()

func button(title: String, callback: Callable) -> Button:
	return STYLE.button(_body, title, callback, title in ["Mở cổng", "Tiếp tục", "Về menu chính"])

func _refresh() -> void:
	var ready := true
	for i in range(4):
		var number := i + 1
		var placed := GameState.has_flag("gate_stone_%d" % number)
		_slots[i].text = "Viên đá %d — %s" % [number, "Đã đặt" if placed else "Đặt vào cổng" if GameState.has_time_stone(number) else "Chưa tìm thấy"]
		_art.placed[i] = placed
		_slots[i].disabled = placed or not GameState.has_time_stone(number)
		if get_viewport_rect().size.y < 420:
			_slots[i].text = "%s · %s" % [["I", "II", "III", "IV"][i], "Đã đặt" if placed else "Đặt đá" if GameState.has_time_stone(number) else "Chưa có"]
		_slots[i].add_theme_color_override("font_disabled_color", STYLE.GOLD if placed else Color("829082"))
		ready = ready and placed
	_activate.disabled = not ready
	_art.queue_redraw()
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
	_text.add_theme_font_size_override("font_size", 20)
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
