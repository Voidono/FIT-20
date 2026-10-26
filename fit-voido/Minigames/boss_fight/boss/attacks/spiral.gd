extends BossAttack
## A rotating emitter above the box sprays a spiral of bullets.

@export var arms := 2
@export var angle_step_deg := 17.0
@export var bullet_speed := 115.0
@export var spawn_interval := 0.2
## Where the emitter sits, relative to the box centre.
@export var emitter_offset := Vector2(0, -150)

@onready var spawn_timer: Timer = %SpawnTimer

var _angle := 0.0


func _ready() -> void:
	spawn_timer.timeout.connect(_fire)


func _on_start() -> void:
	_angle = randf() * 360.0
	spawn_timer.start(scaled_interval(spawn_interval))


func _on_stop() -> void:
	spawn_timer.stop()


func _fire() -> void:
	var origin := box.get_center() + emitter_offset
	for i in arms:
		var angle := deg_to_rad(_angle + 360.0 * float(i) / float(arms))
		spawn_bullet(origin, Vector2.from_angle(angle) * bullet_speed)
	_angle += angle_step_deg
