class_name TrashRunStats
extends RefCounted
## Everything a run accumulates. Step 8 turns this into the run_finished(result) payload.

var score := 0.0
var items_banked := 0
var banks := 0  # bin visits that banked something
var best_bank := 0.0
var bumps := 0  # NPC hits that cut the tail
var items_lost := 0  # items dropped by bumps


func reset() -> void:
	score = 0.0
	items_banked = 0
	banks = 0
	best_bank = 0.0
	bumps = 0
	items_lost = 0
