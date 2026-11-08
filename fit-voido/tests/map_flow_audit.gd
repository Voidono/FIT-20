extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for file in ["nửa đầu", "t_2", "t_3", "t_4", "phòng_máy_2"]:
		var map = load("res://scenes/mapsides/%s.tscn" % file).instantiate()
		print("MAP: ", file)
		for node in map.find_children("*", "Area2D", true, false):
			if "target_scene" in node and not str(node.target_scene).is_empty():
				print("  ", map.get_path_to(node), " -> ", node.target_scene, " arrival=", node.target_position, " chapter=", node.required_chapter, " activation=", node.activation)
			if "dialogue" in node and node.dialogue != null and (str(node.name).contains("Recipient") or str(node.name).contains("Boss")):
				print("  STORY: ", node.name, " @ ", node.position, " ", node.dialogue.resource_path)
		map.free()
	quit()
