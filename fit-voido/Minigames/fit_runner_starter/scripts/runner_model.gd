class_name RunnerModel
extends RefCounted
## Pure simulation, no nodes and no input: effort -> pace (with inertia) -> stamina -> ground speed.
## The runner, the par bot, the "will you make it" prediction and the headless sim all use this one class.

var tuning: RunnerTuning
var course: CourseProfile

var pos: float = 0.0
var prev_pos: float = 0.0
var pace: float = 0.0  ## the runner's own output as a fraction of max_speed (can exceed 1.0 in the spurt)
var stamina: float = 100.0
var walled: bool = false
var walls_hit: int = 0
var drinking: bool = false
var drink_left: float = 0.0
var station_used: bool = false
var elapsed: float = 0.0
var finished: bool = false
var finish_time: float = 0.0
var assist_level: int = 0
var rate: float = 0.0  ## stamina change per second on the last step (+ recover, - drain)
var slope_norm: float = 0.0  ## -1 (steep down) .. +1 (steep up)
var ground_speed: float = 0.0


func _init(p_tuning: RunnerTuning, p_course: CourseProfile = null) -> void:
	tuning = p_tuning
	course = p_course if p_course != null else CourseProfile.new(p_tuning)
	stamina = tuning.stamina_max


func progress() -> float:
	return pos / tuning.track_length


func in_station() -> bool:
	var p: float = progress()
	return (not station_used) and p >= tuning.station_start and p < tuning.station_end


func in_spurt() -> bool:
	return progress() >= tuning.spurt_start


## Take the cup (once per station). Returns true if it started now.
func request_drink() -> bool:
	if station_used or drinking:
		return false
	station_used = true
	drinking = true
	drink_left = tuning.water_duration
	return true


## Stamina change per second for a given pace: smooth curve through your four tier numbers.
func drain_rate(p: float) -> float:
	var ap: PackedFloat32Array = tuning.anchor_paces
	var r0: float = tuning.rate_recover
	var r1: float = tuning.rate_cruise
	var r2: float = tuning.rate_push
	var r3: float = tuning.rate_sprint
	if p <= ap[0]:
		return r0
	if p <= ap[1]:
		return lerpf(r0, r1, (p - ap[0]) / (ap[1] - ap[0]))
	if p <= ap[2]:
		return lerpf(r1, r2, (p - ap[1]) / (ap[2] - ap[1]))
	if p <= ap[3]:
		return lerpf(r2, r3, (p - ap[2]) / (ap[3] - ap[2]))
	return r3


func step(dt: float, effort: float) -> void:
	if finished:
		return
	var t: RunnerTuning = tuning
	var prog: float = pos / t.track_length
	var spurt: bool = prog >= t.spurt_start
	var sn: float = clampf(course.slope_at(pos) / t.slope_ref, -1.0, 1.0)
	slope_norm = sn

	# effort -> target pace, limited by the wall and by drinking, then inertia
	var cap_mult: float = t.spurt_speed_cap if spurt else 1.0
	var target: float = effort * cap_mult
	if drinking:
		target = minf(target, t.water_speed_cap)
	if walled:
		target = minf(target, t.wall_speed_cap)
	if target > pace:
		pace = minf(target, pace + t.speed_accel * dt)
	else:
		pace = maxf(target, pace - t.speed_decel * dt)

	# pace -> stamina
	var r: float = drain_rate(pace)
	if r < 0.0:
		var m: float = 1.0
		if sn > 0.0:
			m *= 1.0 + t.uphill_drain_extra * sn
		if spurt:
			m *= t.spurt_drain_mult
		if walls_hit >= 2:
			m *= t.wall_assist_mult
		if assist_level > 0:
			m *= t.assist_mult
		r *= m
	elif walled and effort >= t.wall_hold_threshold:
		r = 0.0  # holding at the wall: no recovery until the player lets go
	var gain: float = 0.0
	if drinking:
		gain = t.water_amount * dt / t.water_duration
		drink_left -= dt
		if drink_left <= 0.0:
			drinking = false
	rate = r
	stamina = clampf(stamina + r * dt + gain, 0.0, t.stamina_max)
	if (not walled) and stamina <= 0.0:
		walled = true
		walls_hit += 1
	elif walled and stamina >= t.wall_release:
		walled = false

	# pace -> ground speed (hills change speed for free; drain was already charged above)
	var gm: float = 1.0
	if sn > 0.0:
		gm -= t.uphill_speed_penalty * sn
	elif sn < 0.0:
		gm += t.downhill_speed_bonus * (-sn)
	ground_speed = pace * t.max_speed * gm
	prev_pos = pos
	pos += ground_speed * dt
	elapsed += dt
	if pos >= t.track_length:
		finished = true
		var span: float = pos - prev_pos
		var frac: float = (t.track_length - prev_pos) / span if span > 0.0 else 1.0
		finish_time = elapsed - dt + dt * frac


func clone() -> RunnerModel:
	var c := RunnerModel.new(tuning, course)
	c.pos = pos
	c.prev_pos = prev_pos
	c.pace = pace
	c.stamina = stamina
	c.walled = walled
	c.walls_hit = walls_hit
	c.drinking = drinking
	c.drink_left = drink_left
	c.station_used = station_used
	c.elapsed = elapsed
	c.finished = finished
	c.finish_time = finish_time
	c.assist_level = assist_level
	return c
