extends SceneTree
var state: Node
var hud: CanvasLayer

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	state = root.get_node("GameState")
	hud = root.get_node("QuestTracker")
	state.save_path = "user://journal_preview_%d.cfg" % Time.get_ticks_usec()
	state.reset_progress()
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var scene = load("res://scenes/mapsides/t_4.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var player = scene.get_node("Character")
	player.position = Vector2(3000, 430)
	state.award_time_stone(1)
	state.choose_skill(&"fist")
	state.award_time_stone(2)
	await capture("chapter3_desktop")
	hud.toggle.button_pressed = true
	await capture("collapsed_desktop")
	hud.toggle.button_pressed = false
	state.set_flag("room416_rescue_complete")
	state.set_flag("room419_lead_received")
	state.grant_quest_item("marathon_documents")
	await capture("delivery_desktop")
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	await capture("delivery_small")
	hud._fold_preference_set = false
	await capture("compact_small")
	root.get_node("DialogueManager").dialogue_started.emit(null)
	await capture("dialogue_small")
	root.get_node("DialogueManager").dialogue_ended.emit(null)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	hud._fold_preference_set = false
	state.award_time_stone(3)
	await capture("boss_large")
	# Capture real, nearby door and NPC cues with the same palette.
	player.position = Vector2(2723, 390)
	await create_timer(0.5).timeout
	await capture("door_prompt")
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	player.position = Vector2(3000, 430)
	var npc = load("res://scenes/chapters/document_recipient.tscn").instantiate()
	npc.position = player.position + Vector2(55, 0)
	scene.add_child(npc)
	player.position = npc.position + Vector2(0, 26)
	await create_timer(0.5).timeout
	await capture("nearby_npc")
	DirAccess.remove_absolute(state.save_path)
	scene.queue_free()
	await process_frame
	print("PASS: rendered journal, compact, and dialogue states in the actual floor-4 map")
	quit()

func capture(label: String) -> void:
	hud._refresh()
	hud._resize()
	hud._update_scene()
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://tests/journal_%s.png" % label
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Cannot save journal preview: " + path)
