extends Node
## Dev harness: stands in for the main game so the module can be tested on its own. It fits the window to the 640x360
## canvas, picks the language, launches FIT Runner with the debug overlay on, and shows what a quest system would receive.
## Nothing in dev/ belongs to the module: copy only minigames/fit_runner/ into your game.

const BASE_HEIGHT: int = 360
const MIN_WIDTH: int = 640
const MAX_ASPECT: float = 2.05  ## about 18.4:9; wider screens get side bars so nobody sees much further ahead

@onready var _status: Label = $StatusLayer/Status


func _enter_tree() -> void:
	TranslationServer.set_locale("vi")  # the host picks the language; the module never does


func _ready() -> void:
	get_window().size_changed.connect(_update_scale)
	_update_scale()
	var config := FitRunnerConfig.new()
	config.debug_enabled = true
	var game: FitRunner = FitRunnerLauncher.launch(self, config)
	game.run_finished.connect(_on_run_finished)
	game.quit_requested.connect(_on_quit_requested)


## 640x360 internal canvas, 16:9 up to about 18.4:9, bars beyond that (this project uses canvas_items + keep).
func _update_scale() -> void:
	var win: Window = get_window()
	if win.size.y <= 0:
		return
	var aspect: float = float(win.size.x) / float(win.size.y)
	var width: int = roundi(clampf(aspect * float(BASE_HEIGHT), float(MIN_WIDTH), MAX_ASPECT * float(BASE_HEIGHT)))
	win.content_scale_size = Vector2i(width, BASE_HEIGHT)


func _on_run_finished(result: FitRunnerResult) -> void:
	var text: String = JSON.stringify(result.to_dict())
	print("run_finished ", text)
	_status.text = "run_finished: " + text


func _on_quit_requested() -> void:
	print("quit_requested")
	_status.text = "quit_requested (the main game would free the minigame and change scene here)"
