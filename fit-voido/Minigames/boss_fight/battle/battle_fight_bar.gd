class_name BattleFightBar
extends Node2D
## Undertale attack bar. Z / Enter / a tap stops the cursor; closer to the centre = more damage.
## Green = the skill's good zone, bright strip = perfect zone.

signal _stopped(accuracy: float)

@export var bar_size := Vector2(540, 80)
## Seconds for the cursor to cross the bar at speed multiplier 1.0.
@export var travel_time := 1.1
@export var flash_time := 0.4

@onready var background: AssetSlot = %Background
@onready var sweet_spot: AssetSlot = %SweetSpot
@onready var perfect_zone: AssetSlot = %PerfectZone
@onready var cursor: AssetSlot = %Cursor
@onready var title: Label = %Title

var _forgiveness := 0.5
var _travel := 1.0
var _progress := 0.0
var _running := false
var _start_frame := -1


func _ready() -> void:
	background.placeholder_size = bar_size
	set_process(false)
	hide()


## Resolves with accuracy: 0.0 = missed, 1.0 = dead centre.
func run(skill_name: String, forgiveness: float, speed_multiplier: float,
		perfect_threshold: float) -> float:
	_forgiveness = clampf(forgiveness, 0.05, 1.0)
	_travel = travel_time / maxf(speed_multiplier, 0.1)
	title.text = skill_name
	sweet_spot.placeholder_size = Vector2(bar_size.x * _forgiveness, bar_size.y)
	perfect_zone.placeholder_size = Vector2(
			bar_size.x * _forgiveness * (1.0 - perfect_threshold), bar_size.y)
	cursor.placeholder_size = Vector2(8.0, bar_size.y + 16.0)
	cursor.position.x = -bar_size.x * 0.5
	cursor.modulate.a = 1.0
	_progress = 0.0
	_running = true
	_start_frame = Engine.get_process_frames()
	show()
	set_process(true)
	var accuracy: float = await _stopped
	set_process(false)
	var tween := create_tween().set_loops(3)
	tween.tween_property(cursor, "modulate:a", 0.15, flash_time / 6.0)
	tween.tween_property(cursor, "modulate:a", 1.0, flash_time / 6.0)
	await tween.finished
	hide()
	return accuracy


func _input(event: InputEvent) -> void:
	if _running and Engine.get_process_frames() > _start_frame and BattleInput.is_confirm(event):
		_running = false
		get_viewport().set_input_as_handled()
		_stopped.emit(_accuracy())


func _process(delta: float) -> void:
	if not _running:
		return
	_progress += delta / _travel
	cursor.position.x = lerpf(-bar_size.x * 0.5, bar_size.x * 0.5, minf(_progress, 1.0))
	if _progress >= 1.0:
		_running = false
		_stopped.emit(0.0)


func _accuracy() -> float:
	var distance := absf(cursor.position.x) / (bar_size.x * 0.5)
	return clampf(1.0 - distance / _forgiveness, 0.0, 1.0)
