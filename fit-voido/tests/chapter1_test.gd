extends SceneTree

const STATE = preload("res://scripts/game_state.gd")
var _checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		push_error("FAIL: " + label)
		quit(1)
		assert(value, label)

func _run() -> void:
	for path in ["res://Dialogues/stage1_blind_bags.dialogue", "res://Dialogues/tutorial_arrival.dialogue"]:
		var compiled = DMCompiler.compile_string(FileAccess.get_file_as_string(path), path)
		_check(compiled.errors.is_empty(), "chapter dialogue compiles: " + path)
	var state = STATE.new()
	state.save_path = "res://tests/chapter1_test_%d.cfg" % Time.get_ticks_usec()
	root.add_child(state)
	_check(not state.claim_stage1_stone(), "cannot claim before passing")
	_check(not state.select_stage1_activity("boss_fight"), "chapter one rejects other activities")
	_check(state.select_stage1_activity("garbage_quest"), "select cleanup")
	_check(state.is_quest_active("garbage_quest"), "selected activity tracked")
	_check(state.select_stage1_activity("fit_runner"), "can switch activities")
	_check(not state.is_quest_active("garbage_quest") and state.is_quest_active("fit_runner"), "switch removes stale objective")
	state.record_activity_result("fit_runner", {"passed": false})
	_check(not state.can_claim_stage1_stone(), "failure cannot earn stone")
	state.record_activity_result("fit_runner", {"passed": true, "stars": 1})
	_check(not state.has_time_stone(1) and state.can_claim_stage1_stone(), "passing waits for lecturer")
	_check(state.claim_stage1_stone(), "lecturer awards stone")
	_check(state.is_chapter_unlocked(2), "handover unlocks chapter two")
	_check(state.has_completed_quest("stage1_challenge") and state.is_quest_active("enter_room_417"), "handover updates both objectives")
	_check(not state.claim_stage1_stone(), "cannot claim twice")
	_check(not state.select_stage1_activity("garbage_quest"), "completed chapter cannot reopen")
	var restored = STATE.new()
	restored.save_path = state.save_path
	root.add_child(restored)
	_check(restored.has_time_stone(1) and restored.is_quest_active("enter_room_417"), "handover persists completely")
	_check(restored.stage1_activity() == "fit_runner", "selection survives restart")
	restored.reset_progress()
	restored.select_stage1_activity("garbage_quest")
	restored.record_activity_result("garbage_quest", {"passed": true})
	_check(restored.claim_stage1_stone(), "cleanup route earns same reward")
	DirAccess.remove_absolute(state.save_path)
	state.queue_free()
	restored.queue_free()
	await process_frame
	print("PASS: %d chapter-one checks" % _checks)
	quit(0)
