class_name TrashTailItem
extends Area2D
## One follower in the tail: an Area2D on the TAIL layer, so an NPC's hit area can overlap it
## (the item's own tail_shape decides how big a target it is). Pooled by TrashTail.

var def: TrashItemDef
var index := 0  # place in the tail, 0 = closest to the runner
var dist := 0.0  # arc-length distance behind the runner
var pop := 0.0  # 1 -> 0 right after pick-up
var in_use := false

var _shape := CollisionShape2D.new()


func _init() -> void:
	collision_layer = TrashLayers.TAIL
	collision_mask = 0
	monitoring = false
	monitorable = false
	visible = false
	add_child(_shape)


func use(new_def: TrashItemDef) -> void:
	def = new_def
	in_use = true
	visible = true
	_shape.shape = new_def.get_tail_shape()
	set_deferred("monitorable", true)  # deferred: we may be inside a physics callback
	queue_redraw()


func park() -> void:
	in_use = false
	visible = false
	set_deferred("monitorable", false)


func _draw() -> void:
	if def != null:
		def.draw_on(self)
