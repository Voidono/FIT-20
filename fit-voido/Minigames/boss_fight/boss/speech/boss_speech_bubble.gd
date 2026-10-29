class_name BossSpeechBubble
extends BossSpeech
## Placeholder speech bubble: types context.text next to the boss, then removes itself.
## Restyle the Bubble node (StyleBox, font, size) or replace this whole node later.

@onready var bubble: BattleText = %Bubble


func say(_event: StringName, context: Dictionary, anchor: Vector2) -> void:
	var line: String = context.get("text", "")
	if line == "":
		return
	bubble.global_position = anchor
	await bubble.say(line, false)
