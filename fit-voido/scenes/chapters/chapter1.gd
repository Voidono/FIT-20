extends Node2D
## Editable staging for the real campus. Coordinates are local to the campus root.

@export var starting_position := Vector2(300, 100)
@export var minh_position := Vector2(380, 100)
@export var lecturer_position := Vector2(1158, -915)

func _ready() -> void:
	var player := $Map/Character as Node2D
	player.position = starting_position
	$NPC/Minh.position = minh_position
	$NPC/Lecturer.position = lecturer_position
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = int(global_position.x - 1888)
	camera.limit_top = int(global_position.y - 2992)
	camera.limit_right = int(global_position.x + 6496)
	camera.limit_bottom = int(global_position.y + 2384)
	if not GameState.has_flag("intro_complete"):
		GameState.start_quest("meet_minh")
	elif not GameState.has_time_stone(1) and GameState.stage1_activity().is_empty() and not GameState.has_completed_quest("reach_building_c"):
		GameState.start_quest("reach_building_c")
