extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var manager = root.get_node("DialogueManager")
	var resource = manager.create_resource_from_text(FileAccess.get_file_as_string("res://Dialogues/activity_introductions.dialogue"))
	var failed := false
	var extra: Array = [{"locals": {}}]
	for id in ["garbage_quest", "fit_runner", "fit_runner_race", "boss_fight"]:
		var line = await manager.get_next_dialogue_line(resource, id, extra)
		if line == null or line.responses.size() != 2:
			failed = true
			continue
		var skip_line = await manager.get_next_dialogue_line(resource, line.responses[1].next_id, extra)
		failed = failed or skip_line != null
		line = await manager.get_next_dialogue_line(resource, line.responses[0].next_id, extra)
		var pages := 0
		while line != null and pages < 12:
			pages += 1
			var next: String = line.next_id if line.responses.is_empty() else line.responses[0].next_id
			line = await manager.get_next_dialogue_line(resource, next, extra)
		failed = failed or pages < 3 or pages >= 12
	print("Activity introductions: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
