class_name TrashTrainTuning
extends Resource
## Every tweakable number for Trash Train, in one place. All starting values are guesses.
## Edit in the inspector (save as a .tres) or live through the debug overlay.
## Distances are world pixels at the 960x540 reference screen.

enum ControlMode { STEER_TO_POINTER, FLOATING_STICK }

@export_group("Map and camera")
@export var map_size := Vector2(1440.0, 810.0)  # 1.5 x the reference screen
@export_range(0.5, 2.5, 0.05) var camera_zoom := 1.0
@export_range(0.0, 20.0, 0.5) var camera_smoothing := 8.0  # 0 = rigid follow

@export_group("Movement")
@export_range(60.0, 600.0, 5.0) var base_speed := 240.0  # 1440 px in 6 s
@export_range(0.2, 1.0, 0.05) var min_speed_ratio := 0.7
@export_range(0.0, 6000.0, 50.0) var acceleration := 1800.0  # 0 = instant
@export var player_radius := 14.0

@export_group("Pointer")
@export var control_mode: ControlMode = ControlMode.FLOATING_STICK
@export_range(30.0, 160.0, 5.0) var stick_radius := 70.0  # screen px; stick re-anchors past this
@export_range(0.0, 50.0, 1.0) var deadzone := 10.0  # screen px
@export_range(1.0, 120.0, 1.0) var ramp := 24.0  # px beyond deadzone to reach full speed

@export_group("Tail")
@export_range(0, 40, 1) var tail_cap := 12  # 0 = unlimited
@export_range(10.0, 60.0, 1.0) var tail_spacing := 24.0
@export_range(50.0, 2000.0, 10.0) var tail_gap_speed := 600.0  # px/s items slide forward to close gaps
@export_range(0.0, 0.4, 0.01) var wobble_amount := 0.10
@export_range(0.0, 20.0, 0.5) var wobble_speed := 9.0

@export_group("Items")
@export var normal_points := 1.0
@export var heavy_points := 5.0
@export var glitch_points := 3.0
@export_range(0.0, 0.2, 0.005) var normal_slow := 0.03
@export_range(0.0, 0.3, 0.005) var heavy_slow := 0.06
@export_range(0.0, 0.2, 0.005) var glitch_slow := 0.03
@export_range(0.0, 0.5, 0.01) var multiplier_per_item := 0.1
@export_range(1.0, 15.0, 0.5) var glitch_lifetime := 5.0

@export_group("Spawning")
@export_range(0, 60, 1) var start_items := 25
@export_range(0.5, 10.0, 0.25) var spawn_interval := 3.0
@export_range(10, 100, 1) var max_pickups := 60
@export var weight_normal := 0.75
@export var weight_heavy := 0.12
@export var weight_glitch := 0.13
@export var spawn_margin := 48.0
@export var spawn_clear_radius := 120.0  # nothing spawns this close to the runner
@export var spawn_min_separation := 32.0

@export_group("Bins")
@export var bin_size := Vector2(150.0, 280.0)  # one zone at each map end, centred vertically
@export var bin_keepout := 40.0  # nothing spawns or scatters this close to a bin zone

@export_group("NPCs")
@export_range(0, 8, 1) var npc_count := 5  # how many of the routes in npcs.gd are active
@export_range(0.0, 240.0, 5.0) var npc_speed := 90.0  # x the route's own speed factor
@export_range(8.0, 30.0, 1.0) var npc_radius := 16.0
@export_range(0.0, 10.0, 0.5) var npc_hit_forgiveness := 3.0  # px shaved off every hit radius
@export_range(0.0, 4.0, 0.1) var bump_invulnerability := 1.5  # seconds after a cut

@export_group("Scatter")
@export_range(0.1, 1.0, 0.05) var scatter_time := 0.4  # dropped items can't be picked up until they land
@export_range(10.0, 200.0, 5.0) var scatter_min_radius := 40.0
@export_range(30.0, 250.0, 5.0) var scatter_radius := 110.0


func points_for(tier: int) -> float:
	match tier:
		TrashItems.Tier.HEAVY:
			return heavy_points
		TrashItems.Tier.GLITCH:
			return glitch_points
	return normal_points


func slow_for(tier: int) -> float:
	match tier:
		TrashItems.Tier.HEAVY:
			return heavy_slow
		TrashItems.Tier.GLITCH:
			return glitch_slow
	return normal_slow


## sum of points x (1 + multiplier_per_item per item banked at once)
func payout(points_sum: float, item_count: int) -> float:
	return points_sum * (1.0 + multiplier_per_item * item_count)


func pick_kind(rng: RandomNumberGenerator) -> int:
	var total := weight_normal + weight_heavy + weight_glitch
	if total <= 0.0:
		return TrashItems.Kind.CUP
	var r := rng.randf() * total
	var tier: int = TrashItems.Tier.NORMAL
	if r >= weight_normal + weight_heavy:
		tier = TrashItems.Tier.GLITCH
	elif r >= weight_normal:
		tier = TrashItems.Tier.HEAVY
	var options := TrashItems.kinds_in_tier(tier)
	return options[rng.randi() % options.size()]
