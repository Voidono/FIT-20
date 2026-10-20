class_name QteSettings
extends Resource
## Everything about the recovery quick-time event, in one resource. Edit the presets in resources/ (qte_easy,
## qte_normal, qte_hard), make your own with New Resource > QteSettings, or tweak live from the debug overlay.
## The bar is a cursor that sweeps left to right once; tap while it is on the sweet spot.

@export var enabled: bool = true

@export_group("When it appears")
@export_range(0.0, 5.0, 0.05) var rest_time_before_event: float = 2.0  ## seconds of resting before an event shows up
@export_range(0.0, 5.0, 0.05) var cooldown: float = 0.8  ## minimum seconds between two events
@export_range(0.0, 1.0, 0.01) var only_below_stamina: float = 0.9  ## no events while stamina is above this share
@export var during_wall: bool = true  ## also while you are stuck at the wall
@export_range(0.0, 1.0, 0.005) var track_from: float = 0.0  ## events only happen between these two points of the course
@export_range(0.0, 1.0, 0.005) var track_to: float = 0.85
@export_range(0.0, 1.0, 0.01) var rest_pace_below: float = 0.5  ## "resting" means pace under this

@export_group("Difficulty")
@export_range(0.3, 4.0, 0.05) var duration: float = 1.1  ## seconds for the cursor to cross the bar (shorter = harder)
@export_range(0.02, 0.5, 0.01) var perfect_width: float = 0.10  ## share of the bar (smaller = harder)
@export_range(0.05, 0.8, 0.01) var good_width: float = 0.26

@export_group("Position of the sweet spot")
@export_range(0.0, 1.0, 0.01) var target_center: float = 0.65  ## 0 = left end of the bar, 1 = right end
@export_range(0.0, 0.5, 0.01) var target_jitter: float = 0.10  ## random shift per event, plus or minus

@export_group("Reward")
@export_range(0.0, 40.0, 0.5) var perfect_bonus: float = 5.0  ## stamina
@export_range(0.0, 40.0, 0.5) var good_bonus: float = 2.5
@export_range(0.0, 20.0, 0.5) var miss_penalty: float = 0.0
@export_range(0.0, 10.0, 0.5) var streak_step: float = 0.5  ## extra stamina per perfect in a row
@export_range(0, 10, 1) var streak_cap: int = 4

@export_group("Input")
@export_range(0.05, 0.6, 0.01) var tap_max_time: float = 0.22  ## a press shorter than this is a tap, longer turns into running
@export_range(0.0, 2.0, 0.05) var feedback_time: float = 0.6  ## how long PERFECT / GOOD / MISS stays on screen


## All values as "name=value" lines (used in the run log).
func to_text() -> String:
	var lines: PackedStringArray = []
	for info: Dictionary in get_property_list():
		var usage: int = info["usage"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_STORAGE) != 0:
			var prop_name: String = info["name"]
			lines.append("%s=%s" % [prop_name, str(get(prop_name))])
	return "\n".join(lines)
