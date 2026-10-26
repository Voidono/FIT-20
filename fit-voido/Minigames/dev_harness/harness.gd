extends Control
## DEV ONLY. Plays the role of your main game: decides a skill, runs the fight, reads the result.
## It is not part of the module: run this scene (F6) to try the fight in your project, then delete dev_harness/.

const BOSS_FIGHT := preload("res://boss_fight/boss_fight.tscn")

## Option label -> skill id. Your real game derives this from what the player did earlier.
const SEATS := {
	"Human Students  (FIST)": &"fist",
	"Snake Students  (POISON)": &"poison",
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
		var config := BossFightConfig.new()
		config.skill_id = SEATS[labels[pick]]
		var fight := BOSS_FIGHT.instantiate() as BossFight
		fight.config = config
		add_child(fight)
		var result: BossFightResult = await fight.finished
		message.text = "Kết quả: %s   |   chết %d lần   |   %.0f giây" \
				% [result.outcome, result.deaths, result.seconds]
		ui.show()
		await get_tree().create_timer(3.0).timeout
		message.text = ""
