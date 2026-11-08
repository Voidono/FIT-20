extends RefCounted
const GOLD := Color("e6c58a")
const CREAM := Color("f2ebd9")
static func box(color: Color, border := Color("56645a")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	return style
static func frame(root: Control, width := 740.0) -> VBoxContainer:
	root.theme = preload("res://scenes/UI/quests/quest_theme.tres")
	var background = preload("res://scenes/UI/time_screen_art.gd").new()
	background.backdrop = true
	root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	root.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 16
	scroll.offset_top = 16
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", box(Color("162824"), Color("887a57")))
	center.add_child(card)
	var layout := func(): card.custom_minimum_size.x = minf(width, root.get_viewport_rect().size.x - 32)
	root.resized.connect(layout)
	layout.call()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	card.add_child(body)
	return body
static func label(parent: Control, text: String, font_size := 16, color := CREAM) -> Label:
	var node := Label.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node
static func button(parent: Control, title: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 48
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("normal", box(Color("c9aa70") if primary else Color("203730")))
	b.add_theme_stylebox_override("hover", box(Color("e5cb97") if primary else Color("314d40"), GOLD))
	b.add_theme_stylebox_override("pressed", box(Color("a88a55") if primary else Color("263f35"), GOLD))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD))
	b.add_theme_stylebox_override("disabled", box(Color("1b2a25"), Color("38473c")))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color("14231f") if primary else CREAM)
	parent.add_child(b)
	b.pressed.connect(action)
	return b
