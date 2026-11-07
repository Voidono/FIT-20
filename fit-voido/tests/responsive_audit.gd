extends SceneTree
## Real UI at compact landscape, tall landscape, desktop and portrait sizes.
## -- --touch-controls render enables phone controls and optional screenshots.
var failures := 0
var label := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(label + ": " + message)

func bounds(c: Control, message: String) -> void:
	var rect := c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)
	check(Rect2(Vector2(-1, -1), Vector2(root.content_scale_size) + Vector2(2, 2)).encloses(rect), message + " " + str(rect))

func settle() -> void:
	for i in 5:
		await process_frame

func capture(suffix: String) -> void:
	await settle()
	if "render" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/responsive_%s_%s.png" % [label, suffix])

func run() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down", &"interact"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var state = root.get_node("GameState")
	state.save_path = "user://responsive_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	TranslationServer.set_locale("vi")
	for dimensions in [Vector2i(640, 360), Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1170, 540), Vector2i(540, 960)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		label = "%dx%d" % [dimensions.x, dimensions.y]
		var menu = load("res://scenes/menu & options/menu.tscn").instantiate()
		root.add_child(menu)
		await settle()
		for child in menu._design.get_children():
			if child is Sprite2D:
				for button in child.get_children():
					if button is Button: bounds(button, "Menu button")
		await capture("menu")
		menu.free()
		var settings = load("res://scenes/menu & options/setting_game.tscn").instantiate()
		root.add_child(settings)
		await settle()
		bounds(settings.get_node("Label/HSlider"), "Master slider")
		bounds(settings.get_node("Label2/Music"), "Music slider")
		await capture("settings")
		settings.free()
		var controls = load("res://scenes/Character/player_mobile_controls.tscn").instantiate()
		controls.mode = 1
		root.add_child(controls)
		await settle()
		bounds(controls._interact_btn, "Interact button")
		bounds(controls._joystick_container, "Joystick")
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.pressed = true
		touch.position = Vector2(60, dimensions.y - 60)
		root.push_input(touch)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = touch.position + Vector2(90, 0)
		drag.relative = Vector2(90, 0)
		root.push_input(drag)
		await settle()
		check(Input.is_action_pressed("move_right"), "Joystick presses movement")
		controls._on_interact_pressed()
		check(not Input.is_action_pressed("interact"), "Interact is released")
		controls.free()
		check(not Input.is_action_pressed("move_right"), "Scene exit releases movement")
		var result = load("res://Minigames/trash_train_v3/trash_train/result_panel.gd").new()
		root.add_child(result)
		var data = load("res://Minigames/trash_train_v3/trash_train/run_result.gd").new()
		data.passed = true
		data.stars = 3
		data.banked_score = 1500
		result.show_result(data, 1000)
		await settle()
		check(result._panel.size.x <= dimensions.x - 24, "Trash result width")
		check(result.retry_button.size.y >= 44, "Trash retry touch target")
		await capture("trash_result")
		result.free()
		var trash = load("res://Minigames/trash_train_v3/trash_train/trash_train.tscn").instantiate()
		trash.skip_tutorial = true
		root.add_child(trash)
		await settle()
		bounds(trash._hud._message, "Trash ready message")
		await capture("trash_ready")
		trash.free()
		var manager = root.get_node("DialogueManager")
		var quiz = manager.create_resource_from_text("~ start\nThầy: Bạn đang đi dạo ở sân trường và bắt gặp một sinh viên khoa FIT đang làm nhiệm vụ hệ thống kiếm điểm Exp. Sinh viên đó đang học môn nào?\n- Machine Learning Applications (MLA)\n\t=> END\n- Web Programming (WPR)\n\t=> END\n- Principle of Operating Systems (POP)\n\t=> END\n- System Analysis and Design (SAD)\n\t=> END")
		var balloon = manager.show_dialogue_balloon_scene(load("res://Dialogues/Bubbles/quiz_balloon (1).tscn"), quiz, "start")
		await create_timer(0.15).timeout
		balloon.dialogue_label.skip_typing()
		await create_timer(0.4).timeout
		await settle()
		bounds(balloon.dock, "Quiz question and answers")
		for tile in balloon.tiles:
			check(tile.size.y >= 44, "Quiz answer touch target")
		await capture("quiz")
		balloon.free()
		var guide = manager.show_dialogue_balloon_scene(load("res://Dialogues/Bubbles/tutorial_balloon.tscn"), load("res://Dialogues/activity_introductions.dialogue"), "boss_fight")
		await create_timer(0.15).timeout
		guide.dialogue_label.skip_typing()
		await create_timer(0.3).timeout
		await settle()
		bounds(guide.card, "Introduction")
		await capture("guide")
		guide.free()
		var runner = load("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_launcher.gd").create()
		root.add_child(runner)
		runner.set_process(false)
		await settle()
		bounds(runner._hud._ready_overlay, "Runner start card")
		await capture("runner_ready")
		runner._begin_run()
		runner._refresh_hud(0)
		await settle()
		bounds(runner._hud._speed_button, "Runner speed button")
		bounds(runner._hud._qte_button, "Runner QTE button")
		await capture("runner_running")
		var race_result = load("res://Minigames/minigames/fit_runner/scripts/api/fit_runner_result.gd").new()
		race_result.passed = true
		race_result.completed = true
		race_result.stars = 3
		race_result.time_sec = 89
		race_result.par_time = 100
		runner._hud.set_phase(FrRunState.Phase.FINISHED, race_result)
		runner._hud._result_panel.show_result(race_result)
		runner._hud._result_panel.show()
		await settle()
		bounds(runner._hud._result_panel, "Runner results")
		await capture("runner_result")
		runner.free()
		var boss = load("res://Minigames/boss_fight/boss_fight.tscn").instantiate()
		root.add_child(boss)
		await settle()
		bounds(boss.frame, "Boss viewport")
		await capture("boss")
		boss.battle.touch_controls.set_active(true)
		await settle()
		if root.get_node("DeviceInput").is_mobile():
			check(boss.battle.touch_controls._joystick != null, "Boss touch joystick exists")
		boss.battle.touch_controls.set_active(false)
		boss.toggle_pause()
		await settle()
		bounds(boss._resume_button, "Boss resume")
		await capture("boss_pause")
		boss.free()
		var gate = load("res://scenes/chapters/time_gate.tscn").instantiate()
		root.add_child(gate)
		await settle()
		check(gate._body.size.x <= dimensions.x - 56, "Ending scroll content width")
		await capture("gate")
		gate.free()
		print("AUDITED: " + label)
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	label = "campus_phone"
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	var campus = load("res://scenes/mapsides/t_4.tscn").instantiate()
	root.add_child(campus)
	current_scene = campus
	campus.get_node("Character").position = Vector2(3000, 430)
	await create_timer(0.3).timeout
	await capture("journal_controls")
	campus.free()
	DirAccess.remove_absolute(state.save_path)
	print("PASS: responsive audit" if failures == 0 else "FAIL: %d responsive checks" % failures)
	quit(0 if failures == 0 else 1)
