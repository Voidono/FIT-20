class_name TrashPowerups
extends Node
## The three power-ups: MAGNET, SNEAKERS, SHIELD. They appear on the map one at a time (first after
## powerup_first_delay, then every powerup_interval, vanishing after powerup_lifetime), switch on when
## the runner touches them, stack with each other, and refresh when taken again.
##   Magnet:   trash within magnet_radius flies to you (only while the tail has room)
##   Sneakers: speed x sneakers_speed and the weight slowdown is ignored
##   Shield:   absorbs the next NPC hit (never wasted on an empty tail)
## Spawn spots come from the level's spawn zones that have allow_powerups on. Everything here lives
## under the World node, so the ready and result screens freeze it.

signal collected(id: StringName)

const MAGNET := &"magnet"
const SNEAKERS := &"sneakers"
const SHIELD := &"shield"
const IDS: Array[StringName] = [&"magnet", &"sneakers", &"shield"]
const GRAB_RANGE := 24.0  # the magnet hands an item over when it is this close

var tuning: TrashTrainTuning
var spawner: TrashSpawner
var player: TrashPlayer
var tail: TrashTail
var rng: RandomNumberGenerator
var host: Node2D  # where map pickups are added
var on_map: TrashPowerupPickup  # at most one
var taken := 0  # how many were picked up this run

var _left := {}  # id -> seconds left
var _spawn_in := 0.0
var _bag: Array[StringName] = []
var _last_id: StringName = &""
var _shape := CircleShape2D.new()
var _aura: Aura
var _no_effects: Array[Dictionary] = []


class Aura:
	extends Node2D
	var fx: TrashPowerups
	var _t := 0.0
	var _drawn := false

	func _init() -> void:
		z_index = 1  # just above the runner

	func _process(delta: float) -> void:
		_t += delta
		var on := fx != null and fx.any_active()
		if on or _drawn:
			queue_redraw()
		_drawn = on

	func _draw() -> void:
		if fx == null:
			return
		if fx.is_active(TrashPowerups.MAGNET):
			var r := fx.tuning.magnet_radius * (0.97 + 0.03 * sin(_t * 6.0))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 0.35, 0.35, 0.32), 2.0)
			draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 48, Color(1.0, 0.35, 0.35, 0.14), 2.0)
		if fx.is_active(TrashPowerups.SNEAKERS):
			var body := get_parent() as CharacterBody2D
			var v := body.velocity if body != null else Vector2.ZERO
			if v.length() > 20.0:
				var dir := -v.normalized()
				var perp := dir.orthogonal()
				for i in 3:
					var off := (i - 1) * 9.0
					var tip := 38.0 + 6.0 * sin(_t * 30.0 + i)
					draw_line(dir * 20.0 + perp * off, dir * tip + perp * off, Color(1.0, 0.85, 0.2, 0.7), 3.0)
		if fx.is_active(TrashPowerups.SHIELD):
			var left := fx.seconds_left(TrashPowerups.SHIELD)
			var a := 1.0 if left > 3.0 else 0.35 + 0.65 * absf(sin(_t * 14.0))  # flickers when about to end
			draw_circle(Vector2.ZERO, 27.0, Color(0.3, 0.8, 1.0, 0.16 * a))
			draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 40, Color(0.5, 0.9, 1.0, 0.85 * a), 3.0)


func setup(t: TrashTrainTuning, sp: TrashSpawner, runner: TrashPlayer, tl: TrashTail, random: RandomNumberGenerator, parent: Node2D) -> void:
	tuning = t
	spawner = sp
	player = runner
	tail = tl
	rng = random
	host = parent
	process_priority = 12
	_spawn_in = tuning.powerup_first_delay
	_shape.radius = TrashPowerupPickup.RADIUS + 6.0
	_aura = Aura.new()
	_aura.fx = self
	runner.add_child(_aura)


# --- queries ---------------------------------------------------------------------

func is_active(id: StringName) -> bool:
	return _left.has(id)


func any_active() -> bool:
	return not _left.is_empty()


func seconds_left(id: StringName) -> float:
	return _left.get(id, 0.0)


func fraction(id: StringName) -> float:
	return clampf(seconds_left(id) / seconds_for(id), 0.0, 1.0)


func seconds_for(id: StringName) -> float:
	match id:
		MAGNET:
			return tuning.magnet_seconds
		SNEAKERS:
			return tuning.sneakers_seconds
		SHIELD:
			return tuning.shield_seconds
	return 1.0


## Active effects for the HUD: [{id, color, fraction}] in a fixed order.
func hud_state() -> Array[Dictionary]:
	if _left.is_empty():
		return _no_effects
	var out: Array[Dictionary] = []
	for id in IDS:
		if _left.has(id):
			out.append({"id": id, "color": color_of(id), "fraction": fraction(id)})
	return out


func active_text() -> String:
	var parts: Array[String] = []
	for id in IDS:
		if _left.has(id):
			parts.append("%s %.1f" % [id, _left[id]])
	return ", ".join(parts) if not parts.is_empty() else "-"


func map_text() -> String:
	return "%s (%.1f s)" % [on_map.id, on_map.seconds_left()] if is_instance_valid(on_map) else "-"


func next_in() -> float:
	return maxf(_spawn_in, 0.0)


# --- hooks the rest of the game calls ----------------------------------------------

## The runner's speed factor. `weight` is the tail slowdown factor it would normally use.
func speed_factor(weight: float) -> float:
	return tuning.sneakers_speed if _left.has(SNEAKERS) else weight


## The NPC referee asks this when a hit lands: true = the shield took it (and is used up).
func consume_shield() -> bool:
	if _left.has(SHIELD):
		_left.erase(SHIELD)
		return true
	return false


# --- effects and spawning ------------------------------------------------------------

## Switch an effect on (or refresh it to full time).
func activate(id: StringName) -> void:
	_left[id] = seconds_for(id)
	taken += 1
	collected.emit(id)


## Put one on the map now at a legal spot. id empty = the next one from the shuffled bag.
## replace = true removes the one already lying there first. False if no legal spot was found.
func spawn_now(id: StringName = &"", replace: bool = false) -> bool:
	if is_instance_valid(on_map):
		if not replace:
			return false
		on_map.queue_free()
		on_map = null
	var pos := spawner.find_spot(_shape, true)
	if pos == Vector2.INF:
		return false
	spawn_at(id if id != &"" else _next_id(), pos)
	return true


func spawn_at(id: StringName, pos: Vector2) -> TrashPowerupPickup:
	var p := TrashPowerupPickup.new()
	p.setup(id, tuning.powerup_lifetime)
	p.position = pos
	p.collected.connect(_on_pickup_collected)
	p.expired.connect(_on_pickup_expired)
	host.add_child(p)
	on_map = p
	_last_id = id
	return p


func _on_pickup_collected(p: TrashPowerupPickup) -> void:
	if on_map == p:
		on_map = null
	var id := p.id
	p.queue_free()  # safe inside the physics callback
	activate(id)


func _on_pickup_expired(p: TrashPowerupPickup) -> void:
	if on_map == p:
		on_map = null
	p.queue_free()


## Each of the three comes round once before any repeats, and never twice in a row.
func _next_id() -> StringName:
	if _bag.is_empty():
		_bag = IDS.duplicate()
		for i in range(_bag.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := _bag[i]
			_bag[i] = _bag[j]
			_bag[j] = tmp
		if _bag.back() == _last_id and _bag.size() > 1:
			var swap := _bag[0]
			_bag[0] = _bag.back()
			_bag[_bag.size() - 1] = swap
	return _bag.pop_back()


func _physics_process(delta: float) -> void:
	for id in _left.keys():
		_left[id] = _left[id] - delta
		if _left[id] <= 0.0:
			_left.erase(id)
	if _left.has(MAGNET):
		_pull(delta)
	if not tuning.powerups_enabled:
		return
	_spawn_in -= delta
	if _spawn_in <= 0.0:
		if is_instance_valid(on_map):
			_spawn_in = 0.5  # one at a time: wait until it is gone
		elif spawn_now():
			_spawn_in = tuning.powerup_interval
		else:
			_spawn_in = 1.0  # no legal spot right now: look again soon


## Magnet: trash inside the radius slides toward the runner and is handed over when it arrives.
## It stops pulling once the tail is full, so nothing piles up under the runner.
func _pull(delta: float) -> void:
	var room := 1000000
	if tuning.tail_cap > 0:
		room = tuning.tail_cap - tail.count()
	if room <= 0:
		return
	var me := player.global_position
	var r2 := tuning.magnet_radius * tuning.magnet_radius
	var step := tuning.magnet_pull_speed * delta
	for p in spawner.active():
		if p.is_flying():
			continue
		var d := p.global_position - me
		var dist2 := d.length_squared()
		if dist2 > r2:
			continue
		var dist := sqrt(dist2)
		if dist <= GRAB_RANGE:
			spawner.collected.emit(p)  # same path as touching it
			room -= 1
			if room <= 0:
				return
		else:
			p.global_position -= d / dist * minf(step, dist)


# --- looks -------------------------------------------------------------------------

static func color_of(id: StringName) -> Color:
	match id:
		MAGNET:
			return Color("ff5a5a")
		SNEAKERS:
			return Color("ffd93a")
		SHIELD:
			return Color("4ad0ff")
	return Color.WHITE


## Placeholder icons, drawn from shapes. Call from inside a CanvasItem's _draw().
static func draw_icon(ci: CanvasItem, id: StringName, color: Color, k: float) -> void:
	match id:
		MAGNET:  # a horseshoe with white tips
			ci.draw_arc(Vector2(0.0, -1.0) * k, 7.0 * k, 0.0, PI, 14, color, 4.0 * k)
			ci.draw_line(Vector2(-7.0, -1.0) * k, Vector2(-7.0, -8.0) * k, color, 4.0 * k)
			ci.draw_line(Vector2(7.0, -1.0) * k, Vector2(7.0, -8.0) * k, color, 4.0 * k)
			ci.draw_line(Vector2(-7.0, -8.0) * k, Vector2(-7.0, -5.0) * k, Color.WHITE, 4.0 * k)
			ci.draw_line(Vector2(7.0, -8.0) * k, Vector2(7.0, -5.0) * k, Color.WHITE, 4.0 * k)
		SNEAKERS:  # two speed chevrons
			ci.draw_polyline(PackedVector2Array([Vector2(-9, -7) * k, Vector2(-2, 0) * k, Vector2(-9, 7) * k]), color, 4.0 * k)
			ci.draw_polyline(PackedVector2Array([Vector2(0, -7) * k, Vector2(7, 0) * k, Vector2(0, 7) * k]), color, 4.0 * k)
		SHIELD:
			var pts := PackedVector2Array([Vector2(0, -10) * k, Vector2(9, -6) * k, Vector2(9, 2) * k, Vector2(0, 11) * k, Vector2(-9, 2) * k, Vector2(-9, -6) * k])
			ci.draw_colored_polygon(pts, color)
			var closed := pts.duplicate()
			closed.append(pts[0])
			ci.draw_polyline(closed, Color.WHITE, 2.0 * k)
