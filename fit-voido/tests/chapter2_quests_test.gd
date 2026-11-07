extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://chapter2_quests_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	state.enter_chapter2_room()
	check(not state.has_completed_quest("enter_room_417"), "Locked chapter cannot complete arrival")
	state.award_time_stone(1)
	var room = load("res://scenes/mapsides/phòng_máy_2.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	check(state.has_completed_quest("enter_room_417"), "Actual room completes arrival")
	check(state.is_quest_active("choose_room417_seat"), "Arrival activates seating")
	state.choose_skill(&"poison")
	check(state.has_completed_quest("choose_room417_seat"), "Seat choice completes objective")
	check(state.is_quest_active("chapter2_quiz"), "Seat choice activates quiz")
	state.record_quiz_result("chapter2_fit_quiz", 4, 5)
	check(state.is_quest_active("chapter2_quiz"), "Failed attempt keeps quiz active")
	state.record_quiz_result("chapter2_fit_quiz", 5, 5)
	state.award_time_stone(2)
	check(state.has_completed_quest("chapter2_quiz"), "Stone handover completes quiz objective")
	check(state.is_quest_active("reach_room_416"), "Stone handover activates Room 416")
	var restored = load("res://scripts/game_state.gd").new()
	restored.save_path = state.save_path
	restored.load_game()
	check(restored.has_completed_quest("chapter2_quiz"), "Completed quiz objective persists")
	check(restored.is_quest_active("reach_room_416"), "Next objective persists")
	check(not state.award_time_stone(2), "Repeat reward rejected")
	state.enter_chapter2_room()
	check(not state.is_quest_active("chapter2_quiz"), "Reentry does not reopen quiz")
	var keypad = load("res://scenes/chapters/room416_keypad.tscn").instantiate()
	var hallway = load("res://scenes/mapsides/t_2_c.tscn").instantiate()
	check(hallway.get_node("Room417Door").position.x < 2800, "Room 417 remains west of Room 416")
	check(hallway.get_node("Room416Keypad").position == Vector2(3100, 150), "Room 416 takes old entrance")
	check(room.get_node("SceneDoor").target_position == Vector2(2750, 210), "Classroom exit returns to relocated door")
	hallway.free()
	check(keypad.get_script() != null, "Room 416 keypad script loads")
	keypad.free()
	check(not state.try_room416_code("2006"), "Keypad requires hearing the teacher first")
	state.set_flag("room416_help_requested")
	check(not state.try_room416_code("2026"), "Wrong code rejected")
	check(not state.has_flag("room416_unlocked"), "Wrong code leaves door locked")
	check(state.try_room416_code("2006"), "Founding year unlocks door")
	state.finish_room416_rescue()
	check(state.has_completed_quest("unlock_room_416"), "Rescue completes keypad quest")
	check(state.is_quest_active("reach_room_419"), "Rescue activates Room 419")
	restored.load_game()
	check(restored.has_flag("room416_unlocked") and restored.is_quest_active("reach_room_419"), "Unlock and handoff persist")
	var door_script = load("res://scenes/chapters/room419_door.gd")
	check(door_script.can_instantiate(), "Talking door script parses")
	var manager = root.get_node("DialogueManager")
	var dialogue = load("res://Dialogues/chapter3_room419.dialogue")
	var line = await manager.get_next_dialogue_line(dialogue, "start")
	check(line != null, "Room 419 dialogue compiles and starts")
	check(state.receive_room419_lead(), "Rescued player receives lead")
	check(state.has_completed_quest("reach_room_419"), "Talking door completes Room 419 objective")
	check(state.is_quest_active("find_thay_tuan"), "Talking door activates teacher search")
	check(not state.receive_room419_lead(), "Repeat conversation cannot repeat handoff")
	restored.load_game()
	check(restored.has_flag("room419_lead_received") and restored.is_quest_active("find_thay_tuan"), "Teacher lead persists")
	DirAccess.remove_absolute(state.save_path)
	restored.free()
	room.queue_free()
	await process_frame
	print("Chapter 2 quests: %d failures" % failures)
	quit(1 if failures else 0)
