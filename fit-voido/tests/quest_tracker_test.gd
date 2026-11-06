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
	state.save_path = "user://quest_tracker_test_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	var notifications := [0]
	state.quests_changed.connect(func(): notifications[0] += 1)
	state.add_quest("test_collect", "Collect", "Collect ten items", 10)
	state.start_quest("reach_building_c")
	check(state.tracked_quests().size() == 2, "Multiple quests")
	check(root.get_node("QuestTracker")._rows.size() == 2, "Signal creates HUD rows")
	state.update_quest_progress("test_collect", 3)
	check(state.quest_info("test_collect").progress == 3, "Counter update")
	check(root.get_node("QuestTracker")._rows["test_collect"].counter.text == "3/10", "Signal updates HUD counter")
	state.update_quest_objective("test_collect", "Updated objective")
	check(state.quest_info("test_collect").objective == "Updated objective", "Objective update")
	var saved = load("res://scripts/game_state.gd").new()
	saved.save_path = state.save_path
	saved.load_game()
	check(saved.quest_info("test_collect").progress == 3, "Saved counter")
	check(saved.quest_info("test_collect").target == 10, "Saved target")
	state.update_quest_progress("test_collect", 12)
	check(state.has_completed_quest("test_collect"), "Automatic completion")
	state.hide_quest("test_collect")
	check(state.tracked_quests().size() == 1 and state.has_completed_quest("test_collect"), "Hide retains completion")
	state.remove_quest("test_collect")
	check(state.quest_stage("test_collect") == "inactive", "Removal")
	check(notifications[0] >= 7, "Signals emitted")
	var hud = root.get_node("QuestTracker")
	var host := Node.new()
	host.add_to_group("quest_hud_host")
	root.add_child(host)
	current_scene = host
	await process_frame
	hud._update_scene()
	check(hud.visible, "Gameplay root opts into HUD")
	host.remove_from_group("quest_hud_host")
	hud._update_scene()
	check(not hud.visible, "Non gameplay scenes hide HUD")
	hud.toggle.button_pressed = true
	check(not hud.scroll.visible, "Collapse hides list")
	hud.toggle.button_pressed = false
	check(hud.scroll.visible, "Expand restores list")
	var row = load("res://scenes/UI/quests/quest_row.tscn").instantiate()
	root.add_child(row)
	row.display(state.quest_info("reach_building_c"))
	state.complete_quest("reach_building_c")
	row.display(state.quest_info("reach_building_c"))
	check(row.get_node("Body/Heading/Status").text == "[OK]", "Completion presentation")
	check(hud.get_node("Root").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Root passes input")
	check(hud.get_node("Root/Panel/Body/Toggle").focus_mode == Control.FOCUS_NONE, "No keyboard focus theft")
	for size in [Vector2i(960, 540), Vector2i(640, 360), Vector2i(1280, 720)]:
		root.content_scale_size = size
		root.size = size
		hud._resize()
		await process_frame
		check(hud.panel.position.x >= 0, "Top left placement")
		check(hud.panel.get_global_rect().end.x <= root.get_visible_rect().size.x, "Panel stays within viewport width")
	state.reset_progress()
	check(state.tracked_quests().is_empty(), "Reset clears quests")
	DirAccess.remove_absolute(state.save_path)
	saved.free()
	row.queue_free()
	host.queue_free()
	await process_frame
	print("Quest tracker tests: %d failures" % failures)
	quit(1 if failures else 0)

