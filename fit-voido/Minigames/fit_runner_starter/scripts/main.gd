extends Node
## Stand-in for the main game. The minigame is instanced in main.tscn, its signals are connected there, and this
## script only fits the window and shows what the quest system would receive.
## Copy _update_scale() into the real game's boot script if it does not scale already.

const BASE_HEIGHT: int = 360
const MIN_WIDTH: int = 640
const MAX_ASPECT: float = 2.05  ## about 18.4:9; wider screens get side bars so nobody sees much further ahead

@onready var _status: Label = Lookup.node(self, "Status") as Label


func _enter_tree() -> void:
	TranslationServer.set_locale("vi")  # before any Label is ready (the language can be switched in the debug overlay)


func _ready() -> void:
	get_window().size_changed.connect(_update_scale)
	_update_scale()


## 640x360 internal canvas, 16:9 up to about 18.4:9, bars beyond that (project uses canvas_items + keep).
func _update_scale() -> void:
	var win: Window = get_window()
	if win.size.y <= 0:
		return
	var aspect: float = float(win.size.x) / float(win.size.y)
	var width: int = roundi(clampf(aspect * float(BASE_HEIGHT), float(MIN_WIDTH), MAX_ASPECT * float(BASE_HEIGHT)))
	win.content_scale_size = Vector2i(width, BASE_HEIGHT)


func _on_run_finished(result: RunResult) -> void:
	var text: String = JSON.stringify(result.to_dict())
	print("run_finished ", text)
	_status.text = "run_finished: " + text


func _on_quit_requested() -> void:
	print("quit_requested")
	_status.text = "quit_requested (the main game would change scene here)"
