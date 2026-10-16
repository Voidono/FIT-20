class_name RunResult
extends RefCounted
## Result of one attempt. Emitted by FitRunner.run_finished(result).

var passed: bool = false
var time_sec: float = 0.0  ## finish time (for a failed run: the time when the cutoff hit)
var stars: int = 0  ## 0 when not passed, otherwise 1-3
var walls_hit: int = 0
var attempt: int = 1
var par_time: float = 0.0
var input_mode: int = 0  ## 0 = hold/release (A), 1 = hold-time tiers (B)


func to_dict() -> Dictionary:
	return {
		"passed": passed,
		"time_sec": time_sec,
		"stars": stars,
		"walls_hit": walls_hit,
		"attempt": attempt,
		"par_time": par_time,
		"input_mode": input_mode,
	}
