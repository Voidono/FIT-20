class_name TrashTrainTuning
extends Resource
## Every tweakable NUMBER for Trash Train, in one place (all starting values are guesses).
## Edit in the inspector (save as a .tres) or live through the debug overlay.
## Map layout, bins, spawn areas and NPC paths are NOT here: they live in the level scene.

enum ControlMode { STEER_TO_POINTER, FLOATING_STICK }

@export_group("Run")
@export_range(30.0, 180.0, 1.0) var run_duration := 80.0  # seconds (the brief: 75-90)
@export_range(10.0, 1000.0, 1.0) var good_run_score := 100.0  # what a GOOD run banks: set it from playtests
@export_range(0.05, 1.0, 0.01) var pass_ratio := 0.33  # 1 star (= pass) at this share of a good run
@export_range(0.05, 1.5, 0.01) var two_star_ratio := 0.66
@export_range(0.05, 2.0, 0.01) var three_star_ratio := 1.0
@export_range(0, 6, 1) var assist_after_fails := 2  # failed attempts before the quiet extra time (0 = never)
@export_range(0.0, 60.0, 1.0) var assist_bonus_seconds := 10.0

@export_group("Camera")
@export_range(0.5, 2.5, 0.05) var camera_zoom := 1.0
@export_range(0.0, 20.0, 0.5) var camera_smoothing := 8.0  # 0 = rigid follow

@export_group("Movement")
@export_range(60.0, 600.0, 5.0) var base_speed := 240.0  # px/s
@export_range(0.2, 1.0, 0.05) var min_speed_ratio := 0.7
@export_range(0.0, 6000.0, 50.0) var acceleration := 1800.0  # 0 = instant

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
@export var spawn_margin := 48.0  # stay this far inside the level bounds
@export var spawn_clear_radius := 120.0  # nothing spawns this close to the runner
@export var spawn_min_separation := 32.0
@export var bin_keepout := 40.0  # nothing spawns or lands this close to a bin zone

@export_group("NPCs")
@export_range(0, 12, 1) var npc_count := 6  # how many NPCs (first N in the level) are active
@export_range(0.0, 240.0, 5.0) var npc_speed := 90.0  # x the route's own speed_scale
@export_range(0.0, 4.0, 0.1) var bump_invulnerability := 1.5  # seconds after a cut

@export_group("Scatter")
@export_range(0.1, 1.0, 0.05) var scatter_time := 0.4  # dropped items can't be picked up until they land
@export_range(10.0, 200.0, 5.0) var scatter_min_radius := 40.0
@export_range(30.0, 250.0, 5.0) var scatter_radius := 110.0

@export_group("Powerups")
@export var powerups_enabled := true  ## master switch: false = no pickups spawn on the map
@export_range(3.0, 30.0, 0.5) var powerup_first_delay := 8.0  ## seconds before the first pickup appears
@export_range(5.0, 60.0, 1.0) var powerup_interval := 15.0  ## seconds between map spawns
@export_range(3.0, 30.0, 0.5) var powerup_lifetime := 12.0  ## how long a pickup sits on the map
@export_range(40.0, 400.0, 5.0) var magnet_radius := 160.0  ## magnet pull range (px)
@export_range(50.0, 600.0, 10.0) var magnet_pull_speed := 280.0  ## px/s items slide toward the runner
@export_range(3.0, 30.0, 0.5) var magnet_seconds := 8.0  ## magnet active duration
@export_range(1.0, 3.0, 0.05) var sneakers_speed := 1.4  ## speed multiplier while sneakers are active (ignores weight)
@export_range(3.0, 30.0, 0.5) var sneakers_seconds := 6.0  ## sneakers active duration
@export_range(3.0, 60.0, 1.0) var shield_seconds := 20.0  ## shield active duration


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


## Score needed for one star (= to pass).
func pass_score() -> float:
	return good_run_score * pass_ratio


func stars_for(score: float) -> int:
	if score >= good_run_score * three_star_ratio - 0.0001:
		return 3
	if score >= good_run_score * two_star_ratio - 0.0001:
		return 2
	if score >= good_run_score * pass_ratio - 0.0001:
		return 1
	return 0
