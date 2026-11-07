extends Node2D
## Reconcile chapter-two objectives when entering, including existing saves.

func _ready() -> void:
	if not GameState.is_chapter_unlocked(2):
		SceneLoader.return_from_minigame.call_deferred()
		return
	GameState.enter_chapter2_room()
