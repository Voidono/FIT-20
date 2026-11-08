extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("GameState")
	var manager = root.get_node("DialogueManager")
	state.save_path = "res://tests/chapter1_dialogue_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var arrival = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/tutorial_arrival.dialogue"))
	var line = await manager.get_next_dialogue_line(arrival, "start")
	assert(line.character == "Thầy Dũng", "Entrance professor is Dũng")
	var steps := 0
	while line != null and steps < 40:
		steps += 1
		var next: String = line.responses[0].next_id if not line.responses.is_empty() else line.next_id
		line = await manager.get_next_dialogue_line(arrival, next)
	if not state.has_flag("intro_complete") or not state.is_quest_active("reach_building_c"):
		push_error("Arrival did not activate lecturer objective")
		quit(1)
		return
	var lecturer = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/stage1_blind_bags.dialogue"))
	state.select_stage1_activity("garbage_quest")
	state.record_activity_result("garbage_quest", {"passed": true})
	line = await manager.get_next_dialogue_line(lecturer, "start")
	assert(line.character == "Thầy Tùng", "Nhà C professor is Tùng")
	steps = 0
	while line != null and steps < 20:
		steps += 1
		line = await manager.get_next_dialogue_line(lecturer, line.next_id)
	if not state.has_time_stone(1) or not state.is_quest_active("enter_room_417"):
		push_error("Lecturer reward did not activate Room 417 objective")
		quit(1)
		return
	line = await manager.get_next_dialogue_line(lecturer, "start")
	if not line.text.contains("417"):
		push_error("Returning lecturer does not direct player to Room 417")
		quit(1)
		return
	DirAccess.remove_absolute(state.save_path)
	print("PASS: actual arrival dialogue, lecturer reward, and repeat conversation")
	quit(0)
