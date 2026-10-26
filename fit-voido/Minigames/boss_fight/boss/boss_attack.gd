class_name BossAttack
extends Node2D
## One enemy attack = one dodge phase. Build each pattern as its own scene:
## a script extending this on the root, plus Timers / Marker2Ds as children.
## Put pattern scenes under a BossPhase node; override exports per instance to make variants.
##
## Write patterns in "Normal difficulty" numbers. The base class applies the difficulty and the
## retry assist automatically: spawn_bullet() scales speed and damage, scaled_interval() scales
## spawn rate, and `telegraph_scale` is for warning times.

signal finished

@export var display_name := "Attack"
@export var duration := 5.0
@export var box_size := Vector2(200, 140)
@export var bullet_scene: PackedScene
@export var bullet_damage := 2
@export_group("Look")
## Error symbols drawn on the bullets (one picked at random). Empty = plain bullet art.
@export var glyphs := PackedStringArray()
@export var glyph_color := Color(1, 1, 1, 1)
@export_group("Culling")
## true: bullets vanish just outside the box. false: they vanish outside the play area
## (but never below the box, so they don't draw over the HUD).
@export var cull_to_box := false
@export var cull_margin := 12.0

var box: BattleBox
var soul: BattleSoul
var bullets_root: Node
var difficulty: BattleDifficulty
## The 640x480 area of the fight, in global coordinates.
var play_area := Rect2()
var speed_scale := 1.0
var rate_scale := 1.0
var damage_scale := 1.0
var telegraph_scale := 1.0

var _running := false
var _run_id := 0


## Resolves when the pattern ends (timer ran out, or stop() was called).
## `assist` (0..1) is extra easing after the player has died a few times.
func run(p_box: BattleBox, p_soul: BattleSoul, p_bullets: Node, p_difficulty: BattleDifficulty,
		p_play_area: Rect2, assist := 0.0) -> void:
	box = p_box
	soul = p_soul
	bullets_root = p_bullets
	difficulty = p_difficulty
	play_area = p_play_area
	speed_scale = difficulty.bullet_speed_multiplier * (1.0 - assist * 0.5)
	rate_scale = maxf(difficulty.spawn_rate_multiplier * (1.0 - assist * 0.5), 0.1)
	damage_scale = difficulty.damage_taken_multiplier * (1.0 - assist)
	telegraph_scale = difficulty.telegraph_multiplier * (1.0 + assist)
	_run_id += 1
	_running = true
	_on_start()
	var length := duration * difficulty.attack_duration_multiplier * (1.0 - assist * 0.3)
	get_tree().create_timer(length).timeout.connect(_on_duration_elapsed.bind(_run_id))
	await finished


func stop() -> void:
	if not _running:
		return
	_running = false
	_on_stop()
	finished.emit()


## `velocity` is in Normal-difficulty units. `delay` > 0 makes the bullet hang (faded) first.
func spawn_bullet(global_pos: Vector2, velocity: Vector2, delay := 0.0) -> BattleBullet:
	var bullet := bullet_scene.instantiate() as BattleBullet
	bullet.damage = maxi(roundi(bullet_damage * damage_scale), 1)
	bullet.velocity = velocity * speed_scale
	bullet.start_delay = delay * telegraph_scale
	bullet.kill_rect = _kill_rect()
	bullets_root.add_child(bullet)
	bullet.global_position = global_pos
	if not glyphs.is_empty():
		bullet.set_glyph(glyphs[randi() % glyphs.size()], glyph_color)
	return bullet


## Spawn interval after applying difficulty (denser on harder settings).
func scaled_interval(base_interval: float) -> float:
	return base_interval / rate_scale


## Override: start timers / spawners.
func _on_start() -> void:
	pass


## Override: stop timers / spawners.
func _on_stop() -> void:
	pass


func _kill_rect() -> Rect2:
	if cull_to_box:
		return box.get_inner_rect().grow(cull_margin)
	var bottom := minf(play_area.end.y, box.global_position.y + box.size.y)
	var area := Rect2(play_area.position, Vector2(play_area.size.x, bottom - play_area.position.y))
	return area.grow(cull_margin)


func _on_duration_elapsed(id: int) -> void:
	if id == _run_id:
		stop()
