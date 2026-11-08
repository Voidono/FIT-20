extends Control
const STYLE = preload("res://scenes/UI/screen_style.gd")
var _design: Control
var play_button: Button

func _ready() -> void:
	_design = self
	var body := STYLE.frame(self, 740)
	var compact := get_viewport_rect().size.y < 420
	STYLE.label(body, "ĐẠI HỌC HÀ NỘI   /   20 NĂM FIT", 12, STYLE.GOLD)
	STYLE.label(body, "FIT · THE TIME STONE", 28 if compact else 42)
	STYLE.label(body, "2006 — 2026. Bốn viên đá. Một hành trình trở về.", 14)
	var art = preload("res://scenes/UI/time_screen_art.gd").new()
	art.custom_minimum_size.y = 48 if compact else 110
	for i in 4: art.placed[i] = GameState.has_time_stone(i + 1)
	body.add_child(art)
	var row := GridContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var started := GameState.has_flag("intro_complete") or GameState.time_stone_count() > 0
	play_button = STYLE.button(row, "Tiếp tục hành trình" if started else "Bắt đầu hành trình", _on_play_button_pressed, true)
	STYLE.button(row, "Âm thanh", _on_setting_button_pressed)
	if DeviceInput.is_desktop() and not OS.has_feature("web"):
		STYLE.button(row, "Thoát", _on_quit_button_pressed)
	var fit_actions := func(): row.columns = 1 if get_viewport_rect().size.x < 600 and get_viewport_rect().size.y >= 420 else row.get_child_count()
	resized.connect(fit_actions)
	fit_actions.call()
	STYLE.label(body, "%d / 4 VIÊN ĐÁ ĐÃ TÌM THẤY" % GameState.time_stone_count() if started else "Khám phá HANU, gặp gỡ FIT và tìm đường trở về.", 12, Color("acbca8"))
	play_button.grab_focus()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
func _on_play_button_pressed() -> void:
	SceneLoader.go_to("res://scenes/mapsides/nửa đầu.tscn")
func _on_setting_button_pressed() -> void:
	SceneLoader.go_to("res://scenes/menu & options/setting_game.tscn")
