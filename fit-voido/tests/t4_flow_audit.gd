extends SceneTree
const ROUTES = preload("res://scenes/UI/quests/quest_destination.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://t4_audit_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.set_flag("intro_complete")
	state.award_time_stone(1)
	state.award_time_stone(2)
	change_scene_to_file("res://scenes/mapsides/t_4.tscn")
	await create_timer(0.4).timeout
	var map = current_scene
	var player = map.get_node("Character")
	var tiles = map.find_child("sàn",true,false)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player.get_node("CollisionShape2D").shape
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var offset: Vector2 = player.get_node("CollisionShape2D").global_position - player.global_position
	var clear := func(point: Vector2) -> bool:
		query.transform = Transform2D(0, point + offset)
		return map.get_world_2d().direct_space_state.intersect_shape(query).is_empty()
	for node in map.find_children("*", "Area2D",true,false):
		if "target_scene" in node:
			print("LINK ",node.get_path()," at ",node.global_position," -> ",node.target_scene," spawn ",node.target_position)
	for id in ["enter_room_417","reach_room_416","reach_room_419","find_thay_tuan","deliver_marathon_documents"]:
		var targets = ROUTES.resolve(map,id)
		print("GUIDANCE ", id," targets=",targets.size())
	var cells := {}
	for x in range(0, 3265, 16):
		for y in range(0, 577, 16):
			var p := Vector2(x,y)
			if tiles.get_cell_source_id(tiles.local_to_map(tiles.to_local(p))) != -1 and clear.call(p): cells[Vector2i(x/16,y/16)] = true
	var start := Vector2i(98,11)
	var reached := {}
	var queue: Array[Vector2i] = []
	if cells.has(start):
		queue.append(start)
		reached[start] = true
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if cells.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	print("FLOOR connected cells ", reached.size()," / ",cells.size())
	for point in [Vector2(1562.5,170),Vector2(2723,300),Vector2(2786,305),Vector2(3100,175),Vector2(2868,443),Vector2(2890,451),Vector2(2040,170)]:
		var near := false
		for cell in reached:
			if Vector2(cell * 16).distance_to(point) <= 32: near = true
		print("POINT ",point," clear=",clear.call(point)," near reachable floor=",near)
	if "render" in OS.get_cmdline_user_args():
		root.size = Vector2i(1200,600)
		root.content_scale_size = root.size
		var camera := Camera2D.new()
		map.add_child(camera)
		camera.position = Vector2(1640,280)
		camera.zoom = Vector2.ONE * 0.35
		camera.make_current()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/t4_flow_overview.png")
	DirAccess.remove_absolute(state.save_path)
	quit()
