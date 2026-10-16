class_name ResultPanel
extends PanelContainer
## Results screen. Stars, Time Stone and buttons are nodes in result_panel.tscn; swap star_full / star_empty
## in the Inspector for your own art. The text comes from the translation keys.

signal retry_pressed
signal quit_pressed

@export var star_full: Texture2D
@export var star_empty: Texture2D

@onready var _title: Label = %TitleLabel
@onready var _star_row: Control = %Stars
@onready var _time: Label = %TimeLabel
@onready var _par: Label = %ParLabel
@onready var _walls: Label = %WallsLabel
@onready var _stone_row: Control = %StoneRow
@onready var _hint: Label = %HintLabel
@onready var _continue: Button = %ContinueButton


func show_result(r: RunResult) -> void:
	_title.text = tr("RESULT_PASS") if r.passed else tr("RESULT_FAIL")
	_star_row.visible = r.passed
	var i: int = 0
	for child: Node in _star_row.get_children():
		var star := child as TextureRect
		if star != null:
			star.texture = star_full if i < r.stars else star_empty
		i += 1
	_time.text = tr("RESULT_TIME") % Fmt.time(r.time_sec)
	_par.text = tr("RESULT_PAR") % Fmt.time(r.par_time)
	_walls.text = tr("RESULT_WALLS") % r.walls_hit
	_stone_row.visible = r.passed
	_hint.text = tr("STONE_GOT") if r.passed else tr("FAIL_HINT")
	_continue.text = tr("BTN_CONTINUE") if r.passed else tr("BTN_QUIT")


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_continue_pressed() -> void:
	quit_pressed.emit()
