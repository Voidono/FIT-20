class_name FitRunnerStrings
extends RefCounted
## All player-facing text of the minigame in one file: key -> text per language. Keys start with FR_ so they never clash with yours.
## install() registers them with the TranslationServer and never changes the locale: the host decides the language.
## Languages here: vi, en. Add a language by adding a block below; Labels in the scenes hold the keys and translate themselves.

const TABLE: Dictionary = {
	"vi": {
		"FR_ZONE_RECOVER": "Hồi sức",
		"FR_ZONE_CRUISE": "Giữ nhịp",
		"FR_ZONE_PUSH": "Tăng tốc",
		"FR_ZONE_SPRINT": "Nước rút",
		"FR_ZONE_WALL": "Kiệt sức",
		"FR_OUTLOOK_OK": "Đủ sức về đích (+%d)",
		"FR_OUTLOOK_TIGHT": "Sát giới hạn",
		"FR_OUTLOOK_WALL": "Sắp kiệt sức",
		"FR_STORY_READY": "Thu thập 4 Viên đá Thời gian để mở lại cổng thời gian.",
		"FR_PROMPT_HOW": "Giữ để tăng tốc, thả để hồi sức",
		"FR_PROMPT_READY": "Chạm hoặc nhấn Space để bắt đầu",
		"FR_COUNT_GO": "Chạy!",
		"FR_WALL_PROMPT": "Kiệt sức! Thả tay để hồi sức",
		"FR_WATER_PROMPT": "Trạm nước: thả tay để uống",
		"FR_DRINKING": "Đang uống nước…",
		"FR_SPURT_BANNER": "NƯỚC RÚT!",
		"FR_PAUSE_TITLE": "Tạm dừng",
		"FR_BTN_RESUME": "Tiếp tục",
		"FR_BTN_RESTART": "Chơi lại",
		"FR_BTN_QUIT": "Thoát",
		"FR_BTN_CONTINUE": "Tiếp tục",
		"FR_RESULT_PASS": "Về đích!",
		"FR_RESULT_FAIL": "Hết giờ!",
		"FR_RESULT_TIME": "Thời gian: %s",
		"FR_RESULT_PAR": "Mốc chuẩn: %s",
		"FR_RESULT_WALLS": "Số lần kiệt sức: %d",
		"FR_STONE_GOT": "Bạn nhận được Viên đá Thời gian #1!",
		"FR_FAIL_HINT": "Mẹo: giữ nhịp đều, dồn sức cho đoạn nước rút cuối.",
		"FR_ROTATE": "Hãy xoay ngang điện thoại",
		"FR_QTE_TAP": "CHẠM ĐÚNG VÙNG!",
		"FR_QTE_PERFECT": "HOÀN HẢO!",
		"FR_QTE_GOOD": "TỐT",
		"FR_QTE_MISS": "HỤT",
		"FR_RESULT_QTE": "QTE: %d hoàn hảo, %d tốt, %d hụt",
		"FR_SIGN_START": "XUẤT PHÁT",
		"FR_SIGN_HILL": "DỐC",
		"FR_SIGN_WATER": "TRẠM NƯỚC",
		"FR_SIGN_SPURT": "NƯỚC RÚT",
		"FR_SIGN_FINISH": "VỀ ĐÍCH",
	},
	"en": {
		"FR_ZONE_RECOVER": "Recover",
		"FR_ZONE_CRUISE": "Cruise",
		"FR_ZONE_PUSH": "Push",
		"FR_ZONE_SPRINT": "Sprint",
		"FR_ZONE_WALL": "Wall",
		"FR_OUTLOOK_OK": "Enough to finish (+%d)",
		"FR_OUTLOOK_TIGHT": "Cutting it close",
		"FR_OUTLOOK_WALL": "Wall ahead",
		"FR_STORY_READY": "Collect the 4 Time Stones to reopen the time gate.",
		"FR_PROMPT_HOW": "Hold to push, release to recover",
		"FR_PROMPT_READY": "Tap or press Space to start",
		"FR_COUNT_GO": "Go!",
		"FR_WALL_PROMPT": "Out of energy! Let go to recover",
		"FR_WATER_PROMPT": "Water station: let go to drink",
		"FR_DRINKING": "Drinking...",
		"FR_SPURT_BANNER": "FINAL SPURT!",
		"FR_PAUSE_TITLE": "Paused",
		"FR_BTN_RESUME": "Resume",
		"FR_BTN_RESTART": "Retry",
		"FR_BTN_QUIT": "Quit",
		"FR_BTN_CONTINUE": "Continue",
		"FR_RESULT_PASS": "Finished!",
		"FR_RESULT_FAIL": "Time's up!",
		"FR_RESULT_TIME": "Time: %s",
		"FR_RESULT_PAR": "Par: %s",
		"FR_RESULT_WALLS": "Walls hit: %d",
		"FR_STONE_GOT": "You got Time Stone #1!",
		"FR_FAIL_HINT": "Tip: keep a steady pace and save energy for the final spurt.",
		"FR_ROTATE": "Please rotate your phone to landscape",
		"FR_QTE_TAP": "TAP IN THE ZONE!",
		"FR_QTE_PERFECT": "PERFECT!",
		"FR_QTE_GOOD": "GOOD",
		"FR_QTE_MISS": "MISS",
		"FR_RESULT_QTE": "QTE: %d perfect, %d good, %d missed",
		"FR_SIGN_START": "START",
		"FR_SIGN_HILL": "HILL",
		"FR_SIGN_WATER": "WATER",
		"FR_SIGN_SPURT": "SPURT",
		"FR_SIGN_FINISH": "FINISH",
	},
}

static var _installed: bool = false


## Register the translations once. Returns true the first time (so a scene instanced earlier can refresh its labels).
static func install() -> bool:
	if _installed:
		return false
	_installed = true
	for lang: String in TABLE:
		var translation := Translation.new()
		translation.locale = lang
		var messages: Dictionary = TABLE[lang]
		for key: String in messages:
			translation.add_message(StringName(key), StringName(messages[key]))
		TranslationServer.add_translation(translation)
	return true


static func t(key: String) -> String:
	return String(TranslationServer.translate(StringName(key)))
