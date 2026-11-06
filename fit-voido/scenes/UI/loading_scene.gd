extends Control

@export var min_load_time := 1.0

var _progress: Array = []
var _timer := 0.0
var _target := ""


func _ready() -> void:
	_target = SceneLoader.target_scene
	if ResourceLoader.load_threaded_request(_target) != OK:
		_show_failure()


func _process(delta: float) -> void:
	_timer += delta
	var status := ResourceLoader.load_threaded_get_status(_target, _progress)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			if _timer >= min_load_time:
				set_process(false)
				var scene: PackedScene = ResourceLoader.load_threaded_get(_target)
				if get_tree().change_scene_to_packed(scene) != OK:
					_show_failure()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_show_failure()


func _show_failure() -> void:
	set_process(false)
	SceneLoader.activity_id = ""
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(box)
	var message := Label.new()
	message.text = "Không thể mở khu vực này. Vui lòng quay lại."
	box.add_child(message)
	var back := Button.new()
	back.text = "Quay lại"
	back.pressed.connect(func() -> void:
		var path: String = SceneLoader.previous_scene
		if path == SceneLoader.ACTIVITY_HOST or not ResourceLoader.exists(path, "PackedScene"):
			path = SceneLoader.MENU
		if get_tree().change_scene_to_file(path) != OK:
			get_tree().change_scene_to_file(SceneLoader.MENU)
	)
	box.add_child(back)
	back.grab_focus()
