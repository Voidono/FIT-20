extends Control
const STYLE = preload("res://scenes/UI/screen_style.gd")
signal return_requested
var result: Variant
var best_score := 0
var return_button: Button
var _notice: Label
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := STYLE.frame(self, 650)
	var compact := get_viewport_rect().size.y < 420
	if compact:
		body.add_theme_constant_override("separation", 6)
	STYLE.label(body, "CHƯƠNG 04   /   CON BUG", 12, STYLE.GOLD)
	STYLE.label(body, "Cùng nhau sửa lỗi." if result.spared() else "Hệ thống đã an toàn." if result.won() else "Chưa phải lần cuối.", 24 if compact else 30)
	STYLE.label(body, "Thầy Thắng đang chờ bạn trở lại phòng 210C." if result.won() or result.spared() else "Trở lại văn phòng để chuẩn bị và thử sức lần nữa.", 15)
	var rule := HSeparator.new()
	body.add_child(rule)
	rule.visible = not compact
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 16)
	body.add_child(score_row)
	STYLE.label(score_row, "%s" % result.score if result.won() else "CON BUG đã bình tĩnh lại" if result.spared() else "Hãy thử lại", 38 if compact else 46, STYLE.GOLD)
	if result.won():
		var record := STYLE.label(score_row, "ĐIỂM TRẬN ĐẤU\nKỷ lục %d" % best_score, 13)
		record.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 20)
		grid.add_theme_constant_override("v_separation", 6)
		body.add_child(grid)
		STYLE.label(grid, "Cơ bản  %d" % result.base_points)
		STYLE.label(grid, "Thưởng thể lực  +%d" % result.health_bonus)
		STYLE.label(grid, "Hệ số độ khó  ×%.1f" % result.score_multiplier)
		STYLE.label(grid, "Thể lực còn lại  %d / %d" % [result.final_hp, result.max_hp])
	elif result.spared():
		STYLE.label(body, "Một lựa chọn khác, một người bạn mới.\nTiếp tục hành trình để khám phá điều đang chờ phía trước.", 16)
	_notice = STYLE.label(body, "", 14)
	_notice.hide()
	return_button = STYLE.button(body, "Trở lại phòng 210C  →", func(): return_requested.emit(), true)
	return_button.grab_focus()
func show_notice(text: String) -> void:
	_notice.text = text
	_notice.show()
