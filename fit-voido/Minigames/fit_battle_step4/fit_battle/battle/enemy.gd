class_name BossEnemy
extends Node2D
## One enemy = one scene, configured by exports and child nodes:
##   Visual  - AssetSlot: drop your sprite (or an AnimatedSprite2D) here
##   Phases  - BossPhase nodes; each phase's children are its AttackPatterns
##   Acts    - BattleOption nodes = the ACT menu

signal hp_changed(hp: int, max_hp: int)

@export var display_name := "CON BUG"
## HP on Normal difficulty. The difficulty's boss_hp_multiplier scales it.
@export var base_max_hp := 240
@export var defense := 0
@export var spare_mercy_needed := 100
@export var idle_bob := 4.0
@export var idle_bob_time := 0.9
@export_group("Text")
@export_multiline var intro_text := ""
@export var defeat_speech := ""
@export var spare_speech := ""

@onready var visual: Node2D = %Visual
@onready var hp_bar: ProgressBar = %HpBar
@onready var damage_label: Label = %DamageLabel
@onready var phases_root: Node = %Phases
@onready var acts_root: Node = %Acts
@onready var speech_anchor: Marker2D = %SpeechAnchor

var max_hp := 1
var hp := 1
var mercy := 0
var mercy_multiplier := 1.0
var poison_damage := 0
var poison_turns := 0
var phases: Array[BossPhase] = []
var phase: BossPhase

var _label_rest_y := 0.0
var _bob_tween: Tween


func _ready() -> void:
	for child in phases_root.get_children():
		if child is BossPhase:
			phases.append(child)
	assert(not phases.is_empty(), "Enemy needs at least one BossPhase under Phases")
	phases.sort_custom(_by_threshold_descending)
	phase = phases[0]
	visual.self_modulate = phase.tint
	hp_bar.hide()
	_label_rest_y = damage_label.position.y
	damage_label.modulate.a = 0.0
	if idle_bob > 0.0:
		var base_y := visual.position.y
		_bob_tween = create_tween().set_loops()
		_bob_tween.tween_property(visual, "position:y", base_y - idle_bob, idle_bob_time) \
				.set_trans(Tween.TRANS_SINE)
		_bob_tween.tween_property(visual, "position:y", base_y + idle_bob, idle_bob_time) \
				.set_trans(Tween.TRANS_SINE)


static func _by_threshold_descending(a: BossPhase, b: BossPhase) -> bool:
	return a.starts_at_hp_ratio > b.starts_at_hp_ratio


## Applies a difficulty preset. Call once, right after adding the enemy to the tree.
func setup(difficulty: BattleDifficulty) -> void:
	max_hp = maxi(roundi(base_max_hp * difficulty.boss_hp_multiplier), 1)
	hp = max_hp
	mercy = 0
	mercy_multiplier = difficulty.mercy_multiplier
	hp_bar.max_value = max_hp
	hp_bar.value = hp


## Same, but keeps the current health fraction (difficulty switched mid-fight).
func rescale_hp(difficulty: BattleDifficulty) -> void:
	var ratio := float(hp) / float(max_hp)
	max_hp = maxi(roundi(base_max_hp * difficulty.boss_hp_multiplier), 1)
	hp = maxi(roundi(ratio * max_hp), 1)
	mercy_multiplier = difficulty.mercy_multiplier
	hp_bar.max_value = max_hp
	hp_bar.value = hp


func set_hp_ratio(ratio: float) -> void:
	hp = clampi(ceili(ratio * max_hp), 1, max_hp)
	hp_changed.emit(hp, max_hp)


# ---- data the BossBattle asks for -------------------------------------------------

func phase_number() -> int:
	return phases.find(phase) + 1


## Switches to the phase matching the current HP. Returns true if the phase changed.
func update_phase() -> bool:
	var ratio := float(hp) / float(max_hp)
	var target := phases[0]
	for candidate in phases:
		if ratio <= candidate.starts_at_hp_ratio:
			target = candidate
	if target == phase:
		return false
	phase = target
	return true


func get_acts() -> Array[BattleOption]:
	var result: Array[BattleOption] = []
	for child in acts_root.get_children():
		var option := child as BattleOption
		if option != null and option.uses != 0:
			result.append(option)
	return result


func next_attack() -> BossAttack:
	return phase.next_attack()


func add_mercy(amount: int) -> void:
	mercy = clampi(mercy + roundi(amount * mercy_multiplier), 0, spare_mercy_needed)


func can_be_spared() -> bool:
	return mercy >= spare_mercy_needed


# ---- combat feedback ----------------------------------------------------------

func take_hit(amount: int, perfect := false) -> void:
	var color := Color(1.0, 0.85, 0.2) if perfect else Color(1.0, 0.2, 0.2)
	_apply_damage(amount, color)
	await _shake()
	await _hide_bar_later()


func miss() -> void:
	_show_number("MISS", Color(0.7, 0.7, 0.7))
	await get_tree().create_timer(0.6).timeout


func apply_poison(damage_per_turn: int, turns: int) -> void:
	poison_damage = damage_per_turn
	poison_turns = turns


func is_poisoned() -> bool:
	return poison_turns > 0


func tick_poison() -> void:
	poison_turns -= 1
	_apply_damage(poison_damage, Color(0.4, 1.0, 0.4))
	await _hide_bar_later()


func play_phase_change() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "self_modulate", phase.tint, 0.4)
	await _shake()
	await tween.finished


func play_death() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.0)
	await tween.finished


func _apply_damage(amount: int, color: Color) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	hp_bar.max_value = max_hp
	hp_bar.show()
	create_tween().tween_property(hp_bar, "value", float(hp), 0.3)
	_show_number(str(amount), color)


func _show_number(label_text: String, color: Color) -> void:
	damage_label.text = label_text
	damage_label.add_theme_color_override(&"font_color", color)
	damage_label.position.y = _label_rest_y
	damage_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(damage_label, "position:y", _label_rest_y - 24.0, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.2)


func _shake() -> void:
	var base_x := visual.position.x
	var tween := create_tween()
	for i in 6:
		var side := 1.0 if i % 2 == 0 else -1.0
		var offset := 12.0 * (1.0 - float(i) / 6.0) * side
		tween.tween_property(visual, "position:x", base_x + offset, 0.04)
	tween.tween_property(visual, "position:x", base_x, 0.04)
	await tween.finished


func _hide_bar_later() -> void:
	await get_tree().create_timer(0.6).timeout
	hp_bar.hide()
