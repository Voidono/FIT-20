extends BossAttack
## Fires from each Marker2D under SpawnPoints (in turn) straight at the soul.
## Markers sit relative to the box centre: move / add / delete them in the editor.

@export var bullet_speed := 130.0
@export var spawn_interval := 0.8

@onready var spawn_points: Node2D = %SpawnPoints
@onready var spawn_timer: Timer = %SpawnTimer

var _next := 0


func _ready() -> void:
	spawn_timer.timeout.connect(_fire)


func _on_start() -> void:
	global_position = box.get_center()
	_next = 0
	spawn_timer.start(scaled_interval(spawn_interval))


func _on_stop() -> void:
	spawn_timer.stop()


func _fire() -> void:
	var markers := spawn_points.get_children()
	if markers.is_empty():
		return
	var marker := markers[_next % markers.size()] as Node2D
	_next += 1
	var direction := marker.global_position.direction_to(soul.global_position)
	spawn_bullet(marker.global_position, direction * bullet_speed)
