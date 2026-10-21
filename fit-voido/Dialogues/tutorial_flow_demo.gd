extends Node
## Interactive Tutorial Sequence Runner for FIT: THE TIME STONE
## Demonstrates seamless transitions across multiple dialogue files and balloon styles:
## 1. Arrival Scene (pixel_balloon) -> NPC Minh greets the time traveler
## 2. Controls Tutorial (tutorial_balloon) -> Key prompts & movement
## 3. UI Tour (ui_tour_balloon) -> Highlights QuestPanel, TimeStoneSlots, PauseButton
## 4. Gatekeeper Check (quiz_balloon) -> Bác Bảo Vệ quick check
## 5. Nhà C Entrance (pixel_balloon) -> Lecturer offers 2 Blind Bags (Garbage Quest vs FIT Runner)

const PIXEL_BALLOON := "res://Dialogues/Bubbles/pixel_balloon.tscn"
const TUTORIAL_BALLOON := "res://Dialogues/Bubbles/tutorial_balloon.tscn"
const UI_TOUR_BALLOON := "res://Dialogues/Bubbles/ui_tour_balloon.tscn"
const QUIZ_BALLOON := "res://Dialogues/Bubbles/quiz_balloon (1).tscn"

var dialogue_arrival: DialogueResource = preload("res://Dialogues/tutorial_arrival.dialogue")
var dialogue_controls: DialogueResource = preload("res://Dialogues/tutorial_controls.dialogue")
var dialogue_hud: DialogueResource = preload("res://Dialogues/tutorial_hud_tour.dialogue")
var dialogue_quiz: DialogueResource = preload("res://Dialogues/tutorial_gate_quiz.dialogue")
var dialogue_stage1: DialogueResource = preload("res://Dialogues/stage1_blind_bags.dialogue")

var _step := 0


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	play_next_step()


func play_next_step() -> void:
	_step += 1
	match _step:
		1:
			# Step 1: Waking up in 2026 at the Gate (Pixel Balloon)
			DialogueManager.show_dialogue_balloon_scene(PIXEL_BALLOON, dialogue_arrival, "start")
		2:
			# Step 2: Movement & Interaction controls card (Tutorial Balloon)
			DialogueManager.show_dialogue_balloon_scene(TUTORIAL_BALLOON, dialogue_controls, "start")
		3:
			# Step 3: HUD / Quest Tour (UI Tour Balloon)
			DialogueManager.show_dialogue_balloon_scene(UI_TOUR_BALLOON, dialogue_hud, "start")
		4:
			# Step 4: Security Guard verification quiz (Quiz Balloon)
			DialogueManager.show_dialogue_balloon_scene(QUIZ_BALLOON, dialogue_quiz, "start")
		5:
			# Step 5: Arriving at Nhà C - Blind Bags Quest Selection (Pixel Balloon)
			DialogueManager.show_dialogue_balloon_scene(PIXEL_BALLOON, dialogue_stage1, "start")
		_:
			print("Tutorial Flow Demo Complete!")


func _on_dialogue_ended(resource: DialogueResource) -> void:
	# Proceed automatically to the next interactive step in sequence
	await get_tree().create_timer(0.3).timeout
	play_next_step()
