@tool
class_name TrashLevel
extends Node2D
## The root of a MAP. Build a map as its own scene (copy levels/level_template.tscn) with this layout:
##
##   Level (this script)
##   |- anything visual: Sprite2D, TileMapLayer, Polygon2D ...        your art
##   |- Bounds        ReferenceRect   the playable rectangle (camera limits + invisible outer walls)
##   |- PlayerStart   Marker2D        where the runner starts
##   |- Obstacles     Node2D          StaticBody2D / TileMapLayer children: the solid stuff to walk around.
##   |                                Their physics layer is set to WALLS for you.
##   |- Bins          Node2D          TrashBin nodes (any parent works; found automatically)
##   |- SpawnZones    Node2D          TrashSpawnZone nodes (any parent works)
##   '- Routes        Node2D          TrashNpcRoute nodes (Path2D), any parent works
##
## Then drop the scene into the TrashTrain root's "Level Scene" slot.

@export var catalog: TrashItemCatalog  ## item kinds this map spawns (empty = the TrashTrain root's catalog)
@export_range(20.0, 400.0, 1.0) var boundary_thickness := 120.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_make_obstacles_solid()
	_build_boundary_walls()


func get_bounds() -> Rect2:
	var b := get_node_or_null("Bounds") as Control
	if b == null:
		return Rect2(0.0, 0.0, 1440.0, 810.0)
	return b.get_global_rect()


func get_player_start() -> Vector2:
	var m := get_node_or_null("PlayerStart") as Node2D
	return m.global_position if m != null else get_bounds().get_center()


func get_bins() -> Array[TrashBin]:
	var out: Array[TrashBin] = []
	for n in get_tree().get_nodes_in_group(&"trash_bin"):
		if is_ancestor_of(n):
			out.append(n as TrashBin)
	return out


func get_spawn_zones() -> Array[TrashSpawnZone]:
	var out: Array[TrashSpawnZone] = []
	for n in get_tree().get_nodes_in_group(&"trash_spawn_zone"):
		if is_ancestor_of(n):
			out.append(n as TrashSpawnZone)
	return out


func get_routes() -> Array[TrashNpcRoute]:
	var out: Array[TrashNpcRoute] = []
	for n in get_tree().get_nodes_in_group(&"trash_route"):
		if is_ancestor_of(n):
			out.append(n as TrashNpcRoute)
	return out


func _get_configuration_warnings() -> PackedStringArray:
	var w := PackedStringArray()
	if not (get_node_or_null("Bounds") is ReferenceRect):
		w.append("Add a ReferenceRect named 'Bounds' that covers the playable area.")
	if not (get_node_or_null("PlayerStart") is Marker2D):
		w.append("Add a Marker2D named 'PlayerStart' where the runner begins.")
	return w


func _make_obstacles_solid() -> void:
	var holder := get_node_or_null("Obstacles")
	if holder == null:
		return
	for n in holder.find_children("*", "PhysicsBody2D", true, false):
		(n as PhysicsBody2D).collision_layer |= TrashLayers.WALLS
	for n in holder.find_children("*", "TileMapLayer", true, false):
		var ts := (n as TileMapLayer).tile_set
		if ts == null:
			continue
		for i in ts.get_physics_layers_count():
			ts.set_physics_layer_collision_layer(i, ts.get_physics_layer_collision_layer(i) | TrashLayers.WALLS)


func _build_boundary_walls() -> void:
	var b := get_bounds()
	var t := boundary_thickness
	var rects: Array[Rect2] = [
		Rect2(b.position.x - t, b.position.y - t, b.size.x + 2.0 * t, t),
		Rect2(b.position.x - t, b.end.y, b.size.x + 2.0 * t, t),
		Rect2(b.position.x - t, b.position.y, t, b.size.y),
		Rect2(b.end.x, b.position.y, t, b.size.y),
	]
	var walls := StaticBody2D.new()
	walls.name = "BoundaryWalls"
	walls.collision_layer = TrashLayers.WALLS
	walls.collision_mask = 0
	add_child(walls)
	for r in rects:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.get_center()
		walls.add_child(cs)
