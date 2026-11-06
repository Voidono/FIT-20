extends Node2D

func _ready() -> void:
	SceneLoader.restore_player.call_deferred(self)
