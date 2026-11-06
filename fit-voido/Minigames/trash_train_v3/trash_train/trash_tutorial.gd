class_name TrashTutorial
extends Node
## Shows the trash-train tutorial dialogue (using the project's DialogueManager + balloon)
## before the first run of a session.
##
## Usage inside trash_train.gd (or any wrapper scene):
##   _tutorial = TrashTutorial.new()
##   add_child(_tutorial)
##   await _tutorial.run()   # waits until the balloon closes, then returns
##
## The tutorial is skipped automatically if:
##   • it has already been shown this session  (session_shown flag)
##   • the dialogue resource cannot be loaded  (graceful fallback)

const DIALOGUE_PATH := "res://Dialogues/trash_tutorial.dialogue"
const BALLOON_PATH  := "res://Dialogues/Bubbles/tutorial_balloon.tscn"
const CUE           := "start"

## Set to true to always skip the tutorial (e.g. after the player clears level 1).
var skip := false

## True once the tutorial has been shown this session.
var session_shown := false

var _balloon_instance: Node = null


## Show the tutorial and wait until it finishes.
## Returns immediately (no balloon) if [member skip] is true or already shown.
func run() -> void:
	if skip or session_shown:
		return

	var resource: DialogueResource = _load_dialogue()
	if resource == null:
		push_warning("TrashTutorial: could not load dialogue at '%s' — skipping." % DIALOGUE_PATH)
		return

	session_shown = true

	var manager = _get_dialogue_manager()
	if not is_instance_valid(manager):
		push_warning("TrashTutorial: DialogueManager singleton not found.")
		return

	var balloon: Node = null
	if ResourceLoader.exists(BALLOON_PATH) and manager.has_method("show_dialogue_balloon_scene"):
		balloon = manager.show_dialogue_balloon_scene(BALLOON_PATH, resource, CUE)
	elif manager.has_method("show_dialogue_balloon"):
		balloon = manager.show_dialogue_balloon(resource, CUE)

	if is_instance_valid(balloon):
		# Wait until the player finishes the dialogue and the balloon closes
		if balloon.is_inside_tree():
			await balloon.tree_exited
		elif manager.has_signal("dialogue_ended"):
			await manager.dialogue_ended


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _load_dialogue() -> DialogueResource:
	if not ResourceLoader.exists(DIALOGUE_PATH):
		return null
	var res = load(DIALOGUE_PATH)
	if res is DialogueResource:
		return res as DialogueResource
	return null


func _load_balloon() -> PackedScene:
	if not ResourceLoader.exists(BALLOON_PATH):
		return null
	var res = load(BALLOON_PATH)
	if res is PackedScene:
		return res as PackedScene
	return null


func _get_dialogue_manager() -> Object:
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	return get_node_or_null("/root/DialogueManager")
