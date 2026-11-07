class_name FitRunnerResult
extends RefCounted
## Result of one attempt. Emitted by FitRunner.run_finished(result).

var passed: bool = false
var completed: bool = false
var race_mode: int = 0
var placement: int = 1
var entrants: int = 1
var time_sec: float = 0.0  ## finish time (for a failed run: the time when the cutoff hit)
var stars: int = 0  ## 0 when not passed, otherwise 1-3
var walls_hit: int = 0
var attempt: int = 1
var par_time: float = 0.0
var input_mode: int = 0  ## 0 = hold/release (A), 1 = hold-time tiers (B)
var qte_perfect: int = 0
var qte_good: int = 0
var qte_miss: int = 0


func to_dict() -> Dictionary:
	return {
		"completed": completed,
		"race_mode": race_mode,
		"placement": placement,
		"entrants": entrants,
		"passed": passed,
		"time_sec": time_sec,
		"stars": stars,
		"walls_hit": walls_hit,
		"attempt": attempt,
		"par_time": par_time,
		"input_mode": input_mode,
		"qte_perfect": qte_perfect,
		"qte_good": qte_good,
		"qte_miss": qte_miss,
	}
