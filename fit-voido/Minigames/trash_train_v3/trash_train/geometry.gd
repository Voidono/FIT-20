class_name TrashGeometry
extends RefCounted
## Turns the shapes a designer draws (CollisionShape2D / CollisionPolygon2D) into outlines,
## so spawn zones can pick random points inside them and bins can draw / label themselves.

const HALF_SEGMENTS := 12


static func shape_outline(shape: Shape2D) -> PackedVector2Array:
	var out := PackedVector2Array()
	if shape is RectangleShape2D:
		var h := (shape as RectangleShape2D).size * 0.5
		out.append(Vector2(-h.x, -h.y))
		out.append(Vector2(h.x, -h.y))
		out.append(Vector2(h.x, h.y))
		out.append(Vector2(-h.x, h.y))
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		for i in HALF_SEGMENTS * 2:
			out.append(Vector2.from_angle(TAU * i / (HALF_SEGMENTS * 2)) * r)
	elif shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		var r := cap.radius
		var half := maxf(cap.height * 0.5 - r, 0.0)
		for i in range(0, HALF_SEGMENTS + 1):  # over the top, left to right
			out.append(Vector2(0.0, -half) + Vector2.from_angle(PI + PI * i / HALF_SEGMENTS) * r)
		for i in range(0, HALF_SEGMENTS + 1):  # under the bottom, right to left
			out.append(Vector2(0.0, half) + Vector2.from_angle(PI * i / HALF_SEGMENTS) * r)
	elif shape is ConvexPolygonShape2D:
		out = (shape as ConvexPolygonShape2D).points
	return out


## Outline of a CollisionShape2D / CollisionPolygon2D in its PARENT's space. Empty if unsupported or disabled.
static func collision_node_outline(node: Node) -> PackedVector2Array:
	if node is CollisionShape2D:
		var cs := node as CollisionShape2D
		if cs.disabled or cs.shape == null:
			return PackedVector2Array()
		return cs.transform * shape_outline(cs.shape)
	if node is CollisionPolygon2D:
		var cp := node as CollisionPolygon2D
		if cp.disabled:
			return PackedVector2Array()
		return cp.transform * cp.polygon
	return PackedVector2Array()


static func rect_of(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var lo := points[0]
	var hi := points[0]
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo, hi - lo)


## Draw every shape child of `owner` as a filled zone (placeholder art for bins).
static func draw_zone(ci: CanvasItem, owner: Node, fill: Color, edge: Color) -> void:
	for child in owner.get_children():
		var pts := collision_node_outline(child)
		if pts.size() < 3 or Geometry2D.triangulate_polygon(pts).is_empty():
			continue
		ci.draw_colored_polygon(pts, fill)
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, edge, 4.0)
