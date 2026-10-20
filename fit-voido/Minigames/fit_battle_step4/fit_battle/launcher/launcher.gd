extends Control
## PLACEHOLDER for the earlier part of the game (the proposal's stage 2: where the player sits).
## It does only what your real game will have to do:
##   1. decide a skill,
##   2. hand it to BossBattle as a plain string (`skill_id`),
##   3. react to `finished`.
## The battle itself shows the difficulty menu, because no difficulty is passed in.
## Delete this folder when your real flow exists.

const BATTLE_SCENE := preload("res://Minigames/fit_battle_step4/fit_battle/battle/battle.tscn")

## Option label -> skill id (res://Minigames/fit_battle_step4/fit_battle/data/skills/<id>.tres).
const SEATS := {
	"Human Students  (FIST)": "fist",
	"Snake Students  (POISON)": "poison",
}

@onready var ui: Control = %UI
@onready var choices: BattleChoiceList = %ChoiceList
@onready var message: Label = %Message


func _ready() -> void:
	_loop()


func _loop() -> void:
	while true:
		ui.show()
		var labels := PackedStringArray(SEATS.keys())
		var pick := -1
		while pick < 0:
			pick = await choices.choose(labels)
		ui.hide()
		var battle := BATTLE_SCENE.instantiate() as BossBattle
		battle.skill_id = SEATS[labels[pick]]
		add_child(battle)
		var result: StringName = await battle.finished
		battle.queue_free()
		message.text = "Kết quả trận boss: %s" % result
		ui.show()
		await get_tree().create_timer(2.5).timeout
		message.text = ""
