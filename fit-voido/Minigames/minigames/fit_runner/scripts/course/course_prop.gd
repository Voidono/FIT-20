class_name FrCourseProp
extends Node2D
## Something that stands on the track. Instance a prop scene under Course/Props, then set where it stands in the
## Inspector (track_fraction 0..1). Course snaps it to the ground. A %Label child shows label_key (translated),
## a %Banner child is tinted with banner_color. Make your own props by instancing this script on any Node2D.

@export_range(0.0, 1.0, 0.001) var track_fraction: float = 0.0
@export var track_pixels: float = -1.0  ## absolute x in px; overrides track_fraction when >= 0 (used by the distance posts)
@export_range(0.0, 1.0, 0.001) var span_fraction: float = 0.0  ## how wide it is, for things that spread out (water station)
@export var tilt_with_slope: bool = false
@export var label_key: String = ""
@export var banner_color: Color = Color.WHITE


func _ready() -> void:
	var label: Label = FrLookup.optional(self, "Label") as Label
	if label != null and not label_key.is_empty():
		label.text = label_key  # a translation key, or plain text such as "100 m"
	var banner: Sprite2D = FrLookup.optional(self, "Banner") as Sprite2D
	if banner != null:
		banner.modulate = banner_color


func place(tuning: FrTuning, profile: FrCourseProfile, ground_y: float) -> void:
	var x: float = track_pixels if track_pixels >= 0.0 else track_fraction * tuning.track_length
	position = Vector2(x, ground_y - profile.height_at(x))
	rotation = atan(-profile.slope_at(x)) if tilt_with_slope else 0.0
	_on_placed(tuning, profile, ground_y)


## Override in a subclass to arrange children after the prop has been put on the track.
func _on_placed(_tuning: FrTuning, _profile: FrCourseProfile, _ground_y: float) -> void:
	pass
