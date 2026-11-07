extends SceneTree
const ART := "res://Minigames/trash_train_v3/trash_train/levels/temo/"
var out: Node2D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	out = Node2D.new()
	out.name = "CampusSportsGround"
	box("ConcretePaths", Rect2(0, 0, 2450, 1275), Color("aaa99e"))
	for x in range(0, 2451, 64):
		line("ConcreteJoint", [Vector2(x, 0), Vector2(x, 1275)], Color("99998f"), 1)
	for y in range(0, 1276, 64):
		line("ConcreteJoint", [Vector2(0, y), Vector2(2450, y)], Color("99998f"), 1)
	box("TrackSurface", Rect2(104, 280, 2242, 902), Color("777a76"))
	for lane in range(5):
		var inset := lane * 13.0
		line("TrackLane", rounded_rect(Rect2(112 + inset, 288 + inset, 2226 - inset * 2, 886 - inset * 2), 45), Color("d9d7c5"), 2, true)
	grass(Rect2(178, 354, 2094, 744))
	for row in range(2):
		for col in range(2):
			pitch(Rect2(190 + col * 1044, 366 + row * 366, 1026, 348))
	sprite("Basketball", ART + "d4a06e24-5955-4ff5-90fa-ef3c652baf60.png", Rect2(252, 67, 520, 190))
	sprite("SmallCourt1", ART + "Baseball.png", Rect2(982, 67, 480, 190))
	sprite("SmallCourt2", ART + "Baseball.png", Rect2(1692, 67, 480, 190))
	var bin_dir := "res://Minigames/trash_train_v3/trash_train/levels/"
	for p in [Vector2(135, 174), Vector2(2320, 174), Vector2(135, 1190), Vector2(2320, 1190)]:
		sprite("Bin", bin_dir + "ME_Singles_City_Props_32x32_Green_Open_Empty_Trash_Can.png", Rect2(p - Vector2(16, 24), Vector2(32, 48)))
	fence()
	var packed := PackedScene.new()
	packed.pack(out)
	var error := ResourceSaver.save(packed, "res://scenes/mapsides/campus_sports_ground.tscn")
	print("Sports ground saved: ", error)
	if not "fence" in OS.get_cmdline_user_args():
		remove_trees()
	out.free()
	quit(0 if error == OK else 1)

func fence() -> void:
	# Enclose the entire sports complex; west gate opens toward the campus.
	var sections := [
		Rect2(40, 38, 2370, 8), Rect2(40, 1229, 2370, 8),
		Rect2(40, 38, 8, 512), Rect2(40, 730, 8, 507),
		Rect2(2402, 38, 8, 1199),
	]
	var body := StaticBody2D.new()
	body.name = "PerimeterFence"
	body.collision_layer = 1
	body.collision_mask = 0
	add(body)
	for rect in sections:
		box("FenceShadow", Rect2(rect.position + Vector2(3, 3), rect.size + Vector2(3, 3)), Color("66685f"))
		box("FenceRail", rect, Color("c4c8bd"))
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.get_center()
		body.add_child(collision, true)
		collision.owner = out
	for y in [42, 1233]:
		for x in range(40, 2411, 24):
			box("FencePicket", Rect2(x - 1, y - 18, 3, 25), Color("e0e3d7"))
		line("FenceTopRail", [Vector2(40, y - 14), Vector2(2410, y - 14)], Color("9fa89e"), 3)
	for x in [44, 2406]:
		for y in range(42, 1234, 24):
			if x == 44 and y > 550 and y < 730:
				continue
			box("FencePost", Rect2(x - 3, y - 10, 6, 16), Color("e0e3d7"))
	for y in [550, 730]:
		box("GatePost", Rect2(36, y - 20, 16, 24), Color("dfe0cd"))
		box("GateCap", Rect2(34, y - 24, 20, 5), Color("7f897b"))

func box(label: String, rect: Rect2, color: Color) -> void:
	var n := Polygon2D.new()
	n.name = label
	n.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	n.color = color
	add(n)

func line(label: String, points: PackedVector2Array, color: Color, width: float, closed := false) -> void:
	var n := Line2D.new()
	n.name = label
	n.points = points
	n.default_color = color
	n.width = width
	n.closed = closed
	add(n)

func add(n: Node) -> void:
	out.add_child(n, true)
	n.owner = out

func sprite(label: String, path: String, rect: Rect2) -> void:
	var n := Sprite2D.new()
	n.name = label
	n.texture = load(path)
	n.position = rect.get_center()
	n.scale = rect.size / n.texture.get_size()
	add(n)

func rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var centers := [rect.position + Vector2(radius, radius), Vector2(rect.end.x - radius, rect.position.y + radius), rect.end - Vector2(radius, radius), Vector2(rect.position.x + radius, rect.end.y - radius)]
	for corner in range(4):
		for i in range(9):
			var angle := PI + corner * PI / 2 + i * PI / 16
			pts.append(centers[corner] + Vector2.from_angle(angle) * radius)
	return pts

func grass(rect: Rect2) -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(ART + "ME_Singles_School_32x32_Soccer_Court_1.png")
	atlas.texture_region_size = Vector2i(32, 32)
	atlas.margins = Vector2i(16, 80)
	atlas.create_tile(Vector2i.ZERO)
	tiles.add_source(atlas, 0)
	for strip in range(18):
		box("MowingStripe", Rect2(rect.position + Vector2(strip * rect.size.x / 18, 0), Vector2(rect.size.x / 18, rect.size.y)), Color("699750") if strip % 2 == 0 else Color("7fa55a"))
		var layer := TileMapLayer.new()
		layer.name = "GrassStrip%02d" % strip
		layer.tile_set = tiles
		layer.position = rect.position + Vector2(strip * rect.size.x / 18, 0)
		layer.scale = Vector2(rect.size.x / 18 / 128.0, rect.size.y / 768.0)
		layer.modulate = Color(1, 1, 1, 0.10)
		for x in range(4):
			for y in range(24):
				layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
		add(layer)

func pitch(rect: Rect2) -> void:
	var white := Color("e2e7cf")
	line("PitchBoundary", rounded_rect(rect, 0), white, 3, true)
	line("Halfway", [Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y)], white, 3)
	var circle := PackedVector2Array()
	for i in range(64):
		circle.append(rect.get_center() + Vector2.from_angle(i * TAU / 64) * 62)
	line("CenterCircle", circle, white, 3, true)
	for side in [0, 1]:
		var x := rect.position.x if side == 0 else rect.end.x
		var dir := 1 if side == 0 else -1
		for dims in [Vector2(160, 96), Vector2(56, 50)]:
			line("PenaltyArea", [Vector2(x, rect.get_center().y - dims.y), Vector2(x + dir * dims.x, rect.get_center().y - dims.y), Vector2(x + dir * dims.x, rect.get_center().y + dims.y), Vector2(x, rect.get_center().y + dims.y)], white, 3)
		box("GoalNet", Rect2(x - (20 if side == 0 else 0), rect.get_center().y - 34, 20, 68), Color("c2c9be"))
		for j in range(1, 7):
			line("NetMesh", [Vector2(x - (20 if side == 0 else 0), rect.get_center().y - 34 + j * 10), Vector2(x + (20 if side == 1 else 0), rect.get_center().y - 34 + j * 10)], Color("717b72"), 1)

func remove_trees() -> void:
	var path := "res://scenes/mapsides/map.tscn"
	var text := FileAccess.get_file_as_string(path)
	var map = load(path).instantiate()
	var region := Rect2(3375, 475, 2450, 1275)
	var removed := 0
	for path_to_layer in ["cây", "cây to/cây to", "Cây to 2/cây to"]:
		var layer = map.get_node(path_to_layer) as TileMapLayer
		var changed := false
		for cell in layer.get_used_cells():
			var atlas = layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
			if atlas == null:
				continue
			var size := Vector2(atlas.get_tile_texture_region(layer.get_cell_atlas_coords(cell)).size)
			var origin := Vector2(layer.get_cell_tile_data(cell).texture_origin)
			var cell_rect := Rect2(Vector2(layer.map_to_local(cell)) - origin - size / 2, size)
			if (layer.get_global_transform() * cell_rect).intersects(region):
				layer.erase_cell(cell)
				changed = true
				removed += 1
		if changed:
			var replacement := 'tile_map_data = PackedByteArray("%s")' % Marshalls.raw_to_base64(layer.tile_map_data)
			if path_to_layer == "cây":
				var start := text.find('[node name="cây" type="TileMapLayer"')
				var data_start := text.find('tile_map_data = PackedByteArray("', start)
				var data_end := text.find('\n', data_start)
				text = text.substr(0, data_start) + replacement + text.substr(data_end)
			else:
				var parent_path := String(path_to_layer).get_base_dir()
				text += '\n[node name="cây to" parent="%s" index="0"]\n%s\n\n[editable path="%s"]\n' % [parent_path, replacement, parent_path]
	if removed > 0:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(text)
	print("Tree cells replaced by concrete: ", removed)
	map.free()
