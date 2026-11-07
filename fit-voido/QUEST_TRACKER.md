# Journey journal

The exploration HUD is a compact dark-ink journal with brass details, one next
action, a destination and four hand-drawn Time Stone sockets. All icons are native
Godot drawing in `journey_icon.gd`; there are no downloaded/generated bitmap assets
or new font dependencies. The existing font supports Vietnamese.

## Behavior

- One next action follows the actual story handoffs, rather than displaying the
  entire saved quest history. Success directs the player back to the reward NPC.
- Completed quests remain saved; hiding them in the HUD never deletes progress.
- Stone ownership and gate placement are separate. Hollow sockets become faceted
  gold gems when earned, and gain a small check when placed at the Time Gate.
- Collapse with the 44×44 button or J. The compact form retains the current
  objective title and all four stones. Small screens (height under 420) and mobile
  start compact; an explicit player choice takes priority over automatic sizing.
- During dialogue the journal temporarily folds, then restores the player's
  preference. It stays out of menus, minigames, loading screens and ending UI.
- Passive surfaces ignore mouse/touch input. Only the collapse button captures
  it. The journal does not take keyboard focus from movement or interaction.
- No arrows, map pins, spoiler about the hidden ending, quest-count clutter or
  binary 0/1 progress bars. Generic collection quests can still show real counters.

Nearby NPC prompts and name tags use the same ink/brass palette. Door/stair
instructions use a matching bottom-screen card and disappear on leaving range.
The desktop control reminder is in Vietnamese and includes J for the journal.

## Authoring

`GameState` remains the only saved source of quest stages, stones and flags.
`journey_guidance.gd` reads those facts and supplies short HUD copy and location
labels. It performs no saving and does not alter quests to select an objective.
The resolver prioritizes later handoffs over stale earlier active quest entries.

Edit `COPY` in `scenes/UI/quests/journey_guidance.gd` for story HUD wording.
`GameState.update_quest_objective` and authored quest title overrides still take
precedence. For optional content, the existing `add_quest`, counters, hide/remove
and save APIs are preserved. If no story objective is active, the latest visible
unfinished generic quest is shown. The old quest-row scene remains available as
an authoring component, but is no longer instantiated by the journal.

New exploration scenes can opt in with group `quest_hud_host`; scenes under
`res://scenes/mapsides/` already opt in by path.

## Verification

`tests/quest_tracker_test.gd` walks all story handoffs through the real GameState
APIs, including stale quests, perfect-quiz handoff, both stone states, save/load,
New Game, optional counters, dialogue fold, manual preference, input pass-through
and desktop/small/portrait layout bounds. It uses a disposable save.

`tests/journey_journal_preview.gd` renders the actual floor-4 map in expanded,
compact, delivery, dialogue and nearby-interaction states at multiple sizes.
Outputs are `tests/journal_*.png`. These are render checks, not a physical-phone
usability test. Door/ending regressions are covered separately by the existing
room-exit and hidden-ending tests.
