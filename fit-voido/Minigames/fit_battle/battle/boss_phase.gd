class_name BossPhase
extends Node
## One phase of the boss. Its children are BossAttack scenes, used in order (or at random).
## Add / remove / reorder phases under the enemy's "Phases" node. One BossPhase = a single-phase boss.

@export var display_name := "Phase 1"
## The phase starts once the boss HP ratio drops to this value or below (phase 1 = 1.0).
@export_range(0.0, 1.0) var starts_at_hp_ratio := 1.0
## Multiplied onto the boss sprite. Lets one sprite look different per phase.
@export var tint := Color(1, 1, 1, 1)
@export var random_order := false
@export_group("Text")
## Shown in the box when this phase begins (empty = nothing). Not used for phase 1.
@export_multiline var enter_text := ""
## Boss line when this phase begins.
@export var enter_speech := ""
@export var flavor_texts := PackedStringArray()
@export var speech_lines := PackedStringArray()

var _attack_index := 0


func get_flavor(turn: int) -> String:
	if flavor_texts.is_empty():
		return ""
	return flavor_texts[turn % flavor_texts.size()]


func get_speech(turn: int) -> String:
	if speech_lines.is_empty():
		return ""
	return speech_lines[turn % speech_lines.size()]


func next_attack() -> BossAttack:
	var patterns: Array[BossAttack] = []
	for child in get_children():
		if child is BossAttack:
			patterns.append(child)
	if patterns.is_empty():
		return null
	if random_order:
		return patterns.pick_random()
	var pattern := patterns[_attack_index % patterns.size()]
	_attack_index += 1
	return pattern
