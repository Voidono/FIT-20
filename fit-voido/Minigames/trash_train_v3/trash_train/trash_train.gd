class_name TrashTrain
extends Node2D
## Trash Train controller. It knows nothing about any particular MAP: it instances `level_scene`
## (a scene whose root uses level.gd) and wires the game to whatever that level contains.
##
## A run goes  LOADING -> READY ("tap to start") -> RUNNING (the clock) -> ENDED (result panel).
## Retry rebuilds the whole World from the level scene, so every attempt starts fresh.
## READY and ENDED freeze the World by switching its process_mode off: NPCs, timers, glitch
## countdowns and physics all stop, without touching your game's own pause.
##
## TrashTrain (Node2D)                 this script
## |- World (Node2D)                   rebuilt for every attempt
## |   |- <the level scene>            Ground art, Bounds, PlayerStart, Obstacles, Bins, SpawnZones, Routes
## |   |- Pickups, TrashSpawner (+Timer), <player_scene> (+Camera2D), TrashTail, TrashNpcs, TrashPopups
## '- UI (CanvasLayer, layer 10)       TrashPointer, TrashHud, TrashResultPanel, TrashDebugOverlay
##
## For your quest system: instance trash_train.tscn, set level_scene (and failed_attempts from your
## save data), then listen to run_finished(result) / closed(result). See README.md.

signal run_finished(result: TrashRunResult)  ## every attempt, the moment time is up
signal closed(result: TrashRunResult)  ## the player pressed Continue after a pass

enum State { LOADING, READY, RUNNING, ENDED }

const DEFAULT_LEVEL := "res://trash_train/levels/level_yard.tscn"
const DEFAULT_PLAYER := "res://trash_train/player.tscn"
const DEFAULT_NPC := "res://trash_train/npc.tscn"
const DEFAULT_CATALOG := "res://trash_train/items/catalog.tres"
const LOG_PATH := "user://trash_train_runs.csv"
const GOLDEN_ANGLE := 2.399963  # radians; consecutive drops fan out instead of piling up

@export var level_scene: PackedScene  ## the MAP. Empty = the sample yard
@export var player_scene: PackedScene  ## the runner. Empty = player.tscn
@export var npc_scene: PackedScene  ## default NPC for routes that don't set their own
@export var catalog: TrashItemCatalog  ## fallback item list if the level has none
@export var tuning: TrashTrainTuning  ## leave empty to use the defaults in tuning.gd
@export_group("Run")
@export var auto_start := false  ## true = skip "tap to start": the clock starts as soon as the map is ready
@export var failed_attempts := 0  ## feed from your save data; decides when the quiet extra time kicks in
@export var rng_seed := 0  ## 0 = random layout; any other number = the same starting layout (playtests)
@export var log_runs := true  ## append every result to user://trash_train_runs.csv

var stats := TrashRunStats.new()
var state := State.LOADING
var time_left := 0.0
var duration := 0.0  # the clock this attempt started with
var attempt := 0  # attempts started this session
var last_result: TrashRunResult
var level: TrashLevel

var _world: Node2D
var _player: TrashPlayer
var _tail: TrashTail
var _pointer: TrashPointer
var _overlay: TrashDebugOverlay
var _hud: TrashHud
var _result_panel: TrashResultPanel
var _npcs: TrashNpcs
var _popups: TrashPopups
var _spawner: TrashSpawner
var _camera: Camera2D
var _pickups: Node2D
var _bins: Array[TrashBin] = []
var _rng := RandomNumberGenerator.new()
var _info_left := 0.0
var _full_cooldown := 0.0
var _assist_applied := false
var _last_event := "-"


func _ready() -> void:
	if tuning == null:
		tuning = TrashTrainTuning.new()
	if level_scene == null:
		level_scene = load(DEFAULT_LEVEL)
	if player_scene == null:
		player_scene = load(DEFAULT_PLAYER)
	if npc_scene == null:
		npc_scene = load(DEFAULT_NPC)
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	_build_ui()
	var ok: bool = await _build_world()
	if not ok:
		set_process(false)
		set_physics_process(false)
		return
	_finish_loading()


# --- the run ----------------------------------------------------------------------

## Start the clock (called by the first press on the "tap to start" screen, or by you).
func start_run() -> void:
	if state != State.READY and state != State.LOADING:
		return
	attempt += 1
	_assist_applied = _assist_due()
	duration = _next_duration()
	time_left = duration
	state = State.RUNNING
	_world.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.show_running()
	_hud.set_time(time_left)


## Stop the clock now and show the result (also called when time runs out).
func end_run() -> void:
	if state != State.RUNNING:
		return
	state = State.ENDED
	_world.process_mode = Node.PROCESS_MODE_DISABLED
	var r := TrashRunResult.new()
	r.banked_score = stats.score
	r.stars = tuning.stars_for(stats.score)
	r.passed = r.stars >= 1
	r.bumps_taken = stats.bumps
	r.items_banked = stats.items_banked
	r.items_lost = stats.items_lost
	r.unbanked_points = _tail.carried_points()
	r.duration = duration
	r.time_used = duration - time_left
	r.assist_applied = _assist_applied
	r.attempt = attempt
	if not r.passed:
		failed_attempts += 1
	r.failed_attempts = failed_attempts
	last_result = r
	_last_event = "RESULT: %s, %d stars, score %.1f" % ["PASS" if r.passed else "fail", r.stars, r.banked_score]
	_log_result(r)
	_result_panel.show_result(r, ceilf(tuning.pass_score() - 0.0001))
	run_finished.emit(r)


## Throw the world away and build a fresh one from the level scene. Back to "tap to start".
func restart() -> void:
	if state == State.LOADING:
		return
	_result_panel.hide_panel()
	_pointer.follow_target = null
	if _world != null:
		_world.free()
		_world = null
	stats.reset()
	_hud.set_score(0.0)
	var ok: bool = await _build_world()
	if ok:
		_finish_loading()


func _assist_due() -> bool:
	return tuning.assist_after_fails > 0 and failed_attempts >= tuning.assist_after_fails


func _next_duration() -> float:
	return tuning.run_duration + (tuning.assist_bonus_seconds if _assist_due() else 0.0)


func _finish_loading() -> void:
	if auto_start:
		start_run()
	else:
		_enter_ready()


func _enter_ready() -> void:
	state = State.READY
	duration = _next_duration()
	time_left = duration
	_world.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.set_time(time_left)
	_hud.show_ready(ceilf(tuning.pass_score() - 0.0001))


func _on_pointer_pressed() -> void:
	if state == State.READY:
		start_run()


func _on_continue() -> void:
	closed.emit(last_result)


func _log_result(r: TrashRunResult) -> void:
	if not log_runs:
		return
	var fresh := not FileAccess.file_exists(LOG_PATH)
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE if fresh else FileAccess.READ_WRITE)
	if f == null:
		return
	if fresh:
		f.store_line("time,level,attempt,passed,stars,score,bumps,items_banked,items_lost,unbanked,time_used,duration,assist,control,tail_cap,npc_count,npc_speed,seed")
	else:
		f.seek_end()
	f.store_line("%s,%s,%d,%s,%d,%.2f,%d,%d,%d,%.2f,%.1f,%.1f,%s,%d,%d,%d,%.0f,%d" % [
		Time.get_datetime_string_from_system(), level.name, r.attempt, r.passed, r.stars, r.banked_score,
		r.bumps_taken, r.items_banked, r.items_lost, r.unbanked_points, r.time_used, r.duration,
		r.assist_applied, tuning.control_mode, tuning.tail_cap, tuning.npc_count, tuning.npc_speed, rng_seed])
	f.close()


# --- building ---------------------------------------------------------------------

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 10
	add_child(ui)
	_pointer = TrashPointer.new()
	_pointer.tuning = tuning
	_pointer.pressed.connect(_on_pointer_pressed)
	ui.add_child(_pointer)
	_hud = TrashHud.new()
	ui.add_child(_hud)
	_result_panel = TrashResultPanel.new()
	_result_panel.retry_pressed.connect(restart)
	_result_panel.continue_pressed.connect(_on_continue)
	ui.add_child(_result_panel)
	_overlay = TrashDebugOverlay.new()
	ui.add_child(_overlay)
	_overlay.setup(tuning)
	_overlay.action_requested.connect(_on_action)
	_pointer.blockers.append(_overlay.panel)
	_pointer.blockers.append(_overlay.toggle_button)
	_pointer.blockers.append(_result_panel)


func _build_world() -> bool:
	state = State.LOADING
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	move_child(_world, 0)

	level = level_scene.instantiate() as TrashLevel
	if level == null:
		push_error("TrashTrain: the root node of level_scene must use res://trash_train/level.gd (TrashLevel).")
		return false
	_world.add_child(level)
	var items := level.catalog if level.catalog != null else catalog
	if items == null:
		items = load(DEFAULT_CATALOG)
	var bounds := level.get_bounds()

	_pickups = Node2D.new()
	_pickups.name = "Pickups"
	_world.add_child(_pickups)

	_tail = TrashTail.new()
	_player = player_scene.instantiate() as TrashPlayer
	_player.setup(tuning, _pointer, _tail)
	_world.add_child(_player)
	_player.global_position = level.get_player_start()
	_tail.setup(tuning, _player)
	_world.add_child(_tail)

	_camera = Camera2D.new()
	_camera.limit_left = int(bounds.position.x)
	_camera.limit_top = int(bounds.position.y)
	_camera.limit_right = int(bounds.end.x)
	_camera.limit_bottom = int(bounds.end.y)
	_player.add_child(_camera)
	_camera.make_current()

	for route in level.get_routes():
		route.setup(tuning, npc_scene)
	_npcs = TrashNpcs.new()
	_npcs.setup(tuning, _tail)
	_world.add_child(_npcs)
	_npcs.refresh()
	_npcs.bumped.connect(_on_bumped)

	_spawner = TrashSpawner.new()
	_spawner.setup(tuning, items, level.get_spawn_zones(), _pickups, _player, bounds, _rng)
	_spawner.collected.connect(_on_pickup_collected)
	_world.add_child(_spawner)

	_bins = level.get_bins()
	_popups = TrashPopups.new()
	_world.add_child(_popups)
	_pointer.follow_target = _player

	# the walls only exist in the physics space after the first physics step
	await get_tree().physics_frame
	_spawner.start()
	_camera.reset_smoothing()
	return true


# --- per frame ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state != State.RUNNING:
		return
	# Banking is automatic: being inside a bin zone with items it accepts banks them.
	# (Done before the clock check, so a bank on the very last frame still counts.)
	for b in _bins:
		if b.player_inside and _tail.count_accepted(b.accepts) > 0:
			_bank_bin(b)
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		end_run()


func _process(delta: float) -> void:
	if _world == null or _camera == null:
		return
	var zoom := Vector2.ONE * tuning.camera_zoom
	if not _camera.zoom.is_equal_approx(zoom):
		_camera.zoom = zoom
	_camera.position_smoothing_enabled = tuning.camera_smoothing > 0.0
	_camera.position_smoothing_speed = maxf(tuning.camera_smoothing, 0.1)
	_full_cooldown = maxf(0.0, _full_cooldown - delta)

	# blink the runner and the tail while the post-bump immunity lasts
	var alpha := 1.0
	if _npcs.invuln_left > 0.0:
		alpha = 0.35 + 0.65 * absf(sin(_npcs.invuln_left * 18.0))
	_player.modulate.a = alpha
	_tail.modulate.a = alpha

	_hud.set_time(time_left)
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
			_on_action(&"bank_0")
		KEY_2:
			_on_action(&"bank_1")
		KEY_3:
			_on_action(&"cut")
		KEY_4:
			_on_action(&"freeze")
		KEY_R:
			_on_action(&"routes")
		KEY_C:
			_on_action(&"mode")
		KEY_E:
			_on_action(&"end")
		KEY_N:
			_on_action(&"restart")


# --- banking ---------------------------------------------------------------------

## [item count, points, payout] if this bin were entered right now.
func _bin_stats(b: TrashBin) -> Array:
	var count := 0
	var pts := 0.0
	for i in _tail.count():
		var d := _tail.def_at(i)
		if d.goes_in(b.accepts):
			count += 1
			pts += tuning.points_for(d.tier)
	return [count, pts, tuning.payout(pts, count)]


## Pays sum(points) x (1 + multiplier_per_item x items banked in THIS visit) for what the bin accepts.
func _bank_bin(b: TrashBin) -> void:
	var st := _bin_stats(b)
	var taken := _tail.take_accepted(b.accepts)
	if taken.is_empty():
		return
	var pay: float = st[2]
	stats.score += pay
	stats.items_banked += taken.size()
	stats.banks += 1
	stats.best_bank = maxf(stats.best_bank, pay)
	_hud.set_score(stats.score)
	_popups.add("+" + TrashStrings.num(pay), _player.global_position + Vector2(0.0, -40.0), b.color.lightened(0.5), 36)
	_last_event = "%s: %d items, %.1f pts x%.2f = %.1f" % [
		b.name, taken.size(), st[1], 1.0 + tuning.multiplier_per_item * taken.size(), pay]


# --- bumps -------------------------------------------------------------------------

func _on_bumped(index: int) -> void:
	var dropped := _tail.cut_at(index)
	if dropped.is_empty():
		return
	stats.bumps += 1
	stats.items_lost += dropped.size()
	var base_angle := _rng.randf() * TAU
	for j in dropped.size():
		var def: TrashItemDef = dropped[j]["def"]
		var from: Vector2 = dropped[j]["pos"]
		_spawner.drop(def, from, _spawner.scatter_target(from, def, base_angle + j * GOLDEN_ANGLE))
	_popups.add(TrashStrings.t(&"bump"), _player.global_position + Vector2(0.0, -34.0), Color("ff6b5b"), 30)
	_last_event = "bump: cut at %d, %d items dropped" % [index, dropped.size()]


# --- pickups ---------------------------------------------------------------------------

func _on_pickup_collected(p: TrashPickup) -> void:
	_collect.call_deferred(p)  # we are inside a physics callback: change nodes after it


func _collect(p: TrashPickup) -> void:
	if not is_instance_valid(p) or not p.active or p.is_flying():
		return
	if _tail.add_item(p.def):
		_spawner.release(p)
	elif _full_cooldown <= 0.0:  # tail full: the item stays on the ground
		_full_cooldown = 1.0
		_popups.add(TrashStrings.t(&"full"), _player.global_position + Vector2(0.0, -34.0), Color("ffd24a"), 24)


# --- debug actions ---------------------------------------------------------------------

func _on_action(action: StringName) -> void:
	var text := String(action)
	if text.begins_with("bank_"):
		var i := int(text.substr(5))
		if i >= 0 and i < _bins.size():
			_bank_bin(_bins[i])
		return
	match action:
		&"cut":  # same path as a real NPC hit, minus the NPC
			if _tail.count() > 0:
				_on_bumped(_tail.count() >> 1)
		&"freeze":
			_npcs.freeze_all(3.0)
		&"routes":
			for r in level.get_routes():
				r.show_route = not r.show_route
		&"mode":
			if tuning.control_mode == TrashTrainTuning.ControlMode.FLOATING_STICK:
				tuning.control_mode = TrashTrainTuning.ControlMode.STEER_TO_POINTER
			else:
				tuning.control_mode = TrashTrainTuning.ControlMode.FLOATING_STICK
		&"end":
			end_run()
		&"restart":
			restart()


func _info_text() -> String:
	var cap := "no cap" if tuning.tail_cap == 0 else str(tuning.tail_cap)
	var mode := "B stick"
	if tuning.control_mode == TrashTrainTuning.ControlMode.STEER_TO_POINTER:
		mode = "A steer"
	var bin_parts: Array[String] = []
	for b in _bins:
		var st := _bin_stats(b)
		bin_parts.append("%s %d = %.1f" % [b.name, st[0], st[2]])
	return "FPS %d   control %s   %s %.1f / %.0f s\nspeed %d px/s (%d%%)   tail %d / %s\n%s\nscore %s   banks %d   best %s\nbumps %d   lost %d   invuln %.1f s\nNPC %d (%d frozen)   pickups %d   attempt %d, failed %d\nlast: %s" % [
		Engine.get_frames_per_second(), mode, State.keys()[state], time_left, duration,
		_player.speed_now, roundi(_tail.speed_multiplier() * 100.0), _tail.count(), cap,
		"   ".join(bin_parts),
		TrashStrings.num(stats.score), stats.banks, TrashStrings.num(stats.best_bank),
		stats.bumps, stats.items_lost, _npcs.invuln_left,
		_npcs.active_count(), _npcs.frozen_count(), _spawner.active_count(), attempt, failed_attempts,
		_last_event]
