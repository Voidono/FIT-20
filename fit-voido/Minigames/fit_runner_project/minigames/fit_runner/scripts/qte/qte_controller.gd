class_name FrQteController
extends Node
## Recovery quick-time event. While the runner is resting (hands off, pace in the recover zone) a timing bar appears;
## tap when the cursor is on the sweet spot for bonus stamina. This node only judges timing and reports the result:
## FitRunner applies the stamina, the Hud draws the bar. Settings come from a FrQteSettings resource.

signal started(target_center: float, perfect_width: float, good_width: float)
signal resolved(grade: int, bonus: float, streak: int)
signal cancelled

enum Grade { MISS, GOOD, PERFECT }
enum Phase { IDLE, ACTIVE, FEEDBACK }

@export var settings: FrQteSettings
@export var preset_easy: FrQteSettings
@export var preset_normal: FrQteSettings
@export var preset_hard: FrQteSettings

var phase: int = Phase.IDLE
var elapsed: float = 0.0
var target_center: float = 0.5
var streak: int = 0
var perfect_count: int = 0
var good_count: int = 0
var miss_count: int = 0
var forced_off: bool = false

var _rest_time: float = 0.0
var _cooldown: float = 0.0
var _feedback_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func reset(seed_value: int) -> void:
	phase = Phase.IDLE
	elapsed = 0.0
	streak = 0
	perfect_count = 0
	good_count = 0
	miss_count = 0
	_rest_time = 0.0
	_cooldown = 0.0
	_feedback_left = 0.0
	_rng.seed = seed_value  # same attempt, same sweet-spot positions


func is_enabled() -> bool:
	return settings != null and settings.enabled and not forced_off


func is_active() -> bool:
	return is_enabled() and phase == Phase.ACTIVE


## 0..1 position of the cursor along the bar.
func cursor() -> float:
	if settings == null:
		return 0.0
	return clampf(elapsed / maxf(settings.duration, 0.01), 0.0, 1.0)


## 0 = off, 1 = easy, 2 = normal, 3 = hard (the debug overlay's drop-down).
func apply_preset(index: int) -> void:
	if index == 0:
		forced_off = true
		if phase != Phase.IDLE:
			_cancel()
		return
	forced_off = false
	var chosen: FrQteSettings = null
	match index:
		1:
			chosen = preset_easy
		2:
			chosen = preset_normal
		3:
			chosen = preset_hard
	if chosen != null:
		settings = chosen


## Call once per simulation tick. resting: the runner is recovering and the player is not pushing.
func tick(dt: float, resting: bool) -> void:
	if not is_enabled():
		if phase != Phase.IDLE:
			_cancel()
		return
	_cooldown = maxf(_cooldown - dt, 0.0)
	match phase:
		Phase.IDLE:
			if resting:
				_rest_time += dt
				if _rest_time >= settings.rest_time_before_event and _cooldown <= 0.0:
					_start()
			else:
				_rest_time = 0.0
		Phase.ACTIVE:
			if not resting:
				_cancel()  # the player went back to running: no penalty
				return
			elapsed += dt
			if elapsed >= settings.duration:
				_resolve(Grade.MISS)
		Phase.FEEDBACK:
			_rest_time = _rest_time + dt if resting else 0.0
			_feedback_left -= dt
			if _feedback_left <= 0.0:
				phase = Phase.IDLE


## The player tapped. extra_time = time already accumulated into the current tick, so the judge matches what was on screen.
func on_tap(extra_time: float = 0.0) -> void:
	if not is_active():
		return
	var c: float = clampf((elapsed + extra_time) / settings.duration, 0.0, 1.0)
	var d: float = absf(c - target_center)
	if d <= settings.perfect_width * 0.5:
		_resolve(Grade.PERFECT)
	elif d <= settings.good_width * 0.5:
		_resolve(Grade.GOOD)
	else:
		_resolve(Grade.MISS)


func _start() -> void:
	var half: float = settings.good_width * 0.5
	target_center = clampf(settings.target_center + _rng.randf_range(-settings.target_jitter, settings.target_jitter), half, 1.0 - half)
	elapsed = 0.0
	_rest_time = 0.0
	phase = Phase.ACTIVE
	started.emit(target_center, settings.perfect_width, settings.good_width)


func _cancel() -> void:
	phase = Phase.IDLE
	_rest_time = 0.0
	cancelled.emit()


func _resolve(grade: int) -> void:
	var bonus: float = 0.0
	match grade:
		Grade.PERFECT:
			bonus = settings.perfect_bonus + settings.streak_step * float(mini(streak, settings.streak_cap))
			streak += 1
			perfect_count += 1
		Grade.GOOD:
			bonus = settings.good_bonus
			streak = 0
			good_count += 1
		_:
			bonus = -settings.miss_penalty
			streak = 0
			miss_count += 1
	phase = Phase.FEEDBACK
	_feedback_left = settings.feedback_time
	_cooldown = settings.cooldown
	resolved.emit(grade, bonus, streak)
