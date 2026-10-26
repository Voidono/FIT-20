extends Node
## EXAMPLE, not wired to anything: how Level 1 of the main game can offer the two minigames and award Time Stone #1.
## Replace the signal and the comments with your quest / inventory system.

signal time_stone_awarded(number: int)

var _fit_runner_attempts: int = 0
var _active: FitRunner


## Called by your Level 1 menu when the player picks FIT Runner.
func start_fit_runner() -> void:
	_fit_runner_attempts += 1
	var config := FitRunnerConfig.new()
	config.attempt = _fit_runner_attempts
	config.assist_level = 1 if _fit_runner_attempts > 3 else 0  # a little help after repeated fails
	_active = FitRunnerLauncher.create(config)
	_active.run_finished.connect(_on_run_finished)
	_active.quit_requested.connect(_on_quit_requested)
	add_child(_active)  # or put it under your own "minigame layer" node


func _on_run_finished(result: FitRunnerResult) -> void:
	if result.passed:
		time_stone_awarded.emit(1)  # e.g. Quests.complete("level1_minigame"); Inventory.add_time_stone(1)
		# result.stars (1-3), result.time_sec, result.walls_hit, result.qte_perfect ... feed achievements / a leaderboard here
	# a failed run: do nothing, the minigame's Retry button starts the next attempt itself (attempt + 1)


func _on_quit_requested() -> void:
	if is_instance_valid(_active):
		_active.queue_free()  # the minigame hands your camera back in _exit_tree
		_active = null
	# then continue your level flow: show the map, play the "got the stone" dialogue, switch scene...
