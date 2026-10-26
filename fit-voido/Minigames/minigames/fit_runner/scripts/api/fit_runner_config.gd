class_name FitRunnerConfig
extends Resource
## What the host game hands to FitRunner. Every field is optional; the defaults are the tuned baseline.
## Make one in code (FitRunnerConfig.new()) or save it as a .tres per level / per difficulty.

@export var tuning: FrTuning  ## stamina and speed numbers; null = built-in defaults
@export var qte: FrQteSettings  ## recovery QTE; null = the "normal" preset. Presets live in resources/qte_*.tres
@export_range(1, 99, 1) var attempt: int = 1  ## which try this is (shown in the log, used for QTE randomness)
@export_range(0, 3, 1) var assist_level: int = 0  ## 0 = none; above 0 cuts stamina drain 10% (use after repeated fails)
@export var debug_enabled: bool = false
@export var push_action: StringName = &"fr_push"
@export var require_landscape_window: bool = true
@export var pause_keys_enabled: bool = true
@export var autostart: bool = true
