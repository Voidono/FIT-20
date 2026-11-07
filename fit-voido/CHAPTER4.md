# Chapter 4: CON BUG rescue

Update: Spare now also rescues the head and earns Stone #4. The first boss
resolution selects the normal or hidden ending; see `ENDING.md`. This supersedes
the original defeat-only policy described below.

The interaction at `FacultyBossDoor` in `scenes/mapsides/t_2.tscn` is placed at
`(2572, 270)` beside the 210C door artwork. It uses the shared talk-through-door
script and `Dialogues/minigame_battle.dialogue`. The existing campus battle NPC
uses the same dialogue and remains compatible.

Three stones and a saved FIST/POISON choice unlock the fight. The shared activity
host passes that skill to the existing boss module; its difficulty, retry and
quit controls remain available. A victory saves boss-quest completion before
returning. Interacting with 210C after victory plays the faculty-head rescue and
atomically saves Stone #4, rescue completion and the final-gate objective.
Repeat interactions cannot duplicate rewards. Spare remains an unsuccessful
story outcome, consistent with the existing defeat-required rule.

The final-gate objective is the handoff to the next implementation task. No new
office interior or final-gate scene is introduced here. Floor travel remains
user-managed.

Verification: `tests/chapter4_test.gd` exercises both saved skill choices,
prerequisites, Spare, victory, real rescue dialogue, persistence and repeat
rewards. `tests/activity_host_smoke.gd` checks actual module launch and return
using disposable progression and synthetic results; it is not a human boss
playthrough. `tests/document_delivery_test.gd` covers the Chapter 3 handoff.
