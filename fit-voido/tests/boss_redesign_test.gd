extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(960, 720)
	var fight = load("res://Minigames/boss_fight/boss_fight.tscn").instantiate()
	var config := BossFightConfig.new()
	config.skill_id = &"poison"
	config.difficulty_id = &"normal"
	fight.config = config
	root.add_child(fight)
	await process_frame
	await process_frame
	check(not fight.battle.difficulty_menu.visible, "Configured Normal starts directly")
	check(fight.battle.difficulty_menu.size == Vector2(640, 480), "Difficulty menu fills the isolated battle viewport")
	check(fight.battle.get_node_or_null("DebugPanel") == null, "Story defaults do not expose debug cheats")
	check(fight.battle.hud.get_node_or_null("NameRow/LvLabel") == null, "Character level removed")
	var enemy = fight.battle.enemy
	for i in range(3):
		enemy.set_hp_ratio([1.0, 0.60, 0.30][i])
		enemy.update_phase()
		var expected: String = ["Phase1.png", "phase2.png", "phase3.png"][i]
		check(enemy.visual.texture.resource_path.ends_with(expected), "Correct artwork in phase %d" % (i + 1))
		check(not enemy.visual.show_placeholder, "Placeholder hidden")
		var extent: Vector2 = enemy.visual.texture.get_size() * enemy.visual.scale
		check(extent.y <= 180 and extent.x <= 200, "Artwork fits boss area")
		if "render" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/boss_phase%d.png" % (i + 1))
	for preset in ["easy", "normal", "hard"]:
		var result := BossFightResult.new()
		result.outcome = &"win"
		result.difficulty = load("res://Minigames/boss_fight/data/difficulty/%s.tres" % preset)
		result.max_hp = result.difficulty.player_max_hp
		result.final_hp = result.max_hp
		result.calculate_score()
		check(result.score == roundi(2000 * result.difficulty.score_multiplier), "Full-health score: " + preset)
		result.final_hp = 0
		result.calculate_score()
		check(result.score == roundi(1000 * result.difficulty.score_multiplier), "Base score: " + preset)
		result.outcome = &"spared"
		result.calculate_score()
		check(result.score == 0, "Spare earns no victory points")
	var captured: Array[BossFightResult] = []
	fight.free_when_finished = false
	fight.finished.connect(func(result: BossFightResult): captured.append(result))
	fight.battle.stats.hp = 10
	fight._on_battle_finished(&"win")
	check(captured.size() == 1 and captured[0].score == 2250 and captured[0].final_hp == 10, "Result adapter captures remaining health and difficulty")
	if "render" in OS.get_cmdline_user_args():
		var menu = fight.battle.difficulty_menu
		menu._options = fight.battle.get_difficulties()
		menu.show()
		menu.choices.call_deferred("choose", PackedStringArray(["Easy ×1.0", "Normal ×1.5", "Hard ×2.0"]))
		menu._on_focused(1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/boss_score_explanation.png")
	var state = root.get_node("GameState")
	state.save_path = "user://boss_score_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	for stone in range(1, 4):
		state.award_time_stone(stone)
	state.choose_skill(&"fist")
	state.record_activity_result("boss_fight", {"passed": true, "score": 3000})
	state.record_activity_result("boss_fight", {"passed": true, "score": 1500})
	state.record_activity_result("boss_fight", {"passed": false, "score": 9999})
	state.load_game()
	check(state.activity_result("boss_fight").best_score == 3000, "Best score persists without replay farming")
	DirAccess.remove_absolute(state.save_path)
	fight.queue_free()
	await process_frame
	print("Boss redesign: %d failures" % failures)
	quit(1 if failures else 0)
