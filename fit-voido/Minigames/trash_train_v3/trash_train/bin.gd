class_name TrashBin
extends Area2D
## A trash can. The zone is whatever CollisionShape2D / CollisionPolygon2D children you draw: the runner
## banks matching items by entering it. Add any Sprite2D / AnimatedSprite2D / StaticBody2D children for
## looks and a solid body. The root script does the banking; this node only reports "runner inside".

@export var accepts: Array[StringName] = []  ## item bin_ids this can take (empty = takes everything)
@export var label_key: StringName = &""  ## key in strings.gd (empty = no label)
@export var color := Color("4f8df0")
@export var draw_zone := true  ## untick once you have your own art
@export var label_font_size := 20

var player_inside := false

var _label := Label.new()


func _ready() -> void:
	collision_layer = TrashLayers.BINS
	collision_mask = TrashLayers.RUNNER
	monitoring = true
	monitorable = true
	add_to_group(&"trash_bin")
	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))
	if label_key != &"":
		var rect := Rect2()
		for child in get_children():
			var pts := TrashGeometry.collision_node_outline(child)
			if not pts.is_empty():
				var r := TrashGeometry.rect_of(pts)
				rect = r if rect.size == Vector2.ZERO else rect.merge(r)
		_label.text = TrashStrings.t(label_key)
		_label.position = rect.position
		_label.size = rect.size
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_font_size_override("font_size", label_font_size)
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_label.add_theme_constant_override("outline_size", 6)
		add_child(_label)
	queue_redraw()


func takes(def: TrashItemDef) -> bool:
	return def.goes_in(accepts)


func _on_body(body: Node2D, entered: bool) -> void:
	if body.is_in_group(&"trash_player"):
		player_inside = entered
		queue_redraw()


func _draw() -> void:
	if draw_zone:
		TrashGeometry.draw_zone(self, self, Color(color, 0.45 if player_inside else 0.25), color)
