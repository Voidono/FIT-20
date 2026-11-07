extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Inspect the actual saved campus scene without starting its story or save hooks.
	var campus = load("res://scenes/mapsides/nửa đầu.tscn").instantiate()
	var coach = campus.get_node_or_null("Map/SVD/NPC_Minigame_Runner")
	var tuan = campus.get_node_or_null("Map/SVD/ThayTuan")
	if coach == null or tuan == null or coach.dialogue == null or tuan.dialogue == null:
		push_error("Sports-ground NPCs or dialogue resources are missing")
		quit(1)
		return
	print("PASS: Coach and Thay Tuan are placed in the sports-ground scene with imported dialogues")
	campus.free()
	quit()
