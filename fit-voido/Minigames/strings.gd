class_name TrashStrings
extends RefCounted
## Every PLAYER-FACING string lives here (the debug overlay is English-only on purpose).
## Add a language by adding a key to TABLE; switch with TrashStrings.locale = "en".
## Fonts: the engine's built-in font is used for now; the Vietnamese check is in the notes.

static var locale := "vi"

const TABLE := {
	"vi": {
		&"score": "Điểm",
		&"bin_ewaste": "RÁC ĐIỆN TỬ",
		&"bin_general": "RÁC THƯỜNG",
		&"full": "ĐẦY!",
		&"bump": "Va chạm!",
	},
	"en": {
		&"score": "Score",
		&"bin_ewaste": "E-WASTE",
		&"bin_general": "GENERAL",
		&"full": "FULL!",
		&"bump": "Bump!",
	},
}


static func t(key: StringName) -> String:
	var table: Dictionary = TABLE.get(locale, TABLE["en"])
	return table.get(key, String(key))


## 7 -> "7", 7.5 -> "7.5"
static func num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return "%.1f" % v
