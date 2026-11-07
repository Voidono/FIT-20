extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var template = load("res://scenes/templates/scene_door.tscn")
	var first = template.instantiate()
	var second = template.instantiate()
	assert(first is Area2D)
	assert(first.required_chapter == 1)
	assert(first.target_scene.is_empty())
	assert(first.get_node("CollisionShape2D").shape != second.get_node("CollisionShape2D").shape)
	assert(first.activation == 0)
	first.activation = 1
	assert(first.activation == 1)
	var hallway = load("res://scenes/mapsides/t_2.tscn").instantiate()
	var door = hallway.get_node("Room417Door")
	assert(door.position == Vector2(3100, 150))
	assert(door.target_scene == "res://scenes/chapters/room_417.tscn")
	assert(hallway.get_node("CampusEntrance/CollisionShape2D").shape.size == Vector2(200, 48))
	first.free()
	second.free()
	hallway.free()
	print("PASS: reusable door template and both hallway instances")
	quit(0)
