class_name FrTuning
extends Resource
## Every tunable number for FIT Runner lives in this one resource.
## Edit it in the Inspector, or live from the in-game debug overlay.
## All stamina numbers are starting values to be tuned in playtests, not final.

enum InputMode { HOLD_RELEASE, TIERS }

@export_group("Run")
@export_range(3000.0, 20000.0, 100.0) var track_length: float = 10000.0  ## world pixels
@export_range(60.0, 300.0, 1.0) var max_speed: float = 160.0  ## px/s at pace 1.0
@export_range(1.1, 3.0, 0.05) var cutoff_mult: float = 1.5  ## pass = finish under par x this
@export_range(1.0, 2.0, 0.01) var star2_mult: float = 1.25
@export_range(1.0, 1.5, 0.01) var star3_mult: float = 1.05
@export_range(0.0, 300.0, 0.5) var par_time_override: float = 0.0  ## 0 = use the par bot's time

@export_group("Input")
@export var input_mode: InputMode = InputMode.HOLD_RELEASE

@export_group("Input A - hold / release")
@export_range(0.1, 3.0, 0.05) var rise_rate: float = 0.60  ## effort per second while held
@export_range(0.1, 3.0, 0.05) var fall_rate: float = 0.90  ## effort per second while released
@export_range(0.0, 0.5, 0.01) var rest_floor: float = 0.25  ## releasing decays to a slow jog, not a stop
@export_range(0.0, 1.0, 0.01) var band_lo: float = 0.50
@export_range(0.0, 1.0, 0.01) var band_hi_start: float = 0.74  ## wide cruise band early...
@export_range(0.0, 1.0, 0.01) var band_hi_end: float = 0.68  ## ...narrower later
@export_range(0.05, 1.0, 0.05) var stick_start: float = 0.35  ## rate multiplier inside the band (lower = stickier)
@export_range(0.05, 1.0, 0.05) var stick_end: float = 0.70

@export_group("Input B - hold-time tiers")
@export var tier_values: PackedFloat32Array = PackedFloat32Array([0.30, 0.60, 0.80, 1.00])
@export_range(0.1, 2.0, 0.05) var tier_up_time: float = 0.55  ## hold this long to climb one tier
@export_range(0.1, 2.0, 0.05) var tier_down_time: float = 0.50  ## let go this long to drop one tier

@export_group("Speed inertia")
@export_range(0.2, 6.0, 0.05) var speed_accel: float = 1.6  ## pace per second
@export_range(0.2, 6.0, 0.05) var speed_decel: float = 2.2

@export_group("Stamina")
@export_range(20.0, 300.0, 1.0) var stamina_max: float = 100.0
@export var anchor_paces: PackedFloat32Array = PackedFloat32Array([0.25, 0.60, 0.80, 0.95])  ## pace where each rate below applies; linear in between
@export_range(0.0, 10.0, 0.1) var rate_recover: float = 0.0  ## passive coasting recovery (set to 0: recovery now happens at checkpoints)
@export_range(-5.0, 0.0, 0.05) var rate_cruise: float = -0.6  ## yours
@export_range(-10.0, 0.0, 0.05) var rate_push: float = -2.5  ## yours
@export_range(-16.0, 0.0, 0.1) var rate_sprint: float = -8.0  ## yours was -5; the sim needs about -8 for pacing to matter
@export_range(0.1, 1.0, 0.01) var wall_speed_cap: float = 0.45  ## yours
@export_range(5.0, 80.0, 1.0) var wall_release: float = 35.0  ## yours was 25
@export_range(0.0, 1.0, 0.01) var wall_hold_threshold: float = 0.5  ## while walled, holding at or above this effort stops recovery
@export_range(0.5, 1.0, 0.01) var wall_assist_mult: float = 0.9  ## yours: drain x0.9 after two walls
@export_range(0.5, 1.0, 0.01) var assist_mult: float = 0.9  ## extra assist after repeated failed attempts

@export_group("Checkpoints")
@export var checkpoint_fractions: PackedFloat32Array = PackedFloat32Array([0.25, 0.50, 0.75])
@export_range(1.0, 2.0, 0.05) var boost_speed_mult: float = 1.25  ## speed multiplier on good/perfect QTE
@export_range(0.5, 6.0, 0.1) var boost_duration: float = 2.5  ## boost duration in seconds

@export_group("Water station (Legacy/Disabled)")
@export_range(0.0, 1.0, 0.005) var station_start: float = 0.62
@export_range(0.0, 1.0, 0.005) var station_end: float = 0.67
@export_range(0.0, 60.0, 1.0) var water_amount: float = 0.0  ## disabled in favor of checkpoints
@export_range(0.3, 5.0, 0.1) var water_duration: float = 1.6
@export_range(0.1, 1.0, 0.01) var water_speed_cap: float = 0.40
@export_range(0.0, 1.0, 0.01) var water_release_delay: float = 0.12

@export_group("Final spurt")
@export_range(0.5, 1.0, 0.005) var spurt_start: float = 0.85  ## yours: last ~15%
@export_range(1.0, 1.5, 0.01) var spurt_speed_cap: float = 1.12
@export_range(0.1, 1.0, 0.05) var spurt_drain_mult: float = 0.6  ## yours

@export_group("Terrain")
@export var course_points: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.25, 0.0), Vector2(0.36, 90.0), Vector2(0.43, 90.0), Vector2(0.52, 0.0), Vector2(1.0, 0.0)])  ## x = fraction of the track, y = height in px
@export_range(0.02, 0.5, 0.01) var slope_ref: float = 0.12  ## slope that counts as "full" hill
@export_range(0.0, 4.0, 0.1) var uphill_drain_extra: float = 1.5
@export_range(0.0, 0.8, 0.01) var uphill_speed_penalty: float = 0.35
@export_range(0.0, 0.8, 0.01) var downhill_speed_bonus: float = 0.30

@export_group("Par bot - hold/release plan")
@export_range(0.0, 1.0, 0.001) var bot_e_base: float = 0.508
@export_range(0.0, 3.0, 0.01) var bot_k: float = 0.696
@export_range(0.0, 80.0, 0.1) var bot_reserve: float = 12.1  ## stamina the plan wants left when the spurt starts
@export_range(0.0, 0.5, 0.001) var bot_ff: float = 0.146  ## eases off uphill, pushes downhill
@export_range(0.0, 101.0, 1.0) var bot_drink_below: float = 90.0
@export_range(0.0, 1.0, 0.001) var bot_e_min: float = 0.292
@export_range(0.0, 0.1, 0.001) var bot_spurt_lead: float = 0.0

@export_group("Par bot - tier plan")
@export_range(0.0, 80.0, 0.1) var bot_b_reserve: float = 44.2
@export_range(0.0, 0.1, 0.001) var bot_b_spurt_lead: float = 0.012
@export_range(0.5, 20.0, 0.5) var bot_b_hysteresis: float = 4.0

@export_group("Feel")
@export var haptics: bool = false  ## vibrate on a wall (phones only, not every browser)
@export var show_debug_button: bool = true  ## turn off for the release build


## The two numbers that differ from your original tier list. Original: sprint -5, wall exit 25.
func apply_original_numbers() -> void:
	rate_sprint = -5.0
	wall_release = 25.0


## Calibrated in the headless model so that pacing is worth about 25% over mashing.
func apply_calibrated_numbers() -> void:
	rate_sprint = -8.0
	wall_release = 35.0


## All exported values as "name=value" lines (used for the par cache key and the run log).
func to_text() -> String:
	var lines: PackedStringArray = []
	for info: Dictionary in get_property_list():
		var usage: int = info["usage"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_STORAGE) != 0:
			var prop_name: String = info["name"]
			lines.append("%s=%s" % [prop_name, str(get(prop_name))])
	return "\n".join(lines)
