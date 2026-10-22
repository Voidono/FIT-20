extends BossAttack
## A ring of bullets appears around the soul and hangs (a "breakpoint"), then they all
## launch at the spot the soul was standing on.

@export var ring_count := 8
@export var ring_radius := 70.0
@export var hold_time := 0.9
@export var bullet_speed := 160.0
@export var wave_interval := 2.0

@onready var spawn_timer: Timer = %SpawnTimer


func _ready() -> void:
	spawn_timer.timeout.connect(_wave)


func _on_start() -> void:
	spawn_timer.start(scaled_interval(wave_interval))
	_wave()


func _on_stop() -> void:
	spawn_timer.stop()


func _wave() -> void:
	var center := soul.global_position
	var limit := box.get_inner_rect().grow(8.0)
	var offset := randf() * TAU
	for i in ring_count:
		var angle := offset + TAU * float(i) / float(ring_count)
		var spawn_pos := (center + Vector2.from_angle(angle) * ring_radius).clamp(limit.position, limit.end)
		var direction := spawn_pos.direction_to(center)
		spawn_bullet(spawn_pos, direction * bullet_speed, hold_time)
