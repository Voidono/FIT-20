class_name UiTheme
extends RefCounted
## Palette, font and theme in one place, so the pixel-art pass only touches this file.
## The font is a Vietnamese-capable subset of DejaVu Sans Bold (stacked diacritics tested). Swap FONT_PATH
## for your pixel font later, and keep the diacritics test line in the debug overlay to check coverage.

const FONT_PATH: String = "res://assets/fonts/DejaVuSans-Bold-vi.ttf"
const LOGO_PATH: String = "res://assets/branding/fit_logo.png"

# HUD palette
const INK := Color("17233a")
const INK_SOFT := Color("243653")
const CHALK := Color("f1f4f8")
const CHALK_DIM := Color("9fb0c6")

# Zones are told apart by lightness, a glyph and a name as well as hue
const ZONE_RECOVER := Color("67c8e8")
const ZONE_CRUISE := Color("a6d84a")
const ZONE_PUSH := Color("ffa63d")
const ZONE_SPRINT := Color("ee4266")
const ZONE_WALL := Color("8a76a6")

# Placeholder world palette
const SKY_TOP := Color("8fcfea")
const SKY_BOTTOM := Color("e3f3ee")
const HILL_FAR := Color("86bba9")
const HILL_NEAR := Color("5da58b")
const LAWN := Color("3d7d5c")
const TRACK := Color("a9503a")
const WATER_BLUE := Color("4aa3df")

const ZONE_RECOVER_ID: int = 0
const ZONE_CRUISE_ID: int = 1
const ZONE_PUSH_ID: int = 2
const ZONE_SPRINT_ID: int = 3
const ZONE_WALL_ID: int = 4
const ZONE_KEYS: Array[String] = ["ZONE_RECOVER", "ZONE_CRUISE", "ZONE_PUSH", "ZONE_SPRINT", "ZONE_WALL"]
const ZONE_GLYPHS: Array[String] = ["○", "●", "▲", "▲▲", "×"]

static var _font: Font = null
static var _logo: Texture2D = null
static var _logo_checked: bool = false


static func font() -> Font:
	if _font == null:
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH) as Font
		if _font == null:
			_font = ThemeDB.fallback_font
	return _font


## The FIT logo if you have dropped assets/branding/fit_logo.png in, otherwise null.
static func logo() -> Texture2D:
	if not _logo_checked:
		_logo_checked = true
		if ResourceLoader.exists(LOGO_PATH):
			_logo = load(LOGO_PATH) as Texture2D
	return _logo


static func zone_for(pace: float, walled: bool) -> int:
	if walled:
		return ZONE_WALL_ID
	if pace < 0.5:
		return ZONE_RECOVER_ID
	if pace < 0.7:
		return ZONE_CRUISE_ID
	if pace < 0.9:
		return ZONE_PUSH_ID
	return ZONE_SPRINT_ID


static func zone_color(zone: int) -> Color:
	match zone:
		ZONE_RECOVER_ID:
			return ZONE_RECOVER
		ZONE_CRUISE_ID:
			return ZONE_CRUISE
		ZONE_PUSH_ID:
			return ZONE_PUSH
		ZONE_SPRINT_ID:
			return ZONE_SPRINT
	return ZONE_WALL


static func format_time(sec: float) -> String:
	var s: float = maxf(sec, 0.0)
	var minutes: int = int(s / 60.0)
	var rest: float = s - float(minutes) * 60.0
	return "%02d:%04.1f" % [minutes, rest]


static func _box(bg: Color, radius: int, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.set_content_margin_all(8.0)
	return sb


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font()
	theme.default_font_size = 14
	theme.set_color("font_color", "Label", CHALK)
	theme.set_color("font_outline_color", "Label", INK)
	theme.set_constant("outline_size", "Label", 4)
	theme.set_stylebox("normal", "Button", _box(INK_SOFT, 6, CHALK_DIM))
	theme.set_stylebox("hover", "Button", _box(INK_SOFT.lightened(0.12), 6, CHALK))
	theme.set_stylebox("pressed", "Button", _box(INK, 6, CHALK))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", CHALK)
	theme.set_color("font_hover_color", "Button", CHALK)
	theme.set_color("font_pressed_color", "Button", CHALK)
	theme.set_font_size("font_size", "Button", 16)
	theme.set_stylebox("panel", "PanelContainer", _box(Color(INK, 0.94), 10, CHALK_DIM))
	return theme
