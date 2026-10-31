class_name TrashSpawnZone
extends Area2D
## A region where trash may appear. Add CollisionShape2D (rectangle / circle / capsule / convex) and/or
## CollisionPolygon2D children and draw the area you want; points are picked uniformly inside it.
## It does no physics itself. Rotate, scale or move it freely.

@export_range(0.0, 20.0, 0.1) var weight := 1.0  ## relative share of spawns this zone gets
@export var kinds: Array[TrashItemDef] = []  ## only these kinds spawn here (empty = whole catalog)
@export_range(0, 200, 1) var max_alive := 0  ## cap on items from this zone on the ground (0 = no cap)
@export var allow_powerups := true  ## power-up pickups may spawn inside this zone

var alive := 0  # maintained by the spawner

var _parts: Array[Dictionary] = []  # {node, tris, areas, area}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	add_to_group(&"trash_spawn_zone")
	rebuild()


## Re-read the shape children (call it if you change them at runtime).
func rebuild() -> void:
	_parts.clear()
	for child in get_children():
		var outline := TrashGeometry.collision_node_outline(child)
		if outline.size() < 3:
			continue
		var idx := Geometry2D.triangulate_polygon(outline)
		if idx.is_empty():
			push_warning("TrashSpawnZone '%s': shape '%s' is not a simple polygon, ignored." % [name, child.name])
			continue
		var tris := PackedVector2Array()
		var areas := PackedFloat32Array()
		var total := 0.0
		for i in range(0, idx.size(), 3):
			var a := outline[idx[i]]
			var b := outline[idx[i + 1]]
			var c := outline[idx[i + 2]]
			tris.append(a)
			tris.append(b)
			tris.append(c)
			var tri_area := absf((b - a).cross(c - a)) * 0.5
			areas.append(tri_area)
			total += tri_area
		_parts.append({"node": child, "tris": tris, "areas": areas, "area": total})


func has_area() -> bool:
	return not _parts.is_empty()


## Uniformly random point inside the zone, in world coordinates.
func sample(rng: RandomNumberGenerator) -> Vector2:
	if _parts.is_empty():
		return global_position
	var weights := PackedFloat32Array()
	var total := 0.0
	for part in _parts:
		var node: Node2D = part["node"]
		var w: float = part["area"] * absf(node.global_transform.determinant())
		weights.append(w)
		total += w
	if total <= 0.0:
		return global_position
	var r := rng.randf() * total
	var pi := _parts.size() - 1
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			pi = i
			break
	var chosen: Dictionary = _parts[pi]
	var areas: PackedFloat32Array = chosen["areas"]
	var tris: PackedVector2Array = chosen["tris"]
	var pick := rng.randf() * float(chosen["area"])
	var ti := areas.size() - 1
	for i in areas.size():
		pick -= areas[i]
		if pick <= 0.0:
			ti = i
			break
	var u := rng.randf()
	var v := rng.randf()
	if u + v > 1.0:
		u = 1.0 - u
		v = 1.0 - v
	var a := tris[ti * 3]
	var p := a + (tris[ti * 3 + 1] - a) * u + (tris[ti * 3 + 2] - a) * v
	return (chosen["node"] as Node2D).global_transform * p


func contains(point: Vector2) -> bool:
	for part in _parts:
		var node: Node2D = part["node"]
		var local := node.global_transform.affine_inverse() * point
		var tris: PackedVector2Array = part["tris"]
		for i in range(0, tris.size(), 3):
			if _in_triangle(local, tris[i], tris[i + 1], tris[i + 2]):
				return true
	return false


static func _in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := (b - a).cross(p - a)
	var d2 := (c - b).cross(p - b)
	var d3 := (a - c).cross(p - c)
	var has_neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_neg and has_pos)
