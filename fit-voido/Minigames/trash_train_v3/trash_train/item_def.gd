class_name TrashItemDef
extends Resource
## One KIND of trash. Make one .tres per kind (right-click in FileSystem -> New Resource -> TrashItemDef),
## then add it to a TrashItemCatalog. Texture, pickup area and tail hit area are all yours to change.

@export var id: StringName = &"item"
@export var tier: TrashItems.Tier = TrashItems.Tier.NORMAL  ## points / slowdown / glitch behaviour come from the tier
@export var bin_id: StringName = &"general"  ## a bin takes this item if its "accepts" list has this id (or is empty)
@export_range(0.0, 10.0, 0.01) var spawn_weight := 1.0

@export_group("Look")
@export var texture: Texture2D  ## empty = coloured placeholder shape
@export var texture_scale := Vector2.ONE
@export var texture_offset := Vector2.ZERO
@export var placeholder_color := Color.WHITE
@export_enum("Square", "Circle", "Diamond", "Triangle") var placeholder_shape := 1
@export_range(4.0, 40.0, 0.5) var radius := 10.0  ## placeholder size and the default collision size

@export_group("Collision")
@export var pickup_shape: Shape2D  ## area the runner must touch to pick it up. Empty = circle (radius + 4)
@export var tail_shape: Shape2D  ## what NPCs can hit while it trails behind you. Empty = circle (radius - 2)

var _default_pickup: Shape2D
var _default_tail: Shape2D


func goes_in(accepts: Array[StringName]) -> bool:
	return accepts.is_empty() or accepts.has(bin_id)


func get_pickup_shape() -> Shape2D:
	if pickup_shape != null:
		return pickup_shape
	if _default_pickup == null:
		var c := CircleShape2D.new()
		c.radius = radius + 4.0
		_default_pickup = c
	return _default_pickup


func get_tail_shape() -> Shape2D:
	if tail_shape != null:
		return tail_shape
	if _default_tail == null:
		var c := CircleShape2D.new()
		c.radius = maxf(radius - 2.0, 3.0)
		_default_tail = c
	return _default_tail


## Call from inside a CanvasItem's _draw(). Used by ground pickups and tail followers alike.
func draw_on(ci: CanvasItem) -> void:
	if texture != null:
		var size := texture.get_size() * texture_scale
		ci.draw_texture_rect(texture, Rect2(-size * 0.5 + texture_offset, size), false)
		return
	var r := radius
	var edge := placeholder_color.darkened(0.5)
	match placeholder_shape:
		0:
			var rect := Rect2(-r, -r, r * 2.0, r * 2.0)
			ci.draw_rect(rect, placeholder_color)
			ci.draw_rect(rect, edge, false, 2.0)
		1:
			ci.draw_circle(Vector2.ZERO, r, placeholder_color)
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, edge, 2.0)
		2:
			var d := PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
			ci.draw_colored_polygon(d, placeholder_color)
			ci.draw_polyline(PackedVector2Array([d[0], d[1], d[2], d[3], d[0]]), edge, 2.0)
		_:
			var t := PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.8), Vector2(-r, r * 0.8)])
			ci.draw_colored_polygon(t, placeholder_color)
			ci.draw_polyline(PackedVector2Array([t[0], t[1], t[2], t[0]]), edge, 2.0)
