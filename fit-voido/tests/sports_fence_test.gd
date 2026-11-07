extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/mapsides/campus_sports_ground.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var space = scene.get_world_2d().direct_space_state
	var failures := 0
	for pair in [
		[Vector2(1000, 0), Vector2(1000, 100)],
		[Vector2(1000, 1200), Vector2(1000, 1275)],
		[Vector2(0, 300), Vector2(100, 300)],
		[Vector2(0, 1000), Vector2(100, 1000)],
		[Vector2(2350, 800), Vector2(2450, 800)],
	]:
		if space.intersect_ray(PhysicsRayQueryParameters2D.create(pair[0], pair[1], 1)).is_empty():
			failures += 1
			push_error("Fence section does not block travel: %s" % pair)
	if not space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(0, 640), Vector2(100, 640), 1)).is_empty():
		failures += 1
		push_error("West entrance must remain open")
	print("Sports fence: %d failures" % failures)
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
