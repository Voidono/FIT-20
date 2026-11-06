# Shared progression integration

Implemented foundation for the four-stone journey. The chapter content still needs to call these APIs at the appropriate story handoffs.

## Stable IDs and dialogue calls

- Activities/quests: `garbage_quest`, `fit_runner`, `boss_fight`.
- Skills: `fist`, `poison` (lowercase). `GameState.choose_skill("poison")` requires Stone #1 and retains the first valid seating choice.
- Suggested document item ID: `marathon_documents`. Use `grant_quest_item`, `has_quest_item`, and `deliver_quest_item`. Delivery consumes possession and prevents reissuing the same item.
- `GameState.award_time_stone(1)` through `(4)` enforce sequential chapter prerequisites and reject duplicate awards. Ownership uses the existing `stage1_stone_collected` … `stage4_stone_collected` flags for old-save/dialogue compatibility.
- `GameState.is_chapter_unlocked(1)` through `(5)` derive access from all earlier stones; chapter 5 is the final gate. Attach these checks to future doors and story transitions. Unlocking is a query, not automatic scene travel.
- `GameState.place_time_stone(number)` records final-gate placement. `complete_ending()` requires all four owned and placed stones.

Example dialogue mutation:

```text
set SceneLoader.start_minigame("fit_runner")
```

The current three campus activity conversations use this bridge. The boss requires three stones plus a selected skill. There is no silent skill default. The proposal specifies victory: Spare results are recorded but do not complete the boss quest.

## Activity contract

`SceneLoader.start_minigame(id)` captures the current host scene and the grouped player's global position, saves it, and opens `scenes/UI/activity_host.tscn`. It returns an Error if unavailable or unconfigured. Activities must be launched from a saved scene containing a node in the `player` group. Do not launch this host scene directly.

The host configures saved Runner attempts/assistance, Trash Train failures, or the boss skill. Each emitted attempt updates `GameState.activity_result(id)` with attempts, failures, best stars, latest result, and whether any attempt passed. A later failed replay cannot revoke a completed quest. Results save on completion, before Continue. Story NPCs remain responsible for awarding stones; the bridge does not award Stone #1 prematurely.

The host's “Về khuôn viên” button exits even during an activity pause. Continue/quit signals also return. The character restores the saved position only on this return, so ordinary travel does not teleport players to an old checkpoint. A failed save keeps the player in the activity host with a retry-save message. Threaded loading failure provides a Back button.

The return checkpoint survives restarting, but a full main-menu Continue/resume flow is a later task. The activity host does not resume interrupted minigame simulation. Exiting an unfinished attempt does not count as a completed failure.

## Save compatibility

Door travel uses `SceneLoader.go_to_spawn(scene_path, local_position)` with a separate, transient destination spawn. It does not overwrite the saved minigame return checkpoint. The shared door script delays scene changes until after physics callbacks and disarms thresholds containing an arriving player until they leave them.

The existing progress section and legacy flags, quests, NPC stages, and quizzes are preserved. Version 2 adds `journey` and `activity_results`; older saves use empty defaults. `reset_progress()` also clears new data and active quiz session values. `save_failed` and `last_save_error` expose storage failures.

## Verification

Run with Godot 4.7.2 from the project root:

```text
godot --headless --path . --script res://tests/progression_test.gd
godot --headless --path . --script res://tests/activity_host_smoke.gd
```

Tests use unique disposable save files and leave `game_state.cfg` untouched. The first checks conversation compilation, persistence, legacy compatibility, prerequisites, replay safety, item delivery, and reset behavior. The second launches each actual activity through SceneLoader, submits a synthetic success through its real result adapter, and verifies returning to the original player position. Existing Trash Train atlas errors and minigame shutdown-resource warnings are separate from the progression assertions; these checks are not proof of a completed playthrough.
