extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var state = root.get_node("GameState")
	var manager = root.get_node("DialogueManager")
	state.save_path = "user://chapter4_%d.cfg" % Time.get_ticks_usec()
	var resource = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/minigame_battle.dialogue"))
	check(resource != null, "Boss story dialogue compiles")
	for skill in [&"fist", &"poison"]:
		state.reset_progress()
		check(not state.claim_boss_rescue_stone(), "No reward without prerequisites")
		state.award_time_stone(1)
		state.choose_skill(skill)
		state.award_time_stone(2)
		check(not state.can_start_activity("boss_fight"), "Boss locked before Stone 3")
		state.award_time_stone(3)
		state.record_activity_result("boss_fight", {"passed": false, "outcome": "lose"})
		check(not state.claim_boss_rescue_stone(), "Loss does not award rescue reward")
		state.record_activity_result("boss_fight", {"passed": true, "outcome": "win"})
		check(state.is_quest_active("claim_boss_reward"), "Victory activates rescue handoff")
		check(not state.has_time_stone(4), "Victory waits for rescue conversation")
		var line = await manager.get_next_dialogue_line(resource, "start")
		var count := 0
		while line != null and count < 20:
			count += 1
			line = await manager.get_next_dialogue_line(resource, line.next_id)
		check(state.has_time_stone(4) and state.has_flag("faculty_head_rescued"), "Rescue dialogue grants fourth stone")
		check(state.has_completed_quest("rescue_faculty_head"), "Rescue objective completes")
		check(state.is_quest_active("activate_time_gate"), "Final gate objective activates")
		check(not state.claim_boss_rescue_stone(), "No duplicate rescue rewards")
		state.load_game()
		check(state.has_time_stone(4) and state.selected_skill() == skill, "Reward and skill persist")
		line = await manager.get_next_dialogue_line(resource, "start")
		check(line != null and line.text.contains("2006"), "Repeat conversation directs ending")
	var hallway = load("res://scenes/mapsides/t_2.tscn").instantiate()
	check(hallway.get_node("FacultyBossDoor").dialogue_path == "res://Dialogues/minigame_battle.dialogue", "210C entrance has boss dialogue")
	hallway.free()
	DirAccess.remove_absolute(state.save_path)
	print("Chapter 4: %d failures" % failures)
	quit(1 if failures else 0)
