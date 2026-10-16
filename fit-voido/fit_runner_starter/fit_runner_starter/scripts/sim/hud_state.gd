class_name HudState
extends RefCounted
## Snapshot the runner hands to the HUD and the debug overlay every frame.
## They read this and never touch the runner itself.

var phase: int = RunState.Phase.READY
var model: RunnerModel
var tuning: RunnerTuning
var countdown_left: float = 0.0
var has_delta: bool = false
var delta_vs_par: float = 0.0  ## seconds; positive = ahead of the par runner
var ghost_progress: float = 0.0
var effort: float = 0.0
var outlook: int = 0  ## 0 = enough to finish, 1 = tight, 2 = wall ahead
var outlook_stamina: float = 0.0
var par_time: float = 0.0
var cutoff_time: float = 0.0
var attempt: int = 1
