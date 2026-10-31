class_name OcclusionFader
extends Area2D

## Target CanvasItem to fade (defaults to parent if not set).
@export var target: CanvasItem

## Extra CanvasItems to fade alongside target (e.g. companion roof/wall layers).
@export var extra_targets: Array[CanvasItem] = []

## Opacity when player is behind/under this object.
@export_range(0.0, 1.0, 0.05) var fade_alpha: float = 0.4

## Duration of fade transition in seconds.
@export var fade_duration: float = 0.2

## If true, and no CollisionShape2D or CollisionPolygon2D exists as a child,
## automatically generate collision shape(s) from TileMapLayer(s).
@export var auto_generate_shape: bool = true

## How much of the bottom of the bounding box to exclude (0.0 to 1.0).
## Excludes the base/trunk so player standing in front doesn't trigger fade.
@export_range(0.0, 0.8, 0.05) var bottom_margin_ratio: float = 0.25

## Extra pixels to extend the trigger upwards to detect player walking down behind.
@export var top_padding: float = 16.0

## Extra pixels to extend the trigger horizontally.
@export var horizontal_padding: float = 4.0

var _fade_tween: Tween


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if target == null and get_parent() is CanvasItem:
		target = get_parent() as CanvasItem

	if auto_generate_shape and not _has_collision_shape():
		_generate_shapes_from_layers()

	_check_initial_overlap.call_deferred()


func _exit_tree() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			return true
	return false


func _generate_shapes_from_layers() -> void:
	var layers: Array[TileMapLayer] = []
	if target is TileMapLayer:
		layers.append(target as TileMapLayer)
	elif target != null:
		for child in target.get_children():
			if child is TileMapLayer:
				layers.append(child as TileMapLayer)

	if get_parent() is TileMapLayer and not layers.has(get_parent()):
		layers.append(get_parent() as TileMapLayer)

	for extra in extra_targets:
		if extra is TileMapLayer and not layers.has(extra):
			layers.append(extra as TileMapLayer)

	var shape_index := 0
	for layer in layers:
		shape_index = _generate_shapes_for_layer(layer, shape_index)


func _generate_shapes_for_layer(layer: TileMapLayer, start_index: int) -> int:
	var used_cells: Array[Vector2i] = layer.get_used_cells()
	if used_cells.is_empty():
		return start_index

	var unvisited: Dictionary = {}
	for cell in used_cells:
		unvisited[cell] = true

	var neighbor_offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]

	var tile_size := Vector2(16, 16)
	if layer.tile_set:
		tile_size = Vector2(layer.tile_set.tile_size)

	var current_index := start_index

	while not unvisited.is_empty():
		var start_cell: Vector2i = unvisited.keys()[0]
		unvisited.erase(start_cell)
		var cluster: Array[Vector2i] = [start_cell]
		var queue: Array[Vector2i] = [start_cell]

		while not queue.is_empty():
			var curr: Vector2i = queue.pop_back()
			for offset in neighbor_offsets:
				var neighbor: Vector2i = curr + offset
				if unvisited.has(neighbor):
					unvisited.erase(neighbor)
					queue.push_back(neighbor)
					cluster.append(neighbor)

		var min_cell := cluster[0]
		var max_cell := cluster[0]
		for c in cluster:
			min_cell.x = mini(min_cell.x, c.x)
			max_cell.x = maxi(max_cell.x, c.x)
			min_cell.y = mini(min_cell.y, c.y)
			max_cell.y = maxi(max_cell.y, c.y)

		var local_tl: Vector2 = layer.map_to_local(min_cell) - (tile_size * 0.5)
		var local_br: Vector2 = layer.map_to_local(max_cell) + (tile_size * 0.5)

		var tl_global: Vector2 = layer.to_global(local_tl)
		var br_global: Vector2 = layer.to_global(local_br)

		var tl_area: Vector2 = to_local(tl_global)
		var br_area: Vector2 = to_local(br_global)

		var left := minf(tl_area.x, br_area.x)
		var right := maxf(tl_area.x, br_area.x)
		var top := minf(tl_area.y, br_area.y)
		var bottom := maxf(tl_area.y, br_area.y)

		var width := right - left
		var height := bottom - top

		var effective_top := top - top_padding
		var effective_bottom := bottom - (height * bottom_margin_ratio)
		var effective_height := effective_bottom - effective_top
		var effective_width := width + (horizontal_padding * 2.0)

		if effective_height <= 0.0 or effective_width <= 0.0:
			continue

		var shape := RectangleShape2D.new()
		shape.size = Vector2(effective_width, effective_height)

		var col := CollisionShape2D.new()
		col.name = "AutoOcclusionShape_%d" % current_index
		col.shape = shape
		col.position = Vector2(left + (width * 0.5), (effective_top + effective_bottom) * 0.5)
		add_child(col)
		current_index += 1

	return current_index


func _check_initial_overlap() -> void:
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	if _get_player_count() > 0:
		_fade_to(fade_alpha)


func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	_fade_to(fade_alpha)


func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	if _get_player_count() == 0:
		_fade_to(1.0)


func _is_player(body: Node2D) -> bool:
	if body.is_in_group(&"player"):
		return true
	if body.name == "Character":
		return true
	return false


func _get_player_count() -> int:
	var count := 0
	for body in get_overlapping_bodies():
		if _is_player(body):
			count += 1
	return count


func _fade_to(target_alpha: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var targets: Array[CanvasItem] = []
	if target and is_instance_valid(target):
		targets.append(target)
	for extra in extra_targets:
		if extra and is_instance_valid(extra) and not targets.has(extra):
			targets.append(extra)

	if targets.is_empty():
		return

	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	for item in targets:
		_fade_tween.tween_property(item, "modulate:a", target_alpha, fade_duration)
