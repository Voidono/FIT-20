extends SceneTree
const ROUTE = preload("res://scenes/UI/quests/quest_destination.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://waypoint_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	# Resolve every objective against real maps, so renamed/missing targets fail.
	for map_name in ["nửa đầu", "t_2", "t_3", "t_4", "phòng_máy_2"]:
		var scene = load("res://scenes/mapsides/%s.tscn" % map_name).instantiate()
		for id in ROUTE.DESTINATIONS:
			var targets := ROUTE.resolve(scene, id)
			check(not targets.is_empty(), "Route exists: " + map_name + " / " + id)
			for item in targets:
				check(item.node is Node2D, "Live target node")
		if map_name == "t_2":
			check(ROUTE.resolve(scene, "enter_room_417")[0].node.name == "StairsToFloor3", "Go upstairs before classroom")
		if map_name == "t_4":
			check(ROUTE.resolve(scene, "find_thay_tuan")[0].node.name == "StairsDownToFloor3", "Go downstairs before outdoor coach")
		if map_name == "phòng_máy_2":
			check(ROUTE.resolve(scene, "choose_room417_seat").size() == 2, "Both seating groups marked")
			check(ROUTE.resolve(scene, "reach_room_416")[0].node.name == "SceneDoor", "Leave classroom before room416")
		check(ROUTE.resolve(scene, "journey_complete").is_empty(), "Completed journey has no marker")
		scene.free()
	# Exercise actual projection with moving camera and HUD folding.
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	change_scene_to_file("res://scenes/mapsides/nửa đầu.tscn")
	await create_timer(0.4).timeout
	var journal = root.get_node("QuestTracker")
	var marker: Control
	for child in journal.get_children():
		if "targets" in child: marker = child
	check(marker != null, "Journal owns marker")
	check(marker.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Marker does not capture input")
	check(marker.targets.size() == 1 and marker.targets[0].node.name == "Minh", "Starts at Minh")
	await capture("minh")
	state.set_flag("intro_complete")
	await create_timer(0.3).timeout
	check(marker.targets[0].node.name == "Lecturer", "Progress updates marker to lecturer")
	await capture("offscreen")
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	await create_timer(0.2).timeout
	await capture("phone")
	for position in marker.marker_positions:
		check(Rect2(Vector2.ZERO, Vector2(640, 360)).has_point(position), "Offscreen marker stays in viewport")
	root.get_node("DialogueManager").dialogue_started.emit(null)
	await process_frame
	check(not marker.visible, "Marker hidden during dialogue")
	root.get_node("DialogueManager").dialogue_ended.emit(null)
	await process_frame
	check(marker.visible, "Marker restores after dialogue")
	paused = true
	# Like the rest of the HUD, it is behind the pause overlay, without input.
	paused = false
	DirAccess.remove_absolute(state.save_path)
	print("Quest waypoints: %d failures" % failures)
	quit(0 if failures == 0 else 1)
func capture(id: String) -> void:
	if "render" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/waypoint_%s.png" % id)
