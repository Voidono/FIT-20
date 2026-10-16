extends Node
## Stand-in for the main game: fits the window, hosts the minigame, and listens to its signals the way the
## quest system will. Copy _update_scale() into the real game's boot script if it does not scale already.

const RUNNER_SCENE: PackedScene = preload("res://scenes/fit_runner.tscn")
const BASE_HEIGHT: int = 360
const MIN_WIDTH: int = 640
const MAX_ASPECT: float = 2.05  ## about 18.4:9; wider screens get side bars so nobody sees much further ahead

var _runner: FitRunner
var _status: Label


func _ready() -> void:
	get_window().size_changed.connect(_update_scale)
	_update_scale()
	_runner = RUNNER_SCENE.instantiate() as FitRunner
	add_child(_runner)
	_runner.run_finished.connect(_on_run_finished)
	_runner.quit_requested.connect(_on_quit_requested)

	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 10)
	_status.anchor_top = 1.0
	_status.anchor_bottom = 1.0
	_status.offset_left = 4.0
	_status.offset_top = -14.0
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_status)


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
