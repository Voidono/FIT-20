class_name BossSpeech
extends Node
## The contract between BossBattle and whatever shows the boss's lines.
## BossBattle runs `await speech.say(event, context, anchor)` and carries on when it returns.
##   event   : &"turn", &"phase_enter", &"defeat" or &"spare"
##   context : {"text": placeholder line from the BossPhase / BossEnemy, "phase": 1..n, "turn": n}
##   anchor  : global position next to the boss where a bubble should appear
## To use Dialogue Manager, replace the Speech node in battle.tscn with a node whose script
## extends this class (see dialogue_manager_speech.gd.example).


func say(_event: StringName, _context: Dictionary, _anchor: Vector2) -> void:
	pass
