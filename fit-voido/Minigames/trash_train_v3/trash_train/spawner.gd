class_name TrashSpawner
extends Node
## Owns the ground pickups: spawns them inside the level's TrashSpawnZones (weighted), pools the nodes,
## and finds legal landing spots for dropped items. Physics queries keep everything out of walls and
## bin zones; items also stay clear of the runner and of each other.
## If a level has no spawn zones, items appear anywhere inside the bounds.

signal collected(pickup: TrashPickup)

var tuning: TrashTrainTuning
var catalog: TrashItemCatalog
var zones: Array[TrashSpawnZone] = []
var bounds := Rect2()
var player: Node2D
var rng: RandomNumberGenerator
var timer := Timer.new()  # fires every tuning.spawn_interval, in the physics step

var _root: Node2D
var _pool: Array[TrashPickup] = []
var _active: Array[TrashPickup] = []
var _query := PhysicsShapeQueryParameters2D.new()
var _keepout := CircleShape2D.new()


func _init() -> void:
	timer.one_shot = false
	timer.autostart = false
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.timeout.connect(_on_timer)
	add_child(timer)


func setup(t: TrashTrainTuning, cat: TrashItemCatalog, zone_list: Array[TrashSpawnZone], pickups_root: Node2D, runner: Node2D, area: Rect2, random: RandomNumberGenerator) -> void:
	tuning = t
	catalog = cat
	zones = zone_list
	_root = pickups_root
	player = runner
	bounds = area
	rng = random


## Call once, inside the physics step (the walls must exist in the physics space).
func start() -> void:
	for i in tuning.start_items:
		spawn_one()
	timer.start(maxf(tuning.spawn_interval, 0.05))


func active() -> Array[TrashPickup]:
	return _active


func active_count() -> int:
	return _active.size()


func lifetime_for(def: TrashItemDef) -> float:
	return tuning.glitch_lifetime if def.tier == TrashItems.Tier.GLITCH else 0.0


func spawn_one() -> bool:
	if _active.size() >= tuning.max_pickups or catalog == null:
		return false
	var has_zones := false
	for z in zones:
		if z.has_area():
			has_zones = true
	for attempt in 24:
		var zone: TrashSpawnZone = null
		var pos: Vector2
		var def: TrashItemDef
		if has_zones:
			zone = _pick_zone()
			if zone == null:
				return false  # every zone is at its max_alive
			pos = zone.sample(rng)
			def = catalog.pick(rng, zone.kinds)
		else:
			pos = Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
			def = catalog.pick(rng)
		if def == null:
			return false
		if not _spawn_valid(pos, def):
			continue
		spawn_at(def, pos, zone)
		return true
	return false


func spawn_at(def: TrashItemDef, pos: Vector2, zone: TrashSpawnZone = null) -> TrashPickup:
	var p := _acquire()
	p.spawn_zone = zone
	if zone != null:
		zone.alive += 1
	p.activate(def, pos, lifetime_for(def))
	return p


## A dropped item: hops from `from` to `to`, collectable once it lands.
func drop(def: TrashItemDef, from: Vector2, to: Vector2) -> TrashPickup:
	var p := _acquire()
	p.spawn_zone = null
	p.launch(def, from, to, tuning.scatter_time, lifetime_for(def))
	return p


func release(p: TrashPickup) -> void:
	if not p.active:
		return
	p.deactivate()
	if p.spawn_zone != null:
		p.spawn_zone.alive = maxi(p.spawn_zone.alive - 1, 0)
		p.spawn_zone = null
	_active.erase(p)
	_pool.append(p)


## A landing spot near `from` that is inside the bounds and clear of walls and bin zones.
## `angle` fixes the direction of the first try (NAN = random); later tries fan out and shorten.
func scatter_target(from: Vector2, def: TrashItemDef, angle: float = NAN) -> Vector2:
	var hi := maxf(tuning.scatter_radius, tuning.scatter_min_radius)
	var area := bounds.grow(-24.0)
	var base := rng.randf() * TAU if is_nan(angle) else angle
	var shape := def.get_pickup_shape()
	for attempt in 8:
		var dist := rng.randf_range(tuning.scatter_min_radius, hi) * (1.0 - 0.08 * attempt)
		var p := from + Vector2.from_angle(base + attempt * 0.9) * dist
		if area.has_point(p) and _free_of_walls_and_bins(p, shape):
			return p
	return from


func _on_timer() -> void:
	timer.wait_time = maxf(tuning.spawn_interval, 0.05)
	spawn_one()


func _on_collected(p: TrashPickup) -> void:
	collected.emit(p)


func _acquire() -> TrashPickup:
	var p: TrashPickup
	if _pool.is_empty():
		p = TrashPickup.new()
		p.collected.connect(_on_collected)
		p.expired.connect(release)
		_root.add_child(p)
	else:
		p = _pool.pop_back()
	_active.append(p)
	return p


func _pick_zone() -> TrashSpawnZone:
	var eligible: Array[TrashSpawnZone] = []
	var total := 0.0
	for z in zones:
		if z.has_area() and z.weight > 0.0 and (z.max_alive == 0 or z.alive < z.max_alive):
			eligible.append(z)
			total += z.weight
	if eligible.is_empty():
		return null
	var r := rng.randf() * total
	for z in eligible:
		r -= z.weight
		if r <= 0.0:
			return z
	return eligible.back()


## A legal spot for something that is not trash (a power-up). With powerup = true only zones that
## allow power-ups are used. Returns Vector2.INF if nothing legal turns up.
func find_spot(shape: Shape2D, powerup: bool = false) -> Vector2:
	var any_area := false
	var allowed: Array[TrashSpawnZone] = []
	for z in zones:
		if z.has_area():
			any_area = true
			if z.weight > 0.0 and (not powerup or z.allow_powerups):
				allowed.append(z)
	for attempt in 24:
		var pos: Vector2
		if any_area:
			if allowed.is_empty():
				return Vector2.INF
			pos = _pick_weighted(allowed).sample(rng)
		else:
			pos = Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
		if _spot_valid(pos, shape):
			return pos
	return Vector2.INF


func _pick_weighted(list: Array[TrashSpawnZone]) -> TrashSpawnZone:
	var total := 0.0
	for z in list:
		total += z.weight
	var r := rng.randf() * total
	for z in list:
		r -= z.weight
		if r <= 0.0:
			return z
	return list.back()


func _spawn_valid(pos: Vector2, def: TrashItemDef) -> bool:
	return _spot_valid(pos, def.get_pickup_shape())


func _spot_valid(pos: Vector2, shape: Shape2D) -> bool:
	if not bounds.grow(-tuning.spawn_margin).has_point(pos):
		return false
	if pos.distance_to(player.global_position) < tuning.spawn_clear_radius:
		return false
	for p in _active:
		if p.global_position.distance_to(pos) < tuning.spawn_min_separation:
			return false
	return _free_of_walls_and_bins(pos, shape)


func _free_of_walls_and_bins(pos: Vector2, shape: Shape2D) -> bool:
	var space := player.get_world_2d().direct_space_state
	_query.transform = Transform2D(0.0, pos)
	_query.shape = shape
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.collision_mask = TrashLayers.WALLS
	if not space.intersect_shape(_query, 1).is_empty():
		return false
	_keepout.radius = tuning.bin_keepout
	_query.shape = _keepout
	_query.collide_with_bodies = false
	_query.collide_with_areas = true
	_query.collision_mask = TrashLayers.BINS
	return space.intersect_shape(_query, 1).is_empty()
