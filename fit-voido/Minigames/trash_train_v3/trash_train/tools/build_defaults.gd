extends SceneTree
## Regenerates the sample content: item resources + catalog, player.tscn, npc.tscn, the two sample levels
## and trash_train.tscn. You never need this unless you delete or break those files. It does not touch
## your own scenes. Run it from a terminal:
##   godot --headless --path <your project folder> --script res://trash_train/tools/build_defaults.gd
## (it is also a handy read: it shows how to build a level from code.)

const DIR := "res://trash_train/"


func _initialize() -> void:
	_build_all()
	quit()


func _build_all() -> void:
	DirAccess.make_dir_recursive_absolute(DIR + "items")
	DirAccess.make_dir_recursive_absolute(DIR + "levels")
	var catalog := _build_items()
	_build_player()
	_build_npc()
	_build_template(catalog)
	_build_yard(catalog)
	_build_root()
	print("build_defaults: done")


# --- items ---------------------------------------------------------------------

func _build_items() -> TrashItemCatalog:
	# id, tier, bin_id, colour, placeholder shape (0 square 1 circle 2 diamond 3 triangle), radius, weight
	var specs := [
		["floppy", TrashItems.Tier.NORMAL, &"ewaste", "4f8df0", 0, 10.0, 0.15],
		["nokia", TrashItems.Tier.NORMAL, &"ewaste", "7a6cf0", 0, 10.0, 0.15],
		["crt", TrashItems.Tier.HEAVY, &"ewaste", "2b4fa8", 0, 15.0, 0.12],
		["glitch", TrashItems.Tier.GLITCH, &"ewaste", "e04fe0", 2, 11.0, 0.13],
		["cup", TrashItems.Tier.NORMAL, &"general", "f0a030", 1, 10.0, 0.15],
		["noodle", TrashItems.Tier.NORMAL, &"general", "f0d84a", 1, 10.0, 0.15],
		["paper", TrashItems.Tier.NORMAL, &"general", "ece6d0", 3, 10.0, 0.15],
	]
	var list: Array[TrashItemDef] = []
	for s in specs:
		var d := TrashItemDef.new()
		d.id = StringName(s[0])
		d.tier = s[1]
		d.bin_id = s[2]
		d.placeholder_color = Color(s[3])
		d.placeholder_shape = s[4]
		d.radius = s[5]
		d.spawn_weight = s[6]
		var path: String = DIR + "items/%s.tres" % s[0]
		ResourceSaver.save(d, path)
		list.append(ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as TrashItemDef)
	var catalog := TrashItemCatalog.new()
	catalog.items = list
	ResourceSaver.save(catalog, DIR + "items/catalog.tres")
	return ResourceLoader.load(DIR + "items/catalog.tres", "", ResourceLoader.CACHE_MODE_REPLACE) as TrashItemCatalog


# --- runner and NPC scenes ---------------------------------------------------------

func _build_player() -> void:
	var p := TrashPlayer.new()
	p.name = "TrashPlayer"
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	cs.shape = _circle(14.0)
	p.add_child(cs)
	_save_scene(p, DIR + "player.tscn")


func _build_npc() -> void:
	var n := TrashNpc.new()
	n.name = "TrashNpc"
	var cs := CollisionShape2D.new()
	cs.name = "HitArea"
	cs.shape = _circle(13.0)  # a little smaller than the drawn body, so near misses don't count
	n.add_child(cs)
	_save_scene(n, DIR + "npc.tscn")


# --- levels --------------------------------------------------------------------------

func _build_template(catalog: TrashItemCatalog) -> void:
	var lvl := _level_base("LevelTemplate", Vector2(720.0, 405.0), catalog)
	lvl.get_node("SpawnZones").add_child(_zone("ZoneMain", Vector2(720.0, 405.0), [_rect(1000.0, 640.0)], 1.0))
	_save_scene(lvl, DIR + "levels/level_template.tscn")


func _build_yard(catalog: TrashItemCatalog) -> void:
	var lvl := _level_base("LevelYard", Vector2(720.0, 600.0), catalog)
	var obstacles := lvl.get_node("Obstacles")
	obstacles.add_child(_obstacle("Fountain", Vector2(720, 405), _circle(70.0), Color("8aa4b8")))
	obstacles.add_child(_obstacle("Building", Vector2(720, 120), _rect(280.0, 120.0), Color("8b6f5a")))
	obstacles.add_child(_obstacle("BenchWest", Vector2(400, 290), _rect(130.0, 30.0), Color("6b4a2b")))
	obstacles.add_child(_obstacle("BenchEast", Vector2(1040, 520), _rect(130.0, 30.0), Color("6b4a2b")))
	obstacles.add_child(_obstacle("HedgeSouthWest", Vector2(500, 600), _rect(28.0, 180.0), Color("2f6b3a")))
	obstacles.add_child(_obstacle("HedgeNorthEast", Vector2(940, 210), _rect(28.0, 180.0), Color("2f6b3a")))
	obstacles.add_child(_obstacle("TreeA", Vector2(330, 650), _circle(32.0), Color("245c2f")))
	obstacles.add_child(_obstacle("TreeB", Vector2(395, 695), _circle(26.0), Color("245c2f")))
	obstacles.add_child(_obstacle("TreeC", Vector2(1140, 160), _circle(32.0), Color("245c2f")))
	obstacles.add_child(_obstacle("TreeD", Vector2(1075, 118), _circle(26.0), Color("245c2f")))

	var zones := lvl.get_node("SpawnZones")
	zones.add_child(_zone("ZoneWest", Vector2(335, 535), [_rect(270.0, 410.0)], 1.0))
	zones.add_child(_zone("ZoneEast", Vector2(1105, 295), [_rect(270.0, 450.0)], 1.0))
	zones.add_child(_zone("ZoneSouth", Vector2.ZERO, [PackedVector2Array([Vector2(560, 640), Vector2(880, 640), Vector2(980, 760), Vector2(460, 760)])], 1.2))
	zones.add_child(_zone("ZoneNorthStrip", Vector2(720, 235), [_rect(440.0, 60.0)], 0.5, [catalog.find(&"crt"), catalog.find(&"glitch"), catalog.find(&"floppy")]))
	zones.add_child(_zone("ZonePicnic", Vector2(720, 700), [_circle(80.0)], 0.8))

	var routes := lvl.get_node("Routes")
	routes.add_child(_route("FountainLoop", _ellipse_curve(Vector2(720, 405), 230.0, 150.0), TrashNpcRoute.Mode.LOOP, 0.9))
	routes.add_child(_route("WestGuard", _line_curve([Vector2(250, 120), Vector2(250, 690)]), TrashNpcRoute.Mode.PING_PONG, 0.8))
	routes.add_child(_route("EastGuard", _line_curve([Vector2(1210, 690), Vector2(1210, 120)]), TrashNpcRoute.Mode.PING_PONG, 0.8))
	routes.add_child(_route("SouthSweep", _line_curve([Vector2(470, 730), Vector2(1010, 730)]), TrashNpcRoute.Mode.PING_PONG, 1.0, 2))
	routes.add_child(_route("NorthSweep", _line_curve([Vector2(230, 90), Vector2(520, 90)]), TrashNpcRoute.Mode.PING_PONG, 1.1))
	_save_scene(lvl, DIR + "levels/level_yard.tscn")


func _build_root() -> void:
	var root := TrashTrain.new()
	root.name = "TrashTrain"
	root.level_scene = load(DIR + "levels/level_yard.tscn")
	root.player_scene = load(DIR + "player.tscn")
	root.npc_scene = load(DIR + "npc.tscn")
	root.catalog = load(DIR + "items/catalog.tres")
	_save_scene(root, DIR + "trash_train.tscn")


# --- building blocks -------------------------------------------------------------------

## Ground, Bounds, PlayerStart, empty Obstacles / SpawnZones / Routes, and the two bins.
func _level_base(level_name: String, start: Vector2, catalog: TrashItemCatalog) -> TrashLevel:
	var lvl := TrashLevel.new()
	lvl.name = level_name
	lvl.catalog = catalog
	var ground := TrashGroundGrid.new()
	ground.name = "Ground"
	lvl.add_child(ground)
	var bounds := ReferenceRect.new()
	bounds.name = "Bounds"
	bounds.size = Vector2(1440.0, 810.0)
	lvl.add_child(bounds)
	var marker := Marker2D.new()
	marker.name = "PlayerStart"
	marker.position = start
	lvl.add_child(marker)
	var obstacles := Node2D.new()
	obstacles.name = "Obstacles"
	lvl.add_child(obstacles)
	var bins := Node2D.new()
	bins.name = "Bins"
	lvl.add_child(bins)
	bins.add_child(_bin("BinEwaste", Vector2(75, 405), Vector2(150, 280), [&"ewaste"], &"bin_ewaste", Color("4f8df0")))
	bins.add_child(_bin("BinGeneral", Vector2(1365, 405), Vector2(150, 280), [&"general"], &"bin_general", Color("f0a030")))
	var zones := Node2D.new()
	zones.name = "SpawnZones"
	lvl.add_child(zones)
	var routes := Node2D.new()
	routes.name = "Routes"
	lvl.add_child(routes)
	return lvl


func _bin(bin_name: String, pos: Vector2, size: Vector2, accepts: Array, key: StringName, color: Color) -> TrashBin:
	var b := TrashBin.new()
	b.name = bin_name
	b.position = pos
	var list: Array[StringName] = []
	for a in accepts:
		list.append(a)
	b.accepts = list
	b.label_key = key
	b.color = color
	var cs := CollisionShape2D.new()
	cs.name = "Zone"
	cs.shape = _rect(size.x, size.y)
	b.add_child(cs)
	return b


## shapes: Shape2D resources or PackedVector2Array polygons.
func _zone(zone_name: String, pos: Vector2, shapes: Array, weight: float, kinds: Array = []) -> TrashSpawnZone:
	var z := TrashSpawnZone.new()
	z.name = zone_name
	z.position = pos
	z.weight = weight
	var list: Array[TrashItemDef] = []
	for k in kinds:
		list.append(k)
	z.kinds = list
	for i in shapes.size():
		if shapes[i] is PackedVector2Array:
			var cp := CollisionPolygon2D.new()
			cp.name = "Polygon%d" % i
			cp.polygon = shapes[i]
			z.add_child(cp)
		else:
			var cs := CollisionShape2D.new()
			cs.name = "Shape%d" % i
			cs.shape = shapes[i]
			z.add_child(cs)
	return z


func _obstacle(obstacle_name: String, pos: Vector2, shape: Shape2D, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = obstacle_name
	body.position = pos
	body.collision_layer = TrashLayers.WALLS
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	cs.shape = shape
	body.add_child(cs)
	var look := Polygon2D.new()  # placeholder art: replace with your Sprite2D
	look.name = "Sprite"
	look.polygon = TrashGeometry.shape_outline(shape)
	look.color = color
	body.add_child(look)
	return body


func _route(route_name: String, curve: Curve2D, mode: TrashNpcRoute.Mode, speed: float, count: int = 1) -> TrashNpcRoute:
	var r := TrashNpcRoute.new()
	r.name = route_name
	r.curve = curve
	r.mode = mode
	r.speed_scale = speed
	r.count = count
	return r


func _line_curve(points: Array) -> Curve2D:
	var c := Curve2D.new()
	for p in points:
		c.add_point(p)
	return c


func _ellipse_curve(center: Vector2, rx: float, ry: float) -> Curve2D:
	var c := Curve2D.new()
	for i in 5:  # four quarter arcs; the 5th point closes the loop
		var a := PI * 0.5 * i
		var tangent := Vector2(-sin(a) * rx, cos(a) * ry) * 0.5523
		c.add_point(center + Vector2(cos(a) * rx, sin(a) * ry), -tangent, tangent)
	return c


func _rect(w: float, h: float) -> RectangleShape2D:
	var r := RectangleShape2D.new()
	r.size = Vector2(w, h)
	return r


func _circle(radius: float) -> CircleShape2D:
	var c := CircleShape2D.new()
	c.radius = radius
	return c


func _own_all(node: Node, scene_owner: Node) -> void:
	for c in node.get_children():
		c.owner = scene_owner
		_own_all(c, scene_owner)


func _save_scene(root: Node, path: String) -> void:
	_own_all(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("pack failed for %s: %s" % [path, error_string(err)])
	else:
		err = ResourceSaver.save(packed, path)
		if err != OK:
			push_error("save failed for %s: %s" % [path, error_string(err)])
	root.free()
