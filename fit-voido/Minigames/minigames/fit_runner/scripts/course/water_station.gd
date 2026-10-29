class_name FrWaterStation
extends FrCourseProp
## Water station: spreads the tables under %Tables along span_fraction of the track and keeps them on the ground.

@onready var _tables: Node2D = FrLookup.node(self, "Tables") as Node2D


func _on_placed(tuning: FrTuning, profile: FrCourseProfile, ground_y: float) -> void:
	var span: float = span_fraction * tuning.track_length
	var count: int = _tables.get_child_count()
	for i in range(count):
		var table := _tables.get_child(i) as Node2D
		if table == null:
			continue
		var t: float = float(i) / float(maxi(count - 1, 1))
		var local_x: float = lerpf(40.0, maxf(span - 40.0, 40.0), t)
		var world_x: float = position.x + local_x
		table.position = Vector2(local_x, (ground_y - profile.height_at(world_x)) - position.y)
