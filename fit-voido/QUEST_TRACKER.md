# Quest Tracker HUD

Implemented as a new, independent HUD based on the UI Tour's amber/plum
palette and hard pixel borders. The old UI Tour and Tutorial Balloon files
are preserved. No Dialogue Manager nodes, resources, response menus, input
handlers, spotlight, dimming, pointers, step pips or typewriter are used.

## Files and responsibilities

- `scripts/game_state.gd`: existing autoload is also the QuestManager. Owns
  stages, display metadata, counters, visibility, save/load and change signals.
- `scenes/UI/quests/quest_tracker.tscn` and `.gd`: autoload CanvasLayer,
  responsive placement, scene visibility, collapse, bounded scrolling, row diffing.
- `scenes/UI/quests/quest_row.tscn` and `.gd`: one quest's presentation and
  completion flash. Reused rows animate only on an incomplete-to-complete change.
- `scenes/UI/quests/quest_theme.tres`: reusable amber/plum flat styles. Uses
  Godot's default font for Vietnamese coverage; a custom pixel font can be set
  on the theme after confirming it contains Vietnamese glyphs.
- `tests/quest_tracker_test.gd`: isolated-save automated checks.

## Complete scene hierarchy

```
QuestTracker (CanvasLayer, layer 20, quest_tracker.gd; autoload)
└── Root (Control, full rect, mouse IGNORE, quest_theme.tres)
    └── Panel (PanelContainer, top left, mouse IGNORE)
        └── Body (VBoxContainer, mouse IGNORE)
            ├── Toggle (Button, toggle mode, 44px height, focus NONE)
            └── Scroll (ScrollContainer, vertical auto, horizontal disabled)
                └── List (VBoxContainer, expand horizontally, mouse IGNORE)
                    ├── Empty (Label; shown with no visible quests)
                    └── QuestRow* (PanelContainer, quest_row.gd, mouse IGNORE)
                        └── Body (VBoxContainer)
                            ├── Heading (HBoxContainer)
                            │   ├── Status (Label, [ ] or [OK])
                            │   └── Title (Label, wrapped)
                            ├── Objective (Label, wrapped)
                            ├── Counter (Label, right aligned)
                            └── Progress (ProgressBar, 4px, no percentage)
```

The QuestRow subtree is instantiated from quest_row.tscn for each quest.
All passive row controls ignore mouse input. Only the toggle and scroll area
participate in UI input. No global actions or focus are captured. The scroll
area passes unhandled input upward; it must accept scrolling/touch drags.

## Connection and gameplay integration

`project.godot` registers QuestTracker after GameState. No Inspector wiring is
needed. Tracker `_ready()` connects `GameState.quests_changed` to `_refresh()`.
GameState bridges its existing `quest_stage_changed` signal to `quests_changed`,
so existing dialogue starts/completions and activity-result completions update
rows too. Load/reset, metadata, counter, hide and remove changes emit the same
signal. There is no `_process()` polling.

The HUD autoload survives scene changes and uses viewport coordinates rather
than player or Camera2D paths. It appears in the existing `scenes/mapsides/`
exploration scenes. For any additional gameplay scene, put its root in group
`quest_hud_host`. Menu, loading and standalone minigame scenes remain hidden.
No new scene files or node paths are required from you for existing maps.

```gdscript
# New numeric quest (saved automatically):
GameState.add_quest("collect_scrap", "Thu gom", "Thu gom 10 mảnh vật liệu.", 10)
GameState.update_quest_progress("collect_scrap", 3) # Absolute total: 3/10
GameState.update_quest_objective("collect_scrap", "Tìm vật liệu trong sân.")
GameState.update_quest_progress("collect_scrap", 10) # Completes automatically

# Rule-based quest: leave numeric target at 1 and complete when rules pass.
GameState.start_quest("reach_building_c")
GameState.complete_quest("reach_building_c")

# Hide without losing story completion; show again with false.
GameState.hide_quest("collect_scrap")
GameState.hide_quest("collect_scrap", false)
QuestTracker.set_show_completed(false) # Filter all completed rows this session

# Explicitly delete stage and metadata (also deletes story completion):
GameState.remove_quest("collect_scrap")
```

Add known legacy quest titles/objectives to `QUEST_CATALOG` in GameState.
Unknown IDs get a readable fallback title. Existing saves work without the
new `quest_details` dictionary. Metadata/counters/hide flags are saved there;
existing quest stage data keeps its format. Collapse and the completed filter
are session preferences, retained through map changes but not app restarts.
Counters must be updated by the gameplay system that owns that objective:
there is no guessed link to collectible signals that the project has not
provided. Existing minigames remain binary completion goals (0/1 to 1/1).
Future quest rules only need to publish display data via this API.

Width is capped at 288 viewport units with a 12-unit margin. List height is
bounded to roughly 40% of viewport height and scrolls for long lists. Resizing
and content minimum-size signals recalculate layout. Title/objective wrap.
For devices with a display notch, increase `screen_margin` as appropriate;
hardware safe-area behavior still needs device validation.

## Test checklist

Automated: run Godot with `--headless --path . --script tests/quest_tracker_test.gd`.
Also run `tests/progression_test.gd` to check existing story progression.
Tests use uniquely named disposable saves and never overwrite the player's save.

- [ ] Start two quests: both appear, with independent titles and counters.
- [ ] Update a counter and objective: rows refresh without frame polling.
- [ ] Reach the goal: counter clamps, [OK] appears, subtle flash plays once.
- [ ] Unrelated quest updates and loading completed saves do not replay flashes.
- [ ] Hide completed quests: story completion remains true; unhide works.
- [ ] Save/restart: counters, objectives, stages and hidden state are restored.
- [ ] New Game/F8: stale rows disappear.
- [ ] Collapse/expand using mouse and touch; no gameplay focus is stolen.
- [ ] Walk and use joystick outside interactive elements; camera motion leaves HUD fixed.
- [ ] Resize to 640x360, 960x540, 1280x720 and mobile landscape aspect ratios.
- [ ] Long Vietnamese titles/objectives wrap, many quests scroll within the panel.
- [ ] Map transitions retain the HUD; menus/loading/minigames hide it.
- [ ] Tutorial and other dialogue balloons behave as before.
- [ ] Validate touch scrolling, display cutouts and visual font quality on a device.

## Verification in this workspace

- Quest tracker automated tests passed with zero failures (including the live
  autoload signal path, save/load, completion, hide/remove and reset).
- Existing progression suite passed all 48 checks.
- Both headless suites report shutdown ObjectDB/resource warnings.
- Project-wide editor import also reports existing TileSet atlas errors and
  duplicate global `DialogueNPC` classes. These unrelated files were not changed.
- Visual appearance, camera travel and physical mobile touch interaction remain
  manual checks; automated headless checks do not verify rendered pixels.
