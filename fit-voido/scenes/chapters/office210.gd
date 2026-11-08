extends Node2D
## Entrance cinematic, boss return, rescue and gate handoff inside the actual office.
const STORY = preload("res://Dialogues/office210.dialogue")
const BALLOON = preload("res://Dialogues/Bubbles/pixel_balloon.tscn")
var cinematic_running := false
var _balloon: Node
var _line_id := ""
var _line_clock := 0.0
var _rampage: Tween
var _panic: Tween
var _camera: Camera2D
var _near_exit := false
var _hud: CanvasLayer
var _panic_label: Label
@onready var player = $Character
@onready var teacher = $DialogueNPC
@onready var bug = $DialogueNPC2

func _ready() -> void:
	add_to_group("quest_hud_host")
	player.get_node("Camera2D").enabled = false
	_camera = Camera2D.new()
	_camera.position = Vector2(256, 144)
	add_child(_camera)
	_camera.make_current()
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	for actor in [teacher, bug]:
		actor.z_index = 4
		actor.mode = 0
		actor.walk_bob_height = 0
		actor.dialogue = STORY
		actor.cue = "retry"
		actor.repeat_cue = "retry"
		actor.interaction_started.connect(_actor_started)
		actor.interaction_finished.connect(_actor_finished)
	teacher.npc_name = "Thầy Thắng"
	bug.npc_name = "CON BUG"
	bug.prompt_text = "Đối mặt CON BUG"
	bug.get_node("Body").collision_layer = 0
	_panic_label = Label.new()
	_panic_label.text = "!"
	_panic_label.z_index = 10
	_panic_label.position = Vector2(-6, -70)
	_panic_label.add_theme_font_size_override("font_size", 24)
	_panic_label.add_theme_color_override("font_color", Color("ffd177"))
	teacher.add_child(_panic_label)
	_build_hud()
	var exit = $Exit
	exit.body_entered.connect(func(body: Node2D):
		if body == player: _near_exit = true
	)
	exit.body_exited.connect(func(body: Node2D):
		if body == player: _near_exit = false
	)
	_set_cinematic(true)
	_run_entry.call_deferred()

func _fit_camera() -> void:
	var area := get_viewport_rect().size
	_camera.zoom = Vector2.ONE * clampf(minf(area.x / 570.0, area.y / 430.0), 0.5, 1.3)

func _run_entry() -> void:
	_set_cinematic(true)
	if not GameState.is_chapter_unlocked(4):
		_stop_rampage()
		await _play_dialogue("locked")
		_set_cinematic(false)
		return
	if GameState.has_completed_quest("boss_fight"):
		_settle_room()
		if not GameState.has_time_stone(4):
			await _play_dialogue("rescue")
		_set_cinematic(false)
		return
	_start_rampage()
	if GameState.has_flag("room210_intro_seen"):
		_set_cinematic(false)
		return
	await get_tree().create_timer(0.5).timeout
	await _play_dialogue("intro")
	GameState.set_flag("room210_intro_seen")
	await _launch_battle()

func _set_cinematic(active: bool) -> void:
	cinematic_running = active
	player.set_can_move(not active)
	player.get_node("ScreenUI/MenuButton").visible = not active
	if is_instance_valid(player._keyboard_hint): player._keyboard_hint.visible = not active
	if is_instance_valid(player._mobile_controls): player._mobile_controls.visible = not active
	$Exit/Label.visible = not active and _near_exit
	_hud.visible = active
	if active:
		DialogueNPC.is_any_talking = true
		QuestTracker.hide()
	else:
		DialogueNPC.is_any_talking = false
		QuestTracker._update_scene()
		for actor in [teacher, bug]: actor._update_prompt()

func _play_dialogue(cue: String) -> void:
	_balloon = DialogueManager.show_dialogue_balloon_scene(BALLOON, STORY, cue)
	_line_id = ""
	_line_clock = 0
	await _balloon.tree_exited
	_balloon = null

func _process(delta: float) -> void:
	$Exit/Label.visible = not cinematic_running and _near_exit
	if cinematic_running:
		QuestTracker.hide()
		for actor in [teacher, bug]:
			actor.prompt.hide()
			actor.name_tag_anchor.hide()
	# Cinematic lines advance automatically, with normal Enter/tap still usable.
	if not cinematic_running or not is_instance_valid(_balloon): return
	var line = _balloon.dialogue_line
	if line == null: return
	if line.id != _line_id:
		_line_id = line.id
		_line_clock = 0
	if _balloon.dialogue_label.is_typing or not _balloon.is_waiting_for_input: return
	_line_clock += delta
	if line.responses.is_empty() and _line_clock >= maxf(2.3, line.text.length() * 0.045):
		_line_clock = 0
		_balloon.next(line.next_id)

func _start_rampage() -> void:
	_stop_rampage()
	_rampage = create_tween().set_loops()
	for point in [Vector2(420, 100), Vector2(350, 125), Vector2(290, 108), Vector2(430, 78)]:
		_rampage.tween_property(bug, "position", point, 0.65).set_trans(Tween.TRANS_SINE)
		_rampage.tween_interval(0.16)
	_panic = create_tween().set_loops()
	_panic.tween_property(teacher.sprite, "rotation", 0.04, 0.1)
	_panic.tween_property(teacher.sprite, "rotation", -0.04, 0.1)
	_panic_label.show()

func _stop_rampage() -> void:
	if _rampage and _rampage.is_valid(): _rampage.kill()
	if _panic and _panic.is_valid(): _panic.kill()
	teacher.sprite.rotation = 0

func _settle_room() -> void:
	_stop_rampage()
	_panic_label.hide()
	teacher.position = Vector2(440, 125)
	teacher.cue = "after"
	teacher.repeat_cue = "after"
	teacher.prompt_text = "Nói chuyện / Mở cổng"
	teacher.action_label.text = teacher.prompt_text
	bug.visible = GameState.boss_resolution() == "spared"
	bug.monitoring = bug.visible
	if bug.visible:
		bug.position = Vector2(290, 170)
		bug.scale = Vector2.ONE
		bug.cue = "bug_calm"
		bug.repeat_cue = "bug_calm"

func _actor_started() -> void:
	if GameState.has_completed_quest("boss_fight"): return
	_stop_rampage()
	_set_cinematic(true)
	_capture_actor_balloon.call_deferred()

func _capture_actor_balloon() -> void:
	await get_tree().process_frame
	for child in get_children():
		if "dialogue_line" in child and "dock" in child:
			_balloon = child
			_line_id = ""
			_line_clock = 0

func _actor_finished() -> void:
	if GameState.has_completed_quest("boss_fight"): return
	_set_cinematic(true)
	_launch_after_balloon.call_deferred()

func _launch_after_balloon() -> void:
	if is_instance_valid(_balloon): await _balloon.tree_exited
	_balloon = null
	await _launch_battle()

func _launch_battle() -> void:
	_set_cinematic(true)
	_stop_rampage()
	await get_tree().create_timer(0.15).timeout
	# Entry begins the battle automatically; retries return here, never to a hallway.
	var error := SceneLoader.start_minigame("boss_fight")
	if error != OK:
		_start_rampage()
		_set_cinematic(false)

func _unhandled_input(event: InputEvent) -> void:
	if cinematic_running or DialogueNPC.is_any_talking or not _near_exit: return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if SceneLoader.leave_office210() == OK: WorldSfx.play_door()

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 95
	add_child(_hud)
	for bottom in [false, true]:
		var bar := ColorRect.new()
		bar.color = Color(0.02, 0.03, 0.03, 0.9)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -26 if bottom else 0
		bar.offset_bottom = 0 if bottom else 26
		var text := Label.new()
		text.text = "" if bottom else "210C · VĂN PHÒNG KHOA    |    Tự động · Chạm / Enter để tiếp tục"
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size", 12)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(text)
		text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _exit_tree() -> void:
	DialogueNPC.is_any_talking = false
