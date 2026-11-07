extends SceneTree
## Extract static, editable artwork; do not bring minigame controllers into campus.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var source = load("res://Minigames/trash_train_v3/trash_train/levels/Field.tscn").instantiate()
	var out := Node2D.new()
	out.name = "CampusSportsGround"
	var clip := Control.new()
	clip.name = "SportsArea"
	clip.size = Vector2(2450, 1275)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	out.add_child(clip)
	clip.owner = out
	# The destination is wider than Field: keep pixel-art proportions and add
	# paved side concourses instead of stretching pitches horizontally.
	var background := Polygon2D.new()
	background.name = "Concourse"
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(2450, 0), Vector2(2450, 1275), Vector2(0, 1275)])
	background.color = Color("666466")
	clip.add_child(background)
	background.owner = out
	var art := Node2D.new()
	art.name = "FieldArtwork"
	var factor := 1275.0 / 1158.0
	art.scale = Vector2.ONE * factor
	art.position = Vector2((2450.0 - 1373.0 * factor) / 2.0 + 149.0 * factor, 255.0 * factor)
	clip.add_child(art)
	art.owner = out
	for child in source.get_children():
		if child is TileMapLayer or child is Sprite2D or child.name == "Obstacles":
			var copy = child.duplicate()
			clean(copy)
			art.add_child(copy)
			own(copy, out)
	# Decorative bin sprites only: no banking areas, spawn zones or NPC routes.
	for name in ["BinGeneral", "BinGeneral2", "BinEwaste", "BinEwaste2"]:
		var bin = source.get_node(name)
		var sprite = bin.get_node("Sprite2D").duplicate()
		sprite.name = name
		sprite.position += bin.position
		art.add_child(sprite)
		sprite.owner = out
	var packed := PackedScene.new()
	packed.pack(out)
	var error := ResourceSaver.save(packed, "res://scenes/mapsides/campus_sports_ground.tscn")
	print("Sports ground saved: ", error)
	out.free()
	source.free()
	quit(0 if error == OK else 1)

func clean(node: Node) -> void:
	node.set_script(null)
	for child in node.get_children():
		clean(child)
	if node is TileMapLayer:
		# Campus walls use layer 1. Disable fencing collisions here so the
		# exploration route stays open; goalposts retain their solid bodies.
		node.collision_enabled = false
	if node is StaticBody2D:
		node.collision_layer = 1
		node.collision_mask = 0

func own(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		own(child, owner_node)
