class_name ZoneStyle
extends Node
## Look of one stamina zone. The HUD reads these from the child nodes of Root/Zones in hud.tscn, in this order:
## Recover, Cruise, Push, Sprint, Wall. Names, colours, icons and bar patterns are all edited in the Inspector.

@export var label_key: String = ""
@export var color: Color = Color.WHITE
@export var icon: Texture2D
@export var pattern: Texture2D  ## tiled over the filled part of the bar; leave empty for a plain fill
