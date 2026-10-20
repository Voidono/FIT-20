extends BossAttack
## Waves of beams. Each beam blinks a thin warning line first, then fires.
## bullet_scene must be laser.tscn.

@export var lasers_per_wave := 2
@export var wave_interval := 1.7
@export var warn_time := 0.9
@export var active_time := 0.35
@export_range(0.0, 1.0) var vertical_chance := 0.4

@onready var spawn_timer: Timer = %SpawnTimer


func _ready() -> void:
	spawn_timer.timeout.connect(_wave)


func _on_start() -> void:
	spawn_timer.start(scaled_interval(wave_interval))
	_wave()


func _on_stop() -> void:
	spawn_timer.stop()


func _wave() -> void:
	var area := box.get_inner_rect()
	for i in lasers_per_wave:
		var vertical := randf() < vertical_chance
		var beam_pos := area.get_center()
		if vertical:
			beam_pos.x = randf_range(area.position.x + 10.0, area.end.x - 10.0)
		else:
			beam_pos.y = randf_range(area.position.y + 10.0, area.end.y - 10.0)
		var laser := spawn_bullet(beam_pos, Vector2.ZERO) as BattleLaser
		var beam_length := (area.size.y if vertical else area.size.x) + 60.0
		laser.configure(beam_length, not vertical, warn_time * telegraph_scale, active_time)
