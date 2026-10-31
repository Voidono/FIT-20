class_name TrashStrings
extends RefCounted
## Every PLAYER-FACING string lives here (the debug overlay is English-only on purpose).
## Add a language by adding a key to TABLE; switch with TrashStrings.locale = "en".

static var locale := "vi"

const TABLE := {
	"vi": {
		&"score": "Điểm",
		&"time": "Thời gian",
		&"goal": "Mục tiêu",
		&"tap_to_start": "Chạm để bắt đầu",
		&"result_pass": "Hoàn thành!",
		&"result_fail": "Chưa đạt",
		&"retry": "Chơi lại",
		&"next": "Tiếp tục",
		&"bumps_label": "Va chạm",
		&"unbanked": "Chưa bỏ thùng",
		&"bin_ewaste": "RÁC ĐIỆN TỬ",
		&"bin_general": "RÁC THƯỜNG",
		&"full": "ĐẦY!",
		&"bump": "Va chạm!",
		&"magnet": "NAM CHÂM",
		&"sneakers": "GIÀY NHANH",
		&"shield": "KHIÊN",
		&"shield_block": "Đã chặn!",
	},
	"en": {
		&"score": "Score",
		&"time": "Time",
		&"goal": "Goal",
		&"tap_to_start": "Tap to start",
		&"result_pass": "Cleared!",
		&"result_fail": "Not yet",
		&"retry": "Retry",
		&"next": "Continue",
		&"bumps_label": "Bumps",
		&"unbanked": "Not banked",
		&"bin_ewaste": "E-WASTE",
		&"bin_general": "GENERAL",
		&"full": "FULL!",
		&"bump": "Bump!",
		&"magnet": "MAGNET",
		&"sneakers": "SNEAKERS",
		&"shield": "SHIELD",
		&"shield_block": "Blocked!",
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
