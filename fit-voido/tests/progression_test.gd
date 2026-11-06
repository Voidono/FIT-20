extends SceneTree
## Runs against disposable save files; never opens the player's actual save.

const STATE = preload("res://scripts/game_state.gd")
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		push_error("FAIL: " + description)
		quit(1)
		assert(condition, description)


func _run() -> void:
	for path in ["res://Dialogues/minigame_runner.dialogue", "res://Dialogues/minigame_trash.dialogue", "res://Dialogues/minigame_battle.dialogue"]:
		var compiled = DMCompiler.compile_string(FileAccess.get_file_as_string(path), path)
		_check(compiled.errors.is_empty(), "activity conversation compiles: " + path)
	var state = STATE.new()
	state.save_path = "user://progression_test_%d.cfg" % Time.get_ticks_usec()
	root.add_child(state)
	_check(state.is_chapter_unlocked(1), "chapter one starts unlocked")
	_check(not state.is_chapter_unlocked(2), "chapter two starts locked")
	_check(not state.award_time_stone(2), "cannot skip stone prerequisites")
	_check(not state.award_time_stone(0), "invalid stones rejected")
	_check(not state.choose_skill(&"poison"), "seating choice requires chapter two")
	_check(not state.can_start_activity("unknown"), "unknown activity rejected")
	_check(not state.can_start_activity("boss_fight"), "boss requires chapter four and skill")
	state.start_quest("garbage_quest")
	_check(state.record_activity_result("garbage_quest", {"passed": false, "stars": 0}), "failed attempt recorded")
	_check(not state.has_completed_quest("garbage_quest"), "failure cannot complete quest")
	state.record_activity_result("garbage_quest", {"passed": true, "stars": 2})
	_check(state.has_completed_quest("garbage_quest"), "pass completes quest before Continue")
	state.start_quest("garbage_quest")
	state.record_activity_result("garbage_quest", {"passed": false, "stars": 0})
	_check(state.has_completed_quest("garbage_quest"), "replay failure cannot regress completion")
	var history: Dictionary = state.activity_result("garbage_quest")
	_check(history.attempts == 3 and history.failures == 2 and history.best_stars == 2 and history.passed, "attempt history retains best and pass")
	_check(state.award_time_stone(1), "first stone awarded")
	_check(not state.award_time_stone(1), "duplicate stone rejected")
	_check(state.time_stone_count() == 1 and state.is_chapter_unlocked(2), "stone unlocks next chapter")
	_check(state.choose_skill(&"poison"), "valid seating skill saved")
	_check(not state.choose_skill(&"fist"), "seating choice cannot be overwritten")
	_check(not state.choose_skill(&"invalid"), "invalid skill rejected")
	_check(state.grant_quest_item("marathon_documents"), "documents acquired")
	_check(state.deliver_quest_item("marathon_documents"), "documents delivered")
	_check(not state.has_quest_item("marathon_documents"), "delivery consumes possession")
	_check(not state.deliver_quest_item("marathon_documents"), "cannot deliver twice")
	_check(not state.grant_quest_item("marathon_documents"), "cannot reissue delivered documents")
	_check(not state.set_return_point("res://missing.tscn", Vector2.ZERO), "invalid checkpoint rejected")
	_check(state.set_return_point("res://scenes/menu & options/menu.tscn", Vector2(123, 456)), "valid checkpoint saved")
	var restored = STATE.new()
	restored.save_path = state.save_path
	root.add_child(restored)
	_check(restored.has_time_stone(1) and restored.selected_skill() == &"poison", "stone and skill survive reload")
	_check(restored.has_flag("delivered:marathon_documents"), "delivery survives reload")
	_check(restored.activity_result("garbage_quest").failures == 2, "assistance counters survive reload")
	_check(restored.return_point().position == Vector2(123, 456), "return position survives reload")
	_check(not restored.complete_ending(), "ending requires four stones and placements")
	for number in range(2, 5):
		_check(restored.award_time_stone(number), "sequential stone %d" % number)
	_check(restored.can_start_activity("boss_fight"), "boss unlocks with skill and three stones")
	for number in range(1, 5):
		_check(restored.place_time_stone(number), "gate slot %d" % number)
	_check(restored.complete_ending(), "all slots enable ending")
	_check(not restored.complete_ending(), "ending is idempotent")
	restored.quiz_begin("test", 5)
	restored.reset_progress()
	_check(restored.time_stone_count() == 0 and restored.selected_skill() == &"", "New Game clears journey")
	_check(restored.return_point().is_empty() and restored.activity_result("garbage_quest").is_empty(), "New Game clears checkpoints and results")
	_check(restored.quiz_session_id.is_empty(), "New Game clears active quiz")
	# Simulate an older save with no journey section; old stone flags still work.
	var legacy := ConfigFile.new()
	legacy.set_value("progress", "flags", {"stage1_stone_collected": true})
	legacy.save(state.save_path)
	restored.load_game()
	_check(restored.has_time_stone(1) and restored.is_chapter_unlocked(2), "legacy stone flags migrate without data loss")
	_check(restored.selected_skill() == &"", "missing new save fields use defaults")
	DirAccess.remove_absolute(state.save_path)
	state.queue_free()
	restored.queue_free()
	await process_frame
	print("PASS: %d progression checks" % _checks)
	quit(0)
