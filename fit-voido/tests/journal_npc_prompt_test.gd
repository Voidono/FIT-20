extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var npc = load("res://scenes/Character/dialogue_npc.tscn").instantiate()
	npc.npc_name = "Giảng viên phụ trách lễ kỷ niệm"
	npc.mode = 0
	npc.position = Vector2(400, 250)
	root.add_child(npc)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	root.add_child(player)
	npc._on_body_entered(player)
	for i in range(5):
		await process_frame
	var name_rect: Rect2 = npc.name_panel.get_global_rect()
	var prompt_rect: Rect2 = npc.prompt_box.get_global_rect()
	var failed := false
	if name_rect.intersects(prompt_rect):
		push_error("NPC name and action prompt overlap")
		failed = true
	if absf(name_rect.get_center().x - npc.global_position.x) > 1:
		push_error("NPC name is not centered")
		failed = true
	if name_rect.size.x > 240:
		push_error("Long NPC name exceeds bounded width")
		failed = true
	if not npc.prompt.visible or not npc.name_tag_anchor.visible:
		push_error("Nearby NPC cues should be visible")
		failed = true
	npc._on_body_exited(player)
	if npc.prompt.visible or npc.name_tag_anchor.visible:
		push_error("NPC cues should hide outside interaction range")
		failed = true
	npc.queue_free()
	player.queue_free()
	await process_frame
	print("Journal NPC prompt: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
