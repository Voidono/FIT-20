extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://delivery_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	check(not state.hand_over_marathon_documents(), "Cannot deliver without progress or document")
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	check(not state.hand_over_marathon_documents(), "Stone two alone cannot complete delivery")
	state.set_flag("room419_lead_received")
	state.quiz_begin("tuan_identity", 3)
	for i in range(3):
		state.quiz_mark(true)
	state.verify_tuan_identity()
	state.record_activity_result("fit_runner_race", {"race_mode": 1, "passed": true, "completed": true, "placement": 2})
	state.claim_tuan_documents()
	var manager = root.get_node("DialogueManager")
	var resource = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/chapter3_delivery.dialogue"))
	check(resource != null, "Delivery dialogue compiles")
	var line = await manager.get_next_dialogue_line(resource, "start")
	var count := 0
	while line != null and count < 30:
		count += 1
		var next: String = line.next_id if line.responses.is_empty() else line.responses[0].next_id
		line = await manager.get_next_dialogue_line(resource, next)
	check(count < 30, "Delivery conversation ends")
	check(state.has_time_stone(3), "Dialogue awards Stone 3")
	check(not state.has_quest_item("marathon_documents"), "Document consumed")
	check(state.has_flag("delivered:marathon_documents"), "Delivery recorded")
	check(state.has_completed_quest("deliver_marathon_documents"), "Delivery quest completed")
	check(state.is_quest_active("rescue_faculty_head"), "Boss objective activated")
	check(state.has_flag("faculty_disturbance_seen"), "Disturbance completed")
	check(not state.hand_over_marathon_documents(), "No duplicate handover")
	check(not state.claim_tuan_documents(), "No reissued document")
	state.load_game()
	check(state.has_time_stone(3) and state.is_quest_active("rescue_faculty_head"), "Reward and next objective survive reload")
	line = await manager.get_next_dialogue_line(resource, "start")
	check(line != null and line.text.contains("210C"), "Repeat conversation gives destination")
	state.set_flag("faculty_disturbance_seen", false)
	line = await manager.get_next_dialogue_line(resource, "start")
	check(line != null and line.text.contains("Đèn"), "Interrupted disturbance resumes after saved reward")
	DirAccess.remove_absolute(state.save_path)
	print("Document delivery: %d failures" % failures)
	quit(1 if failures else 0)
