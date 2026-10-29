class_name FrResultPanel
extends PanelContainer
## Results screen. Stars, Time Stone and buttons are nodes in result_panel.tscn; swap star_full / star_empty
## in the Inspector for your own art. The text comes from the translation keys.

signal retry_pressed
signal quit_pressed

@export var star_full: Texture2D
@export var star_empty: Texture2D

@onready var _title: Label = FrLookup.node(self, "TitleLabel") as Label
@onready var _star_row: Control = FrLookup.node(self, "Stars") as Control
@onready var _time: Label = FrLookup.node(self, "TimeLabel") as Label
@onready var _par: Label = FrLookup.node(self, "ParLabel") as Label
@onready var _walls: Label = FrLookup.node(self, "WallsLabel") as Label
@onready var _qte: Label = FrLookup.node(self, "QteLabel") as Label
@onready var _stone_row: Control = FrLookup.node(self, "StoneRow") as Control
@onready var _hint: Label = FrLookup.node(self, "HintLabel") as Label
@onready var _continue: Button = FrLookup.node(self, "ContinueButton") as Button


func show_result(r: FitRunnerResult) -> void:
	_title.text = tr("FR_RESULT_PASS") if r.passed else tr("FR_RESULT_FAIL")
	_star_row.visible = r.passed
	var i: int = 0
	for child: Node in _star_row.get_children():
		var star := child as TextureRect
		if star != null:
			star.texture = star_full if i < r.stars else star_empty
		i += 1
	_time.text = tr("FR_RESULT_TIME") % FrFmt.time(r.time_sec)
	_par.text = tr("FR_RESULT_PAR") % FrFmt.time(r.par_time)
	_walls.text = tr("FR_RESULT_WALLS") % r.walls_hit
	_qte.visible = (r.qte_perfect + r.qte_good + r.qte_miss) > 0
	_qte.text = tr("FR_RESULT_QTE") % [r.qte_perfect, r.qte_good, r.qte_miss]
	_stone_row.visible = r.passed
	_hint.text = tr("FR_STONE_GOT") if r.passed else tr("FR_FAIL_HINT")
	_continue.text = tr("FR_BTN_CONTINUE") if r.passed else tr("FR_BTN_QUIT")


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_continue_pressed() -> void:
	quit_pressed.emit()
