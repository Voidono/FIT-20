class_name Strings
extends RefCounted
## All player-facing text in one translation-ready file: key -> text per language.
## install() registers the tables with Godot's TranslationServer, t() looks a key up.
## The Vietnamese is a first draft for you to review. STORY_READY is a placeholder until the real storyline arrives.

const DEFAULT_LOCALE: String = "vi"

const TABLE: Dictionary = {
	"vi": {
		"ZONE_RECOVER": "Hồi sức",
		"ZONE_CRUISE": "Giữ nhịp",
		"ZONE_PUSH": "Tăng tốc",
		"ZONE_SPRINT": "Nước rút",
		"ZONE_WALL": "Kiệt sức",
		"OUTLOOK_OK": "Đủ sức về đích (+%d)",
		"OUTLOOK_TIGHT": "Sát giới hạn",
		"OUTLOOK_WALL": "Sắp kiệt sức",
		"STORY_READY": "Thu thập 4 Viên đá Thời gian để mở lại cổng thời gian.",
		"PROMPT_HOW": "Giữ để tăng tốc, thả để hồi sức",
		"PROMPT_READY": "Chạm hoặc nhấn Space để bắt đầu",
		"COUNT_GO": "Chạy!",
		"WALL_PROMPT": "Kiệt sức! Thả tay để hồi sức",
		"WATER_PROMPT": "Trạm nước: thả tay để uống",
		"DRINKING": "Đang uống nước…",
		"SPURT_BANNER": "NƯỚC RÚT!",
		"PAUSE_TITLE": "Tạm dừng",
		"BTN_RESUME": "Tiếp tục",
		"BTN_RESTART": "Chơi lại",
		"BTN_QUIT": "Thoát",
		"BTN_CONTINUE": "Tiếp tục",
		"RESULT_PASS": "Về đích!",
		"RESULT_FAIL": "Hết giờ!",
		"RESULT_TIME": "Thời gian: %s",
		"RESULT_PAR": "Mốc chuẩn: %s",
		"RESULT_WALLS": "Số lần kiệt sức: %d",
		"STONE_GOT": "Bạn nhận được Viên đá Thời gian #1!",
		"FAIL_HINT": "Mẹo: giữ nhịp đều, dồn sức cho đoạn nước rút cuối.",
		"ROTATE": "Hãy xoay ngang điện thoại",
		"SIGN_START": "XUẤT PHÁT",
		"SIGN_HILL": "DỐC",
		"SIGN_WATER": "TRẠM NƯỚC",
		"SIGN_SPURT": "NƯỚC RÚT",
		"SIGN_FINISH": "VỀ ĐÍCH",
	},
	"en": {
		"ZONE_RECOVER": "Recover",
		"ZONE_CRUISE": "Cruise",
		"ZONE_PUSH": "Push",
		"ZONE_SPRINT": "Sprint",
		"ZONE_WALL": "Wall",
		"OUTLOOK_OK": "Enough to finish (+%d)",
		"OUTLOOK_TIGHT": "Cutting it close",
		"OUTLOOK_WALL": "Wall ahead",
		"STORY_READY": "Collect the 4 Time Stones to reopen the time gate.",
		"PROMPT_HOW": "Hold to push, release to recover",
		"PROMPT_READY": "Tap or press Space to start",
		"COUNT_GO": "Go!",
		"WALL_PROMPT": "Out of energy! Let go to recover",
		"WATER_PROMPT": "Water station: let go to drink",
		"DRINKING": "Drinking...",
		"SPURT_BANNER": "FINAL SPURT!",
		"PAUSE_TITLE": "Paused",
		"BTN_RESUME": "Resume",
		"BTN_RESTART": "Retry",
		"BTN_QUIT": "Quit",
		"BTN_CONTINUE": "Continue",
		"RESULT_PASS": "Finished!",
		"RESULT_FAIL": "Time's up!",
		"RESULT_TIME": "Time: %s",
		"RESULT_PAR": "Par: %s",
		"RESULT_WALLS": "Walls hit: %d",
		"STONE_GOT": "You got Time Stone #1!",
		"FAIL_HINT": "Tip: keep a steady pace and save energy for the final spurt.",
		"ROTATE": "Please rotate your phone to landscape",
		"SIGN_START": "START",
		"SIGN_HILL": "HILL",
		"SIGN_WATER": "WATER",
		"SIGN_SPURT": "SPURT",
		"SIGN_FINISH": "FINISH",
	},
}

static var _installed: bool = false


## Register every language with the TranslationServer. Safe to call many times.
## The first call selects Vietnamese unless you pass a locale; later calls only change it when you pass one.
static func install(locale: String = "") -> void:
	if not _installed:
		_installed = true
		for lang: String in TABLE:
			var translation := Translation.new()
			translation.locale = lang
			var messages: Dictionary = TABLE[lang]
			for key: String in messages:
				translation.add_message(StringName(key), StringName(messages[key]))
			TranslationServer.add_translation(translation)
		TranslationServer.set_locale(DEFAULT_LOCALE if locale.is_empty() else locale)
	elif not locale.is_empty():
		TranslationServer.set_locale(locale)


static func t(key: String) -> String:
	return String(TranslationServer.translate(StringName(key)))
