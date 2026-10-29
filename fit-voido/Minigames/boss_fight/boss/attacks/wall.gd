extends BossAttack
## Walls of brackets slide across the box with a gap to slip through.

@export var wall_speed := 100.0
@export var spacing := 18.0
@export var gap_size := 60.0
@export var spawn_interval := 1.6
@export var from_right := true

@onready var spawn_timer: Timer = %SpawnTimer


func _ready() -> void:
	spawn_timer.timeout.connect(_spawn)


func _on_start() -> void:
	spawn_timer.start(scaled_interval(spawn_interval))
	_spawn()


func _on_stop() -> void:
	spawn_timer.stop()


func _spawn() -> void:
	var area := box.get_inner_rect()
	var x := area.end.x + 8.0 if from_right else area.position.x - 8.0
	var direction := Vector2.LEFT if from_right else Vector2.RIGHT
	var gap_center := randf_range(area.position.y + gap_size * 0.5, area.end.y - gap_size * 0.5)
	var y := area.position.y + spacing * 0.5
	while y < area.end.y:
		if absf(y - gap_center) > gap_size * 0.5:
			spawn_bullet(Vector2(x, y), direction * wall_speed)
		y += spacing
