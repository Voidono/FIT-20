extends Node2D
## Chapter-two arrival only; seating and quiz belong to the next implementation task.

func _ready() -> void:
	if not GameState.is_chapter_unlocked(2):
		SceneLoader.return_from_minigame.call_deferred()
		return
	GameState.complete_quest("enter_room_417")
