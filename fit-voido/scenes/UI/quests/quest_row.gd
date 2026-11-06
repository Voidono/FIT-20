extends PanelContainer
## Passive quest presentation: no input actions or Dialogue Manager dependency.

var _completed := false
var _initialized := false
var _flash: Tween
@onready var title_label: Label = $Body/Heading/Title
@onready var status: Label = $Body/Heading/Status
@onready var objective: Label = $Body/Objective
@onready var counter: Label = $Body/Counter
@onready var progress: ProgressBar = $Body/Progress

func display(data: Dictionary) -> void:
	var done := bool(data["completed"])
	title_label.text = str(data["title"])
	status.text = "[OK]" if done else "[ ]"
	objective.text = str(data["objective"])
	counter.text = "%d/%d" % [data["progress"], data["target"]]
	progress.max_value = int(data["target"])
	progress.value = int(data["progress"])
	if _initialized and done and not _completed:
		if _flash and _flash.is_valid():
			_flash.kill()
		modulate = Color(1.0, 0.85, 0.45)
		_flash = create_tween()
		_flash.tween_property(self, "modulate", Color.WHITE, 0.65)
	_completed = done
	_initialized = true
