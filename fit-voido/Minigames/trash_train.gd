class_name TrashTrain
extends Node2D
## Trash Train, steps 1-3: movement, pick-up, tail, bins + banking + score, NPCs + bump scatter.
## The node tree is built in _ready(), so the scene file only needs this script on a Node2D.
## This node also draws the placeholder yard.
##
## TrashTrain (Node2D)                 this script
## |- Bins (Node2D)                    2 x TrashBin (Area2D): E-waste left, General right
## |- TrashNpcs (Node2D)               routes + bump test (process priority 20)
## |- Pickups (Node2D)                 pooled TrashPickup (Area2D), capped by tuning.max_pickups
## |- TrashPlayer (CharacterBody2D)    has the Camera2D as a child
## |- TrashTail (Node2D)               processes after the player (process_priority 10)
## |- TrashPopups (Node2D)             floating "+7.5" text
## '- UI (CanvasLayer, layer 10)
##    |- TrashPointer (Node2D)         mouse + touch -> move vector
##    |- TrashHud (Control)            score
##    '- TrashDebugOverlay (Control)   readouts, test buttons, tuning sliders

const GOLDEN_ANGLE := 2.399963  # radians; consecutive drops fan out instead of piling up

@export var tuning: TrashTrainTuning  # leave empty to use the defaults in tuning.gd

var stats := TrashRunStats.new()

var _player: TrashPlayer
var _tail: TrashTail
var _pointer: TrashPointer
var _overlay: TrashDebugOverlay
var _hud: TrashHud
var _npcs: TrashNpcs
var _popups: TrashPopups
var _camera: Camera2D
var _pickups: Node2D
var _bins: Array[TrashBin] = []
var _pool: Array[TrashPickup] = []
var _rng := RandomNumberGenerator.new()
var _spawn_left := 0.0
var _info_left := 0.0
var _full_cooldown := 0.0
var _last_event := "-"


func _ready() -> void:
	if tuning == null:
		tuning = TrashTrainTuning.new()
	_rng.randomize()

	_pointer = TrashPointer.new()
	_tail = TrashTail.new()
	_player = TrashPlayer.new()
	_player.setup(tuning, _pointer, _tail)
	_player.position = tuning.map_size * 0.5
	_npcs = TrashNpcs.new()
	_npcs.setup(tuning, _player, _tail)
	_npcs.bumped.connect(_on_bumped)
	_popups = TrashPopups.new()

	# tree order = draw order inside the same z: bins, NPC route lines, ground pickups
	var bins_root := Node2D.new()
	bins_root.name = "Bins"
	add_child(bins_root)
	var zone := tuning.bin_size
	var top := tuning.map_size.y * 0.5 - zone.y * 0.5
	_add_bin(bins_root, TrashItems.Bin.EWASTE, Rect2(0.0, top, zone.x, zone.y))
	_add_bin(bins_root, TrashItems.Bin.GENERAL, Rect2(tuning.map_size.x - zone.x, top, zone.x, zone.y))
	add_child(_npcs)
	_pickups = Node2D.new()
	_pickups.name = "Pickups"
	add_child(_pickups)
	add_child(_player)  # before the tail, so it moves first each frame
	_tail.setup(tuning, _player)
	add_child(_tail)
	add_child(_popups)

	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(tuning.map_size.x)
	_camera.limit_bottom = int(tuning.map_size.y)
	_player.add_child(_camera)
	_camera.make_current()

	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 10
	add_child(ui)
	_pointer.tuning = tuning
	_pointer.follow_target = _player
	ui.add_child(_pointer)
	_hud = TrashHud.new()
	ui.add_child(_hud)
	_overlay = TrashDebugOverlay.new()
	ui.add_child(_overlay)
	_overlay.setup(tuning)
	_overlay.action_requested.connect(_on_action)
	_pointer.blockers.append(_overlay.panel)
	_pointer.blockers.append(_overlay.toggle_button)

	for i in tuning.start_items:
		_spawn_one()
	_spawn_left = tuning.spawn_interval


func _add_bin(parent: Node, bin_type: int, zone: Rect2) -> void:
	var b := TrashBin.new()
	b.setup(bin_type, zone)
	parent.add_child(b)
	_bins.append(b)


func _physics_process(_delta: float) -> void:
	# Banking is automatic: being inside a bin zone with matching items banks them.
	for b in _bins:
		if b.player_inside and _tail.count_bin(b.bin) > 0:
			_bank_bin(b.bin)


func _process(delta: float) -> void:
	var zoom := Vector2.ONE * tuning.camera_zoom
	if not _camera.zoom.is_equal_approx(zoom):
		_camera.zoom = zoom
	_camera.position_smoothing_enabled = tuning.camera_smoothing > 0.0
	_camera.position_smoothing_speed = maxf(tuning.camera_smoothing, 0.1)

	_spawn_left = minf(_spawn_left, tuning.spawn_interval) - delta
	if _spawn_left <= 0.0:
		_spawn_left += tuning.spawn_interval
		_spawn_one()
	_full_cooldown = maxf(0.0, _full_cooldown - delta)

	# blink the runner and the tail while the post-bump immunity lasts
	var alpha := 1.0
	if _npcs.invuln_left > 0.0:
		alpha = 0.35 + 0.65 * absf(sin(_npcs.invuln_left * 18.0))
	_player.modulate.a = alpha
	_tail.modulate.a = alpha

	_info_left -= delta
	if _info_left <= 0.0:
		_info_left = 0.1
		_overlay.info.text = _info_text()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_F3:
			_overlay.toggle()
		KEY_1:
			_on_action(&"bank_ewaste")
		KEY_2:
			_on_action(&"bank_general")
		KEY_3:
			_on_action(&"cut")
		KEY_4:
			_on_action(&"freeze")
		KEY_R:
			_on_action(&"routes")
		KEY_C:
			_on_action(&"mode")


# --- banking ---------------------------------------------------------------------

## [item count, points, payout] if this bin were entered right now.
func _bin_stats(bin: int) -> Array:
	var count := 0
	var pts := 0.0
	for i in _tail.count():
		var k := _tail.kind_at(i)
		if TrashItems.bin_of(k) == bin:
			count += 1
			pts += tuning.points_for(TrashItems.tier_of(k))
	return [count, pts, tuning.payout(pts, count)]


## Pays sum(points) x (1 + multiplier_per_item x items banked in THIS visit) for the bin's own items.
func _bank_bin(bin: int) -> void:
	var stats_now := _bin_stats(bin)
	var taken := _tail.take_bin(bin)
	if taken.is_empty():
		return
	var pay: float = stats_now[2]
	stats.score += pay
	stats.items_banked += taken.size()
	stats.banks += 1
	stats.best_bank = maxf(stats.best_bank, pay)
	_hud.set_score(stats.score)
	_popups.add("+" + TrashStrings.num(pay), _player.global_position + Vector2(0.0, -40.0), TrashItems.bin_color(bin).lightened(0.5), 36)
	_last_event = "%s bin: %d items, %.1f pts x%.2f = %.1f" % [
		TrashItems.BIN_NAMES[bin], taken.size(), stats_now[1],
		1.0 + tuning.multiplier_per_item * taken.size(), pay]


# --- bumps -------------------------------------------------------------------------

func _on_bumped(index: int) -> void:
	var dropped := _tail.cut_at(index)
	if dropped.is_empty():
		return
	stats.bumps += 1
	stats.items_lost += dropped.size()
	var base_angle := _rng.randf() * TAU
	for j in dropped.size():
		var from: Vector2 = dropped[j]["pos"]
		var kind: int = dropped[j]["kind"]
		var to := _scatter_target(from, base_angle + j * GOLDEN_ANGLE)
		_acquire_pickup().launch(kind, from, to, tuning.scatter_time, _lifetime_for(kind))
	_popups.add(TrashStrings.t(&"bump"), _player.global_position + Vector2(0.0, -34.0), Color("ff6b5b"), 30)
	_last_event = "bump: cut at %d, %d items dropped" % [index, dropped.size()]


func _scatter_target(from: Vector2, angle: float = NAN) -> Vector2:
	var hi := maxf(tuning.scatter_radius, tuning.scatter_min_radius)
	var dist := _rng.randf_range(tuning.scatter_min_radius, hi)
	if is_nan(angle):
		angle = _rng.randf() * TAU
	var p := from + Vector2.from_angle(angle) * dist
	var m := 24.0
	p = p.clamp(Vector2(m, m), tuning.map_size - Vector2(m, m))
	return _push_out_of_bins(p, tuning.bin_keepout)


## Items never land (or spawn) inside a bin zone; they get nudged to the zone's inner edge.
func _push_out_of_bins(p: Vector2, margin: float) -> Vector2:
	for b in _bins:
		var r := b.rect.grow(margin)
		if r.has_point(p):
			p.x = r.end.x if b.rect.get_center().x < tuning.map_size.x * 0.5 else r.position.x
	return p


func _in_bin(p: Vector2, margin: float) -> bool:
	for b in _bins:
		if b.rect.grow(margin).has_point(p):
			return true
	return false


# --- spawning and pooling ------------------------------------------------------------

func _spawn_one() -> bool:
	if _active_pickups() >= tuning.max_pickups:
		return false
	var pos := _find_free_spot()
	if pos == Vector2.INF:
		return false
	var kind := tuning.pick_kind(_rng)
	_acquire_pickup().activate(kind, pos, _lifetime_for(kind))
	return true


func _find_free_spot() -> Vector2:
	var m := tuning.spawn_margin
	for attempt in 20:
		var pos := Vector2(
			_rng.randf_range(m, tuning.map_size.x - m),
			_rng.randf_range(m, tuning.map_size.y - m))
		if pos.distance_to(_player.global_position) < tuning.spawn_clear_radius:
			continue
		if _in_bin(pos, tuning.bin_keepout):
			continue
		var free := true
		for c in _pickups.get_children():
			var other := c as TrashPickup
			if other.active and other.position.distance_to(pos) < tuning.spawn_min_separation:
				free = false
				break
		if free:
			return pos
	return Vector2.INF


func _lifetime_for(kind: int) -> float:
	return tuning.glitch_lifetime if TrashItems.tier_of(kind) == TrashItems.Tier.GLITCH else 0.0


func _acquire_pickup() -> TrashPickup:
	var p: TrashPickup
	if _pool.is_empty():
		p = TrashPickup.new()
		p.collected.connect(_on_pickup_collected)
		p.expired.connect(_release_pickup)
		_pickups.add_child(p)
	else:
		p = _pool.pop_back()
	return p


func _release_pickup(p: TrashPickup) -> void:
	if not p.active:
		return
	p.deactivate()
	_pool.append(p)


func _on_pickup_collected(p: TrashPickup) -> void:
	if _tail.add_item(p.kind):
		_release_pickup(p)
	elif _full_cooldown <= 0.0:  # tail full: the item stays on the ground
		_full_cooldown = 1.0
		_popups.add(TrashStrings.t(&"full"), _player.global_position + Vector2(0.0, -34.0), Color("ffd24a"), 24)


func _active_pickups() -> int:
	var n := 0
	for c in _pickups.get_children():
		if (c as TrashPickup).active:
			n += 1
	return n


# --- debug actions ---------------------------------------------------------------------

func _on_action(action: StringName) -> void:
	match action:
		&"bank_ewaste":
			_bank_bin(TrashItems.Bin.EWASTE)
		&"bank_general":
			_bank_bin(TrashItems.Bin.GENERAL)
		&"cut":  # same path as a real NPC hit, minus the NPC
			if _tail.count() > 0:
				_on_bumped(_tail.count() >> 1)
		&"freeze":
			_npcs.freeze_all(3.0)
		&"routes":
			_npcs.show_routes = not _npcs.show_routes
		&"mode":
			if tuning.control_mode == TrashTrainTuning.ControlMode.FLOATING_STICK:
				tuning.control_mode = TrashTrainTuning.ControlMode.STEER_TO_POINTER
			else:
				tuning.control_mode = TrashTrainTuning.ControlMode.FLOATING_STICK


func _info_text() -> String:
	var cap := "no cap" if tuning.tail_cap == 0 else str(tuning.tail_cap)
	var mode := "B stick"
	if tuning.control_mode == TrashTrainTuning.ControlMode.STEER_TO_POINTER:
		mode = "A steer"
	var e := _bin_stats(TrashItems.Bin.EWASTE)
	var g := _bin_stats(TrashItems.Bin.GENERAL)
	return "FPS %d   control %s\nspeed %d px/s (%d%%)   tail %d / %s\nE-waste %d = %.1f   General %d = %.1f\nscore %s   banks %d   best %s\nbumps %d   lost %d   invuln %.1f s\nNPC %d (%d frozen)   pickups %d   spawn %.1f s\nlast: %s" % [
		Engine.get_frames_per_second(), mode,
		_player.speed_now, roundi(_tail.speed_multiplier() * 100.0), _tail.count(), cap,
		e[0], e[2], g[0], g[2],
		TrashStrings.num(stats.score), stats.banks, TrashStrings.num(stats.best_bank),
		stats.bumps, stats.items_lost, _npcs.invuln_left,
		_npcs.active_count(), _npcs.frozen_count(), _active_pickups(), _spawn_left,
		_last_event]


# --- placeholder yard --------------------------------------------------------------------

func _draw() -> void:
	var m := tuning.map_size
	draw_rect(Rect2(-3000.0, -3000.0, m.x + 6000.0, m.y + 6000.0), Color("1d3326"))
	draw_rect(Rect2(Vector2.ZERO, m), Color("3d7a4c"))
	var grid := Color(1, 1, 1, 0.07)
	var x := 120.0
	while x < m.x:
		draw_line(Vector2(x, 0.0), Vector2(x, m.y), grid, 2.0)
		x += 120.0
	var y := 120.0
	while y < m.y:
		draw_line(Vector2(0.0, y), Vector2(m.x, y), grid, 2.0)
		y += 120.0
	draw_rect(Rect2(Vector2.ZERO, m), Color("e8e8e8"), false, 4.0)
