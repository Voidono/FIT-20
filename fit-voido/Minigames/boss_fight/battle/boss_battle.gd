class_name BossBattle
extends Node2D
## The fight itself (controller). The main game normally uses BossFight instead, which runs this
## scene inside an isolated, scaled 640x480 viewport. This scene also runs on its own (F6) for testing.
##
## One attempt = intro -> [ player menu -> (phase change) -> boss speech -> dodge phase ] x N -> ending.
## Dying restarts the fight (auto_restart_on_death), so `finished` only fires on a win / spare.

signal finished(result: StringName)
signal player_died(death_count: int)
## SFX / music hooks (menu_move, menu_confirm, player_hit, enemy_hit, ...). See the README, "Cues".
signal cue(cue_name: StringName, data: Dictionary)
signal _confirmed
signal _banner_choice(choice: StringName)

const DESIGN_SIZE := Vector2(640, 480)
const CANCEL := &"cancel"
const NEXT := &"next"

## Start by itself in _ready(). BossFight turns this off and calls begin() once it has configured us.
@export var auto_start := true
## The skill as a resource, or leave it empty and set `skill_id` (looked up in Library/Skills).
@export var skill: BattleSkill
@export var skill_id := "fist"
## Leave both empty and the player gets the difficulty menu first.
@export var difficulty: BattleDifficulty
@export var difficulty_id := ""
@export var enemy_scene: PackedScene
@export var player_name := "SV 2006"
@export_group("Flow")
@export var auto_restart_on_death := true
## Offers "change difficulty" next to "retry" on the game-over screen.
@export var allow_difficulty_change := true
## Undertale shows "* ENEMY" before FIGHT / ACT. Turn off for one tap fewer.
@export var show_target_step := true
## Each death eases the next attempt (slower bullets, less damage) by this much, up to max_assist.
@export_range(0.0, 0.5) var assist_per_death := 0.1
@export_range(0.0, 0.9) var max_assist := 0.4
@export_group("Text")
@export_multiline var no_items_text := "* Bạn không còn vật phẩm nào."
@export var spare_label := "Spare"
@export_multiline var spare_fail_text := "* CON BUG chưa muốn dừng lại."
@export_multiline var spareable_text := "* CON BUG đã dịu lại. Bạn có thể tha cho nó."
@export_multiline var win_text := "* BẠN ĐÃ ĐÁNH BẠI CON BUG!"
@export_multiline var spared_text := "* CON BUG lặng lẽ biến mất."
@export var win_banner := "VICTORY"
@export var lose_banner := "GAME OVER"
@export var continue_hint := "Nhấn Z hoặc chạm màn hình để tiếp tục"

@onready var enemy_slot: Node2D = %EnemySlot
@onready var box: BattleBox = %BattleBox
@onready var soul: BattleSoul = %Soul
@onready var bullets: Node2D = %Bullets
@onready var menu: BattleMenu = %Menu
@onready var hud: BattleHud = %PlayerHud
@onready var speech: BossSpeech = %Speech
@onready var items_root: Node = %Items
@onready var skills_root: Node = %Skills
@onready var difficulties_root: Node = %Difficulties
@onready var difficulty_menu: BattleDifficultyMenu = %DifficultyMenu
@onready var result_root: Control = %Result
@onready var result_label: Label = %ResultLabel
@onready var hint_label: Label = %HintLabel
@onready var banner_buttons: Control = %BannerButtons
@onready var retry_button: Button = %RetryButton
@onready var change_button: Button = %ChangeButton
@onready var touch_controls: BattleTouchControls = %TouchControls

var enemy: BossEnemy
var stats: BattleStats
var deaths := 0

var _turn := 0
var _pattern: BossAttack
var _spare_announced := false
var _waiting_confirm := false
var _wait_frame := -1


func _ready() -> void:
	soul.hit.connect(_on_soul_hit)
	retry_button.pressed.connect(func() -> void: _banner_choice.emit(&"retry"))
	change_button.pressed.connect(func() -> void: _banner_choice.emit(&"difficulty"))
	_connect_cues()
	result_root.hide()
	_apply_touch_mode()
	if auto_start:
		begin()


func _input(event: InputEvent) -> void:
	if _waiting_confirm and Engine.get_process_frames() > _wait_frame \
			and BattleInput.is_confirm(event):
		_waiting_confirm = false
		_confirmed.emit()


# ---- public API -----------------------------------------------------------------

## Starts the fight. Skill and difficulty are resolved from the exports first.
func begin() -> void:
	assert(enemy_scene != null, "BossBattle needs enemy_scene")
	if skill == null:
		skill = skill_by_id(StringName(skill_id))
		if skill == null:
			push_error("Unknown skill id '%s' (see BossBattle/Library/Skills). Using the first skill." % skill_id)
			var all_skills := get_skills()
			skill = all_skills[0] if not all_skills.is_empty() else null
	assert(skill != null, "BossBattle has no skill: add one under Library/Skills")
	if difficulty == null and difficulty_id != "":
		difficulty = difficulty_by_id(StringName(difficulty_id))
		if difficulty == null:
			push_error("Unknown difficulty id '%s'. The player will be asked instead." % difficulty_id)
	_run()


func get_skills() -> Array[BattleSkill]:
	var result: Array[BattleSkill] = []
	for child in skills_root.get_children():
		var ref := child as BattleResourceRef
		if ref != null and ref.resource is BattleSkill:
			result.append(ref.resource)
	return result


func get_difficulties() -> Array[BattleDifficulty]:
	var result: Array[BattleDifficulty] = []
	for child in difficulties_root.get_children():
		var ref := child as BattleResourceRef
		if ref != null and ref.resource is BattleDifficulty:
			result.append(ref.resource)
	return result


func skill_by_id(id: StringName) -> BattleSkill:
	for candidate in get_skills():
		if candidate.id == id:
			return candidate
	return null


func difficulty_by_id(id: StringName) -> BattleDifficulty:
	for candidate in get_difficulties():
		if candidate.id == id:
			return candidate
	return null


## The 640x480 area of the fight in global coordinates.
func play_area() -> Rect2:
	return Rect2(global_position, DESIGN_SIZE)


func set_difficulty(new_difficulty: BattleDifficulty) -> void:
	difficulty = new_difficulty
	if stats != null:
		stats.set_max_hp(difficulty.player_max_hp)
	if enemy != null:
		enemy.rescale_hp(difficulty)
	soul.configure(difficulty.invincibility_time, skill.dodge_speed_multiplier)


func set_skill(new_skill: BattleSkill) -> void:
	skill = new_skill
	if difficulty != null:
		soul.configure(difficulty.invincibility_time, skill.dodge_speed_multiplier)


## Testing: flips the phone joystick on or off on a desktop (debug panel button).
func toggle_mobile_controls() -> void:
	if touch_controls.is_enabled():
		touch_controls.mode = BattleTouchControls.Mode.NEVER
	else:
		touch_controls.mode = BattleTouchControls.Mode.ALWAYS
	_apply_touch_mode()


func debug_set_boss_ratio(ratio: float) -> void:
	if enemy != null:
		enemy.set_hp_ratio(ratio)


func debug_fill_mercy() -> void:
	if enemy != null:
		enemy.mercy = enemy.spare_mercy_needed


func debug_heal() -> void:
	if stats != null:
		stats.full_heal()


# ---- flow -----------------------------------------------------------------------

func _run() -> void:
	if difficulty == null:
		difficulty = await difficulty_menu.pick(get_difficulties(), null)
	while true:
		var outcome: StringName = await _fight()
		if outcome == &"lose":
			deaths += 1
			player_died.emit(deaths)
			var choice: StringName = await _show_game_over()
			if choice == &"difficulty":
				difficulty = await difficulty_menu.pick(get_difficulties(), difficulty)
			if auto_restart_on_death:
				continue
		finished.emit(outcome)
		if get_tree().current_scene == self:
			await _show_banner(lose_banner if outcome == &"lose" else win_banner, continue_hint)
			get_tree().reload_current_scene()
		return


func _fight() -> StringName:
	_setup_attempt()
	await box.flavor.say(enemy.intro_text)
	var outcome := NEXT
	while outcome == NEXT:
		outcome = await _player_turn()
		if outcome != NEXT:
			break
		outcome = await _enemy_turn()
	await _play_ending(outcome)
	return outcome


func _setup_attempt() -> void:
	if enemy != null:
		enemy.queue_free()
	_clear_bullets()
	stats = BattleStats.new()
	stats.setup(player_name, difficulty.player_max_hp)
	hud.bind(stats)
	soul.configure(difficulty.invincibility_time, skill.dodge_speed_multiplier)
	soul.hide_soul()
	touch_controls.set_active(false)
	enemy = enemy_scene.instantiate() as BossEnemy
	enemy_slot.add_child(enemy)
	enemy.setup(difficulty)
	for child in items_root.get_children():
		var option := child as BattleOption
		if option != null:
			option.reset()
	box.reset()
	menu.deactivate()
	_turn = 0
	_pattern = null
	_spare_announced = false
	cue.emit(&"fight_started", {"attempt": deaths + 1, "skill": skill.id, "difficulty": difficulty.id})


func _assist() -> float:
	return minf(float(deaths) * assist_per_death, max_assist)


## Phones: joystick on, drag-to-move off (so they never fight). Desktop: the reverse.
func _apply_touch_mode() -> void:
	soul.touch_drag_enabled = not touch_controls.is_enabled()


func _clear_bullets() -> void:
	for child in bullets.get_children():
		child.queue_free()


func _freeze_bullets() -> void:
	for child in bullets.get_children():
		child.set_physics_process(false)


func _connect_cues() -> void:
	menu.moved.connect(func() -> void: cue.emit(&"menu_move", {}))
	menu.chosen.connect(func(_action: StringName) -> void: cue.emit(&"menu_confirm", {}))
	for list in [box.choices, difficulty_menu.choices]:
		list.moved.connect(func() -> void: cue.emit(&"menu_move", {}))
		list.picked.connect(func(_index: int) -> void: cue.emit(&"menu_confirm", {}))


# ---- player turn ----------------------------------------------------------------

func _player_turn() -> StringName:
	while true:
		box.flavor.type_text(enemy.phase.get_flavor(_turn))
		menu.activate()
		var action: StringName = await menu.chosen
		menu.deactivate()
		box.flavor.clear_text()
		var outcome := CANCEL
		match action:
			&"fight":
				outcome = await _do_fight()
			&"act":
				outcome = await _do_act()
			&"item":
				outcome = await _do_item()
			&"mercy":
				outcome = await _do_mercy()
		if outcome != CANCEL:
			return outcome
	return NEXT


## The "* CON BUG" step before FIGHT / ACT. Returns false if the player backed out.
func _pick_target() -> bool:
	if not show_target_step:
		return true
	var highlighted := PackedInt32Array([0]) if enemy.can_be_spared() else PackedInt32Array()
	var pick: int = await box.choices.choose(PackedStringArray([enemy.display_name]), highlighted)
	return pick >= 0


func _do_fight() -> StringName:
	var picked: bool = await _pick_target()
	if not picked:
		return CANCEL
	var forgiveness := clampf(skill.forgiveness * difficulty.sweet_spot_multiplier, 0.05, 1.0)
	var accuracy: float = await box.fight_bar.run(
			skill.display_name, forgiveness, difficulty.bar_speed_multiplier,
			skill.perfect_threshold)
	cue.emit(&"bar_stopped", {"accuracy": accuracy})
	if accuracy <= 0.0:
		cue.emit(&"enemy_miss", {})
		await enemy.miss()
	else:
		var perfect := accuracy >= skill.perfect_threshold
		var ratio := lerpf(skill.min_damage_ratio, 1.0, accuracy)
		var bonus := skill.perfect_multiplier if perfect else 1.0
		var damage := maxi(roundi(skill.base_damage * ratio * bonus) - enemy.defense, 1)
		cue.emit(&"enemy_hit", {"damage": damage, "perfect": perfect})
		await enemy.take_hit(damage, perfect)
		if skill.poison_turns > 0:
			enemy.apply_poison(skill.poison_damage, skill.poison_turns)
	if enemy.hp <= 0:
		return &"win"
	return NEXT


func _do_act() -> StringName:
	var picked: bool = await _pick_target()
	if not picked:
		return CANCEL
	var options := enemy.get_acts()
	var labels := PackedStringArray()
	for option in options:
		labels.append(option.label)
	var pick: int = await box.choices.choose(labels)
	if pick < 0:
		return CANCEL
	var chosen_act := options[pick]
	chosen_act.use()
	enemy.add_mercy(chosen_act.mercy_delta)
	await box.flavor.say(chosen_act.response)
	if enemy.can_be_spared() and not _spare_announced:
		_spare_announced = true
		await box.flavor.say(spareable_text)
	return NEXT


func _do_item() -> StringName:
	var options: Array[BattleOption] = []
	for child in items_root.get_children():
		var candidate := child as BattleOption
		if candidate != null and candidate.uses != 0:
			options.append(candidate)
	if options.is_empty():
		await box.flavor.say(no_items_text)
		return CANCEL
	var labels := PackedStringArray()
	for option in options:
		labels.append(option.label)
	var pick: int = await box.choices.choose(labels)
	if pick < 0:
		return CANCEL
	var chosen_item := options[pick]
	stats.heal(chosen_item.heal_amount)
	cue.emit(&"player_heal", {"amount": chosen_item.heal_amount})
	chosen_item.use()
	await box.flavor.say(chosen_item.response)
	return NEXT


func _do_mercy() -> StringName:
	var highlighted := PackedInt32Array([0]) if enemy.can_be_spared() else PackedInt32Array()
	var pick: int = await box.choices.choose(PackedStringArray([spare_label]), highlighted)
	if pick < 0:
		return CANCEL
	if enemy.can_be_spared():
		return &"spared"
	await box.flavor.say(spare_fail_text)
	return NEXT


# ---- enemy turn -----------------------------------------------------------------

func _enemy_turn() -> StringName:
	if enemy.is_poisoned():
		cue.emit(&"enemy_poison", {"damage": enemy.poison_damage})
		await enemy.tick_poison()
		if enemy.hp <= 0:
			return &"win"
	if enemy.update_phase():
		await _phase_transition()
	await speech.say(&"turn", _speech_context(enemy.phase.get_speech(_turn)), _speech_anchor())
	var pattern := enemy.next_attack()
	if pattern != null:
		touch_controls.set_active(true)
		await box.start_dodge(pattern.box_size)
		_pattern = pattern
		soul.begin_play(box.get_center(), box)
		cue.emit(&"attack_started", {"name": pattern.display_name})
		await pattern.run(box, soul, bullets, difficulty, play_area(), _assist())
		_pattern = null
		touch_controls.set_active(false)
		cue.emit(&"attack_ended", {})
		if stats.is_dead():
			return &"lose"
		soul.hide_soul()
		_clear_bullets()
		await box.end_dodge()
	_turn += 1
	return NEXT


func _phase_transition() -> void:
	cue.emit(&"phase_changed", {"phase": enemy.phase_number()})
	await enemy.play_phase_change()
	if enemy.phase.enter_text != "":
		await box.flavor.say(enemy.phase.enter_text)
	await speech.say(&"phase_enter", _speech_context(enemy.phase.enter_speech), _speech_anchor())


func _on_soul_hit(damage: int) -> void:
	stats.damage(damage)
	cue.emit(&"player_hit", {"damage": damage, "hp": stats.hp})
	if stats.is_dead() and _pattern != null:
		_pattern.call_deferred(&"stop")


func _speech_context(text: String) -> Dictionary:
	return {"text": text, "phase": enemy.phase_number(), "turn": _turn}


func _speech_anchor() -> Vector2:
	return enemy.speech_anchor.global_position


# ---- ending -----------------------------------------------------------------------

func _play_ending(outcome: StringName) -> void:
	match outcome:
		&"win":
			cue.emit(&"enemy_defeated", {})
			await speech.say(&"defeat", _speech_context(enemy.defeat_speech), _speech_anchor())
			await enemy.play_death()
			await box.flavor.say(win_text)
		&"spared":
			cue.emit(&"spared", {})
			await speech.say(&"spare", _speech_context(enemy.spare_speech), _speech_anchor())
			await box.flavor.say(spared_text)
		&"lose":
			cue.emit(&"player_died", {"deaths": deaths + 1})
			_freeze_bullets()
			await soul.play_death()


## Game-over screen with RETRY / CHANGE DIFFICULTY buttons (tap, or arrows + Z).
func _show_game_over() -> StringName:
	result_label.text = lose_banner
	hint_label.text = ""
	change_button.visible = allow_difficulty_change
	banner_buttons.show()
	result_root.show()
	retry_button.grab_focus()
	var choice: StringName = await _banner_choice
	banner_buttons.hide()
	result_root.hide()
	return choice


## Plain banner that waits for a confirm (used for the standalone victory screen).
func _show_banner(title: String, hint: String) -> void:
	result_label.text = title
	hint_label.text = hint
	banner_buttons.hide()
	result_root.show()
	_waiting_confirm = true
	_wait_frame = Engine.get_process_frames()
	await _confirmed
	result_root.hide()
