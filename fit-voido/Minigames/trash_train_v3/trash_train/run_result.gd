class_name TrashRunResult
extends RefCounted
## What one attempt produced. Emitted by TrashTrain.run_finished when the clock runs out.
## passed / banked_score / stars / bumps_taken are the fields the quest system needs.

var passed := false
var stars := 0  # 0 = not passed, 1-3 = passed
var banked_score := 0.0
var bumps_taken := 0
var items_banked := 0
var items_lost := 0  # dropped by bumps (they can be picked up again, so this is "ever dropped")
var unbanked_points := 0.0  # still in the tail when time ran out (worth nothing)
var time_used := 0.0
var duration := 0.0  # the clock this attempt started with (includes the quiet assist)
var assist_applied := false
var attempt := 0  # 1 = first attempt this session
var failed_attempts := 0  # total failed attempts so far, including this one if it failed


func to_dict() -> Dictionary:
	return {
		"passed": passed, "stars": stars, "banked_score": banked_score, "bumps_taken": bumps_taken,
		"items_banked": items_banked, "items_lost": items_lost, "unbanked_points": unbanked_points,
		"time_used": time_used, "duration": duration, "assist_applied": assist_applied,
		"attempt": attempt, "failed_attempts": failed_attempts,
	}
