class_name TuningSlider
extends HBoxContainer
## One live-tuning row. Add a slider by instancing tuning_slider.tscn under the overlay's Sliders node and filling in
## property (a RunnerTuning variable), label_text, min_value, max_value and step in the Inspector.

@export var property: StringName = &""
@export var label_text: String = ""
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var step: float = 0.01

@onready var _name_label: Label =$NameLabel
@onready var _slider: HSlider = $Slider
@onready var _value_label: Label = $ValueLabel

var _tuning: RunnerTuning
var _syncing: bool = false


func _ready() -> void:
	_name_label.text = label_text
	_slider.min_value = min_value
	_slider.max_value = max_value
	_slider.step = step


func bind(tuning: RunnerTuning) -> void:
	_tuning = tuning
	_syncing = true
	var v: float = float(tuning.get(property))
	_slider.value = v
	_value_label.text = _fmt(v)
	_syncing = false


func _on_value_changed(v: float) -> void:
	if _syncing or _tuning == null:
		return
	_tuning.set(property, v)
	_value_label.text = _fmt(v)


func _fmt(v: float) -> String:
	return ("%.0f" % v) if absf(v) >= 100.0 else ("%.2f" % v)
