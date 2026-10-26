extends BossAttack
## Error symbols fall from the top edge of the box.

@export var fall_speed := 150.0
@export var speed_jitter := 30.0
@export var spawn_interval := 0.45

@onready var spawn_timer: Timer = %SpawnTimer


func _ready() -> void:
	spawn_timer.timeout.connect(_spawn)


func _on_start() -> void:
	spawn_timer.start(scaled_interval(spawn_interval))


func _on_stop() -> void:
	spawn_timer.stop()


func _spawn() -> void:
	var area := box.get_inner_rect()
	var x := randf_range(area.position.x + 8.0, area.end.x - 8.0)
	var speed := fall_speed + randf_range(-speed_jitter, speed_jitter)
	spawn_bullet(Vector2(x, area.position.y - 6.0), Vector2.DOWN * speed)
