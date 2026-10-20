class_name TrashNpcs
extends Node
## NPC referee. Every physics frame (after the runner, the tail and the routes have moved) it asks each
## NPC what it is touching, and cuts the tail at the touched item closest to the runner (touching the
## runner itself = index 0 = everything drops). Then bump_invulnerability seconds of immunity follow.
## A hit on an empty tail does nothing. tuning.npc_count limits how many NPCs are active (first N).

signal bumped(cut_index: int)

var tuning: TrashTrainTuning
var tail: TrashTail
var invuln_left := 0.0

var _npcs: Array[TrashNpc] = []


func setup(t: TrashTrainTuning, tl: TrashTail) -> void:
	tuning = t
	tail = tl
	process_priority = 20


## Call after the routes have created their NPCs.
func refresh() -> void:
	_npcs.clear()
	for n in get_tree().get_nodes_in_group(&"trash_npc"):
		_npcs.append(n as TrashNpc)


func all() -> Array[TrashNpc]:
	return _npcs


func freeze_all(seconds: float) -> void:
	for n in _npcs:
		n.freeze(seconds)


func active_count() -> int:
	var c := 0
	for n in _npcs:
		if n.enabled:
			c += 1
	return c


func frozen_count() -> int:
	var c := 0
	for n in _npcs:
		if n.enabled and n.frozen_left > 0.0:
			c += 1
	return c


func _physics_process(delta: float) -> void:
	if tuning == null:
		return
	invuln_left = maxf(0.0, invuln_left - delta)
	for i in _npcs.size():
		var on := i < tuning.npc_count
		if _npcs[i].enabled != on:
			_npcs[i].set_enabled(on)
	if invuln_left > 0.0 or tail.count() == 0:
		return
	var best := tail.count()
	for n in _npcs:
		var i := n.hit_index()
		if i >= 0 and i < best:
			best = i
	if best < tail.count():
		invuln_left = tuning.bump_invulnerability
		bumped.emit(best)
