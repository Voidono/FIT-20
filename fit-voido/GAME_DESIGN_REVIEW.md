# FIT: The Time Stone — game design review

Reviewed: 6 November 2026

## Verdict and scope

The strongest idea is a campus anniversary adventure seen through a student displaced from 2006 to 2026. Campus exploration, faculty trivia, environmental cleanup, sports, and a programming-themed boss give it a recognizable identity. Trash Train has a clear risk/reward loop; Runner offers pacing decisions; CON BUG provides a thematic climax with combat and peaceful solutions.

The present repository contains substantial individual activities, but does not yet establish a complete, connected adventure. Prioritize completing one journey from introduction to saved reward and return before adding more content.

This is a source-based review of the main menu, campus scene setup, character interaction, tutorial and quest dialogue, save state, settings, and all three minigame systems. It is not a frame-by-frame audit of every asset or third-party addon. No live playtest was performed; Godot was not available on the command path. Visual quality, collision feel, actual completion times, device performance, and difficulty remain unverified. Existing logs contain errors referring to older resource locations and are not evidence of current runtime failures. The pre-existing change to project.godot was left untouched.

## 1. Critical player-journey problems

### Runner cannot be entered through its current NPC conversation

`Dialogues/minigame_runner.dialogue` contains the sample Nathan conversation, with no game launch. The campus NPC also stores the nonexistent `Minigames/fit_runner_starter/scenes/main.tscn` target. Because this NPC has dialogue and does not enable direct scene changes, its target is not used automatically after the conversation. The current module entry is `Minigames/minigames/fit_runner/fit_runner.tscn`.

Replace the placeholder with a short explanation of hold/release pacing and a deliberate Start/Back choice, routed through a host that receives results.

### Battle entry targets missing content

`Dialogues/minigame_battle.dialogue` launches `Minigames/fit_battle_step4/fit_battle/launcher/launcher.tscn`, which is absent. The campus NPC stores another absent target, `Minigames/fit_battle/fit_battle_host.tscn`. The available module is `Minigames/boss_fight/boss_fight.tscn`.

`scenes/UI/loading_scene.gd` stops processing on a failed load and only logs an error. Give the player an explanation and a way back when a destination fails.

### Minigame success does not advance the adventure

`stage1_blind_bags.dialogue` awards Stone #1 only after `garbage_quest` or `fit_runner` is complete. No production completion handler for either quest was found. Runner result connections exist in development examples; Trash Train emits results and Continue signals, but the standalone scene has no host to return to the campus. Its default save routine saves existing GameState data without marking the quest complete.

Define one host responsibility: launch the activity, remember the return location, record a passing result once, update the quest, save, and return the player. Award progression on success so closing the game before Continue cannot lose the earned reward; let Continue control presentation and travel.

### Four-stone promise has no complete implementation

The introduction promises four stones and a return portal. Only the first stone award is evident in the reviewed progression content. The stage-one dialogue points to Room 417, but no complete chain for stones two through four or the final return was found. The tutorial sequence and lecturer selection are demonstrated in a separate demo rather than connected to the main campus entry.

Write a single progression table specifying each stone's activity, prerequisite, pass rule, award event, next destination, and ending effect. Either finish that chain or explicitly scope the playable build to one chapter.

## 2. Onboarding and navigation

- **Teach working controls.** Tutorial dialogue advertises arrows, Shift sprint, and E/Space interaction. The main character dynamically registers WASD, stick/D-pad movement, and E interaction. It does not register arrow movement, Shift sprint, Space interaction, or a controller interaction button. Its desktop hint also advertises arrows. Implement the promised bindings or correct all prompts together.
- **Teach by doing.** The demo automatically moves through arrival, controls, HUD tour, guard quiz, and lecturer conversation. End each lesson with an actual task: walk to Minh, interact, answer, then reach Nhà C. Avoid explaining several systems before players have moved.
- **Move the HUD beyond the demo.** QuestPanel, TimeStoneSlots, and PauseButton are mock tutorial targets in `TutorialFlowDemo.tscn`; a corresponding production quest HUD was not found. Show one current objective, stone count, and a clear route to the destination.
- **Make campus destinations functional.** The Area2D at the top of the main campus connects to `_on_body_entered`, but its attached `scenes/mapsides/area_2d.gd` only extends Area2D and has no handler. Verify and connect the intended doorway before relying on it for progression.
- **Separate mandatory and optional conversations.** Put introductory guidance and activity hosts at purposeful locations. Use visible names, role labels, and objective markers; generic NPCs currently default to wandering, which can make required characters harder to locate.

## 3. Narrative and choices

The 2006/2026 contrast should affect more than the opening joke. Let each stone reveal a small campus memory, changed custom, or faculty milestone. End by paying off the player's wish to return and what they learned about FIT.

The two named “blind bags” reveal their contents immediately. Decide whether this is an informed activity choice or a surprise reward. For an anniversary audience, an informed choice is clearer. Allow switching activities after a failed attempt and explain that both routes earn the same stone.

Activity instructions drift from the implemented mechanics: the lecturer describes relay/obstacle running and bringing collected trash back to the lecturer. Runner is a stamina-pacing game; Trash Train scores deposits in bins during a timed run. Rewrite instructions around the actual pass condition and where the reward is claimed.

Keep campus humor, but review all attached dialogue for audience suitability and remove sample/test material from the player route. `Tliet.dialogue` includes sexual slang and unrelated esports jokes; whether it is attached to any shipped route should be checked before release.

## 4. Quizzes and learning

`GameState.record_quiz_result()` marks any attempt completed, including zero correct. `Quizlv2.dialogue` then sends completed players to its all-done branch, so a low-scoring player cannot retry that quiz through its normal menu. The guard also recognizes a failed attempt as completed, while only a correct answer sets `gate_unlocked`. No production consumer of that unlock flag was found.

Track attempted, passed, and best score separately. Use the passed condition for a gate. Keep practice/retry available after completion, with no duplicate story rewards. Give the correct answer plus one short explanation after mistakes.

The capitalization-only “Hello World” question measures exact typography more than campus understanding. The question about which course makes students doubt their major is subjective. Replace these with facts taught by nearby NPCs or environmental clues. The review did not independently verify historical claims.

Several quiz branches emit `award_exp` with zero, and no consumer of that event was found. Decide whether XP serves a real purpose. If stones alone drive progression, omit XP promises; otherwise define earning, display, and use before adding it.

## 5. Minigame design and balance

### Trash Train

Keep the tension between a longer, more valuable tail and a safer deposit. Defaults are 80 seconds, a 12-item tail, and score thresholds of 33/66/100 for one/two/three stars. These are starting guesses, not validated targets. The active scene overrides the default NPC count from six to ten.

Introduce movement, pickup, and banking before adding multiple bins, heavy/glitch items, NPC cuts, and powerups. Show carried value separately from banked score, identify compatible bins with icons/text, and warn near timeout that carried items do not count.

Check whether high-value heavy items dominate normal items: both point value and the batch multiplier affect rewards. Tune using actual item distribution and route time. Compare first-attempt pass rate with Runner because the player receives the same story reward from either route.

Failure currently offers Retry with no Continue, and no general exit/pause flow was found in the controller. Add a route back to campus on failure and an accessible pause/exit option. Preserve failed-attempt assistance across sessions; the default grants ten extra seconds after two failures, but requires host-provided saved attempt data.

### FIT Runner

Keep the one-input pacing identity and the ghost as an optional performance reference. Teach “hold to increase effort, release to reduce it,” then stamina, then checkpoint timing. Show pass time and exhaustion recovery clearly so a slow run remains understandable.

Documentation is stale: README describes recovery timing events while resting and water restoring 15 stamina. Current tuning disables legacy water recovery and passive coasting recovery, and the controller triggers checkpoint events. Reconcile tutorial text, tuning, and documentation before using the old simulation times as evidence of balance.

Measure whether missing timing events makes recovery too punishing for beginners. Validate both input modes against the current checkpoint model. Make repeated-failure assistance explicit in host configuration and persistence; retry increments alone do not establish that assistance increases.

### CON BUG boss

The Syntax Error → Runtime Error → Fatal Error phases are a strong thematic escalation. FIGHT/ACT/ITEM/MERCY support different approaches, and difficulty selection plus death assistance improve access.

Teach dodging with a safe first pattern. Explain that ACT builds mercy and show progress toward Spare. On Normal, four Debug actions at 16 mercy plus three Ctrl+S actions at 12 reach exactly 100: a useful baseline for comparing peaceful-route duration with FIGHT. Check route balance on every difficulty and ensure win/spare both award the intended story reward.

Skill choice is described as coming from earlier gameplay, but no production bridge was found. Define how the player earns FIST/POISON, or offer a local choice. Test telegraph readability, finger occlusion, and retry fatigue on phones. Provide pause and a clear escape to the campus.

## 6. Presentation, accessibility, and persistence

Use Vietnamese consistently by default; desktop movement hints, sample dialogue, battle labels, and some minigame text mix languages. A language option should cover tutorial prompts and result screens as well as dialogue.

Standardize Start, Retry, Continue, Back, pause behavior, audio levels, and input hints across modules. The boss uses a 640×480 design while the project is 960×540 and Runner is designed around 640×360; inspect scaling and letterboxing on actual displays before judging cohesion.

Support keyboard focus in results: Trash Train creates its result buttons with focus disabled, so normal keyboard navigation cannot reach them. Provide controller interaction in the campus and avoid relying on color alone for bins, timing judgments, or danger cues. Check font sizes and touch targets on a phone.

GameState saves flags, quest stages, NPC stages, and quiz results. It does not currently represent a saved campus position, minigame results, or assistance counters. Establish safe checkpoints, distinguish New Game from Continue, and show what will be resumed. Save failures should be visible to the player when progress is at risk.

## 7. Recommended delivery order

1. Complete a small end-to-end slice: menu → arrival → actual movement/interact lesson → stage-one choice → either activity → saved Stone #1 → return to lecturer → next destination. Both alternative routes must work.
2. Fix missing destinations, loading recovery, doorway handling, truthful controls, quiz pass/retry rules, and activity exit paths.
3. Add the production objective/stone HUD and define all remaining stone awards plus the ending.
4. Reconcile instructions with current mechanics, remove placeholder dialogue, and unify language/input behavior.
5. Run observed playtests, then tune difficulty and presentation from the results.

## 8. Playtest acceptance checklist

Use at least five new players, including keyboard and phone users. The following are proposed targets, not measured results:

- Players can state the goal and find the first required NPC without verbal help.
- Every advertised control works; each device can start, pause, retry, continue, and exit.
- Both stage-one routes award exactly one stone and return to the correct location.
- Relaunch after success, after returning, and before pressing Continue preserves the intended progression.
- Failed quizzes can be retried; locked gates unlock only under the intended rule.
- Record first-attempt pass rate, attempts to success, completion time, exit rate, and player explanations of each failure. Compare Trash Train and Runner rather than assuming equal difficulty.
- Test carried trash at timeout, a final-frame deposit, exhaustion plus a missed checkpoint, death plus difficulty change, win versus spare, and invalid scene loading.
- A full new save can reach the ending without debug shortcuts, and optional content cannot break that route.

Do not approve balance from source inspection alone. The next useful evidence is a recorded uninterrupted run of the connected journey and observed first-time playtests.
