extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/recast_%s.png" % name)
func finish_bubble() -> void:
	for i in 30:
		var balloon: Node
		for child in current_scene.get_children():
			if "dialogue_line" in child and "dialogue_label" in child: balloon = child
		if balloon == null: return
		var line = balloon.dialogue_line
		if line == null: return
		balloon.next(line.next_id if line.responses.is_empty() else line.responses[0].next_id)
		await create_timer(0.05).timeout
func run() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	var state = root.get_node("GameState")
	state.save_path = "user://recast_preview_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.set_flag("intro_complete")
	change_scene_to_file("res://scenes/mapsides/nửa đầu.tscn")
	await create_timer(0.2).timeout
	var map = current_scene
	var player = map.get_node("Map/Character")
	var npc = map.get_node("CampusLife/wifi")
	player.global_position = npc.global_position + Vector2(0, 26)
	var camera := Camera2D.new()
	map.add_child(camera)
	camera.global_position = npc.global_position + Vector2(100, 0)
	camera.make_current()
	npc._on_body_entered(player)
	npc.talk()
	await create_timer(0.2).timeout
	# Move through opening and first reply to show the actual response buttons.
	for child in map.get_children():
		if "dialogue_line" in child and "dialogue_label" in child:
			child.dialogue_label.skip_typing()
			await create_timer(0.1).timeout
	await shot("student_choices")
	await finish_bubble()
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	state.set_flag("room416_rescue_complete")
	change_scene_to_file("res://scenes/mapsides/t_4.tscn")
	await create_timer(0.2).timeout
	map = current_scene
	player = map.get_node("Character")
	var door = map.get_node("Room419Door")
	player.position = door.position + Vector2(28,-8)
	camera = Camera2D.new()
	map.add_child(camera)
	camera.position = door.position + Vector2(40, -80)
	camera.make_current()
	door._player = player
	door._talk()
	await create_timer(0.85).timeout
	for child in map.get_children():
		if "dialogue_label" in child: child.dialogue_label.skip_typing()
	await shot("tuan_419")
	await finish_bubble()
	var config := FitRunnerConfig.new()
	config.race_mode = FitRunnerConfig.RaceMode.COMPETITION
	config.lock_mode = true
	var game = load("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd").create(config)
	current_scene.free()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game._begin_run()
	game.model.elapsed = 20.0
	game.model.pos = game.rivals[0].position_at(20.0) - 30
	game.model.pace = 0.85
	game._update_views(0)
	game._refresh_hud(0)
	await create_timer(0.2).timeout
	await shot("khanh_ghost")
	game.free()
	DirAccess.remove_absolute(state.save_path)
	quit()
