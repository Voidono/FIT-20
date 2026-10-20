class_name BossBattle
extends Node2D
## Undertale-style boss fight. One attempt =
##   intro -> [ player menu -> (phase change) -> boss speech -> dodge phase ] x N -> ending.
##
## Run battle.tscn directly to test (F6), or use it from the main game:
##
##     var battle: BossBattle = preload("res://Minigames/fit_battle_step4/fit_battle/battle/battle.tscn").instantiate()
##     battle.skill_id = "poison"     # PLACEHOLDER handoff: a plain string from the earlier part
##     # battle.difficulty = ...      # leave empty: the battle shows the difficulty menu itself
##     battle.finished.connect(_on_battle_finished)    # &"win" or &"spared"
##     add_child(battle)
##
## Dying restarts the fight (auto_restart_on_death), so `finished` only fires on a win / spare.

signal finished(result: StringName)
signal player_died(death_count: int)
signal _confirmed
signal _banner_choice(choice: StringName)

const CANCEL := &"cancel"
const NEXT := &"next"

## The skill as a resource. Leave empty to use `skill_id`.
@export var skill: BattleSkill
## PLACEHOLDER handoff from the earlier part: a skill id such as "fist" or "poison".
## Loaded from res://Minigames/fit_battle_step4/fit_battle/data/skills/<id>.tres when `skill` is empty.
@export var skill_id := "fist"
## Leave empty and the battle shows the difficulty menu first. Set it to skip the menu.
@export var difficulty: BattleDifficulty
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


static func skill_from_id(id: StringName) -> BattleSkill:
	return load("res://Minigames/fit_battle_step4/fit_battle/data/skills/%s.tres" % id) as BattleSkill


static func difficulty_from_id(id: StringName) -> BattleDifficulty:
	return load("res://Minigames/fit_battle_step4/fit_battle/data/difficulty/%s.tres" % id) as BattleDifficulty


func _ready() -> void:
	assert(enemy_scene != null, "BossBattle needs enemy_scene")
	if skill == null:
		skill = skill_from_id(StringName(skill_id))
		if skill == null:
			push_error("Unknown skill_id '%s' (expected res://Minigames/fit_battle_step4/fit_battle/data/skills/%s.tres). Using fist." \
					% [skill_id, skill_id])
			skill = skill_from_id(&"fist")
	soul.hit.connect(_on_soul_hit)
	retry_button.pressed.connect(func() -> void: _banner_choice.emit(&"retry"))
	change_button.pressed.connect(func() -> void: _banner_choice.emit(&"difficulty"))
	result_root.hide()
	_apply_touch_mode()
	_run()


func _input(event: InputEvent) -> void:
	if _waiting_confirm and Engine.get_process_frames() > _wait_frame \
			and BattleInput.is_confirm(event):
		_waiting_confirm = false
		_confirmed.emit()


# ---- public API (main game / debug panel) ---------------------------------------

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


## Phones: joystick on, drag-to-move off (so they never fight). Desktop: the reverse.
func _apply_touch_mode() -> void:
	soul.touch_drag_enabled = not touch_controls.is_enabled()


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
		difficulty = await difficulty_menu.pick(null)
	while true:
		var outcome: StringName = await _fight()
		if outcome == &"lose":
			deaths += 1
			player_died.emit(deaths)
			var choice: StringName = await _show_game_over()
			if choice == &"difficulty":
				difficulty = await difficulty_menu.pick(difficulty)
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
	get_tree().call_group(&"bullet", "queue_free")
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


func _assist() -> float:
	return minf(float(deaths) * assist_per_death, max_assist)


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
	if accuracy <= 0.0:
		await enemy.miss()
	else:
		var perfect := accuracy >= skill.perfect_threshold
		var ratio := lerpf(skill.min_damage_ratio, 1.0, accuracy)
		var bonus := skill.perfect_multiplier if perfect else 1.0
		var damage := maxi(roundi(skill.base_damage * ratio * bonus) - enemy.defense, 1)
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
		soul.begin_play(box.get_center())
		await pattern.run(box, soul, bullets, difficulty, _assist())
		_pattern = null
		touch_controls.set_active(false)
		if stats.is_dead():
			return &"lose"
		soul.hide_soul()
		get_tree().call_group(&"bullet", "queue_free")
		await box.end_dodge()
	_turn += 1
	return NEXT


func _phase_transition() -> void:
	await enemy.play_phase_change()
	if enemy.phase.enter_text != "":
		await box.flavor.say(enemy.phase.enter_text)
	await speech.say(&"phase_enter", _speech_context(enemy.phase.enter_speech), _speech_anchor())


func _on_soul_hit(damage: int) -> void:
	stats.damage(damage)
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
			await speech.say(&"defeat", _speech_context(enemy.defeat_speech), _speech_anchor())
			await enemy.play_death()
			await box.flavor.say(win_text)
		&"spared":
			await speech.say(&"spare", _speech_context(enemy.spare_speech), _speech_anchor())
			await box.flavor.say(spared_text)
		&"lose":
			get_tree().call_group(&"bullet", "set_physics_process", false)
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
