extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fight = load("res://Minigames/boss_fight/boss_fight.tscn").instantiate()
	var config := BossFightConfig.new()
	config.difficulty_id = &"normal"
	fight.config = config
	root.add_child(fight)
	await process_frame
	fight.toggle_pause()
	var failed: bool = not paused or not fight._pause_panel.visible
	var enemy = fight.battle.enemy
	var before: Vector2 = enemy.visual.position
	await create_timer(0.4).timeout
	failed = failed or enemy.visual.position.distance_to(before) > 0.1
	# Pattern duration timers must stop too, not only bullets/animations.
	var timer := create_timer(0.15, false)
	await create_timer(0.25).timeout
	failed = failed or timer.time_left <= 0
	fight.toggle_pause()
	failed = failed or paused or fight._pause_panel.visible
	fight.toggle_pause()
	fight.queue_free()
	await process_frame
	failed = failed or paused
	print("Boss pause: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
