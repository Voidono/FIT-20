# Fill-in dialogue templates

These templates follow the conversations already in `npc_ngoc.dialogue`, `npc_tung.dialogue`, `tutorial_arrival.dialogue`, `minigame_runner.dialogue`, and `quiz_basics.dialogue`. Dialogue text can be Vietnamese or English; keep the syntax and IDs unchanged while filling in the wording.

## Choose a starting point

| You want to write… | Copy this file |
|---|---|
| An NPC with a first meeting, choices, reminders, and a final repeat line | `Dialogues/templates/npc_template.dialogue` |
| An activity introduction with rules and a start/later choice | `Dialogues/templates/minigame_template.dialogue` |
| A scored quiz with answer feedback and a saved result | `Dialogues/templates/quiz_template.dialogue` |

Duplicate your chosen file into `Dialogues/`, name it for the character or encounter, then replace every `TEMPLATE_...`, `NPC_NAME`, and `<...>` placeholder. Template originals are authoring starters; do not attach them to an NPC before replacing placeholders.

## Fill in this writing sheet first

```text
Dialogue filename:
NPC display name:
Unique NPC / quiz ID:
Location and chapter:
Personality / speaking style:
What the player should learn:
What the player should do next:

FIRST MEETING
Greeting:
Situation / clue:
Player choice A:
    NPC reply:
Player choice B:
    NPC reply:
Next destination / action:

RETURN VISIT
Greeting:
Reminder choice and reply:
Completion condition (if any):
Completion reply:

AFTER COMPLETION
Short repeat line:

OPTIONAL ACTIVITY / QUIZ
Activity ID or quiz ID:
Controls / rules:
Success condition / question count:
Questions, choices, correct answers, and explanations:
Result response:
Reward and the existing game function that grants it:
```

## Basic writing syntax

```text
~ start
Minh: <Your opening line.> [#mood=happy]
- <Player choice A.>
	Minh: <Reply to A.>
	=> END
- <Player choice B.>
	Minh: <Reply to B.>
	=> END
```

- `~ name` starts a named section. `=> name` jumps to it; `=> END` ends the conversation.
- `Speaker: text` displays a spoken line. The text after `- ` is a player choice; indent its reply with a tab. Lines after all choice branches are shared continuation lines.
- Keep speaker names consistent. They also determine portrait lookup in the pixel balloon.
- Use `[color=green]destination[/color]` or `[color=yellow]key item[/color]` sparingly, as the existing arrival dialogue does.
- `[#mood=happy]` requests a mood portrait if available. The pixel balloon checks `res://portraits/<speaker_lowercase>_<mood>.png`, then the base speaker portrait (other supported image extensions also work). A tag alone does not create an expression image.
- Use unique, stable IDs such as `linh_yard`. Reusing another NPC's or quiz's ID shares its saved progress.

## Progress and rewards

The NPC starter follows `new → met → active → complete`. It becomes active after the introduction, including either opening choice. Its completion option records a conversation milestone based on the player's choice. For an actual task, check the real game state before offering completion; a player's claim is not proof of success.

For a quest, use existing project methods where appropriate:

```text
set GameState.start_quest("YOUR_QUEST_ID")
```

Check the actual objective before calling `GameState.complete_quest("YOUR_QUEST_ID")`. For example, the chapter 1 lecturer uses `GameState.can_claim_stage1_stone()` before `GameState.claim_stage1_stone()`. Keep that chapter flow when changing its dialogue; the generic minigame starter only launches an activity and does not select a chapter activity or grant a stone.

For a one-time tutorial, put the introduction under `if not GameState.has_flag("YOUR_FLAG_ID"):` and call `set GameState.set_flag("YOUR_FLAG_ID")` after it. Add a short repeat line for later visits, following `tutorial_arrival.dialogue`.

For more quiz questions, copy a question section, give it a unique title, and update every answer's next-section jump. Update the total in `quiz_begin` and both score displays. The starter saves a result after any score and shows the completed message on later visits, matching the existing quiz pattern.

## Put it in the game

1. Select your NPC using `scenes/Character/dialogue_npc.gd` in Godot.
2. Assign your copied `.dialogue` file to **Content → Dialogue**.
3. Keep **Cue** as `start`. Leave **Repeat Cue** empty so this file chooses the correct return dialogue from saved progress.
4. Use `res://Dialogues/Bubbles/pixel_balloon.tscn` for the standard dialogue appearance. Keep a specialized balloon if the encounter already requires one.
5. Preview the dialogue in the Dialogue Manager editor, then interact with the NPC in the game. Check each choice, a return visit, and the completed visit. Check minigame launches and quiz scores in-game because they depend on the project's saved state and autoloads.

Saved progress affects which lines appear. Use a fresh test save when checking first meetings. The project's debug F8 shortcut resets **all** saved progress, so use it only if you intend to clear that test progress.
