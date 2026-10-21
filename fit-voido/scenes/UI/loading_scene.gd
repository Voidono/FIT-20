extends Control

@export var min_load_time := 1.0

var _progress: Array = []
var _timer := 0.0
var _target := ""


func _ready() -> void:
	_target = SceneLoader.target_scene
	ResourceLoader.load_threaded_request(_target)


func _process(delta: float) -> void:
	_timer += delta
	var status := ResourceLoader.load_threaded_get_status(_target, _progress)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			if _timer >= min_load_time:
				set_process(false)
				var scene: PackedScene = ResourceLoader.load_threaded_get(_target)
				get_tree().change_scene_to_packed(scene)

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			push_error("Không load được scene: " + _target)
