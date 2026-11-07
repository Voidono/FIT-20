# Activity guides and boss pause

The shared activity host opens `Dialogues/activity_introductions.dialogue` in the
existing `Dialogues/Bubbles/tutorial_balloon.tscn` before creating a minigame.
Each main-game launch offers instructions or a skip choice. Practice, Ghost Race,
Trash Train and CON BUG have separate cues with rules matching their story role.
No activity clock, damage or attempt recording runs during this initial guide.
Trash Train's internal tutorial is skipped in the host to avoid duplicate guides;
standalone Trash Train retains its original tutorial.

CON BUG has a pause button and Esc/P shortcuts. Resume returns to the exact combat
state, Help reopens the same bubble, and Exit returns through the existing campus
host. Closing Help returns to the pause menu rather than silently resuming danger.
Attack-duration and linger timers now honor tree pause; physics, input and tweens
inside the boss viewport pause as well. Paused time is excluded from result seconds.
Leaving a paused fight restores the prior tree-pause state. The dev harness also
receives a quit result instead of waiting indefinitely for a victory signal.

The boss wrapper and help balloon remain active while paused, so the menu and guide
can still be used. The guide is above the pause layer. Main-game hosts should launch
the battle with an unpaused SceneTree; its new pause flow controls tree pause.

Checks: `tests/activity_intro_test.gd` executes all full-guide and skip branches;
`tests/boss_pause_test.gd` verifies pause/resume, frozen animation/timers and cleanup;
`tests/activity_host_smoke.gd` exercises the real skip-to-module flow, help replay
while paused, saved outcomes and campus returns. Add `-- render` to that smoke test
to capture the introduction bubbles and boss pause menu in Godot.
