# Campus cast

Six named professors, one campus/hallway assignment each:

| Professor | Location | Role |
|---|---|---|
| Dũng | Original entrance NPC spot (`NPC/Minh`) | Arrival and tutorial |
| Tùng | Beginning of Nhà C (`NPC/Lecturer`) | Chapter 1 activities and stone |
| Khánh | Original sports-field position `(3260, 359)` | Chapter 3 quiz, race and documents |
| Ngọc | Outside 210C, tầng 2 | Document delivery and chapter 4 lead |
| Tuấn | Emerges from 419, tầng 4 | Directs player to Khánh; stays by doorway afterwards |
| Thắng | Inside office 210 | Existing cutscene, rescue and gate |

417 has an unnamed guest lecturer with the suited `boykopho2` artwork, avoiding a second Tùng portrait. The two intentionally silent classroom students stay unchanged.

## Ambient walkers

Eight walkers on campus and two on each of tầng 2, 3 and 4: fourteen total, all with full walking frames. One additional outdoor guest, **Chủ Tịch AFK**, uses the static T1 sprite and stays at `(3800, -290)` in the campus life scene. `NPC_1` (white) and `NPC_2` (red) are university students. The suited `boykopho` walkers and T1 are visitors, not students.

Each ambient NPC has two randomized, non-repeating conversations with two selectable replies per conversation: 30 conversations / 60 branches. These never modify progression.

Author positions, skins, movement and dialogue in `scenes/ambient/campus_cast.json`, then run `python tools/build_campus_life.py`. Map-level `CampusLife` transforms remain editable. Tầng 3 uses its own `t_3_life.tscn`.

## Khánh's ghost

Replaces the first of five race rivals, using `khanh.png` idle and `khanhrun1`, `khanhrun2`, `khanhrun3` for moving states. His separate SpriteFrames resource leaves player/other ghosts unchanged. Strategy 6 uses the full training pace and perfect checkpoints; the other four retain 0.94 playback speed. Practice remains unchanged, and chapter 3 still requires top three rather than beating Khánh.

Internal quest IDs containing `minh` or `tuan` remain intact for save compatibility; player-facing names and guidance use the new cast.

Checks: `tests/ambient_life_test.gd`, `tests/reconnected_rooms_test.gd`, `tests/fit_runner_modes_test.gd`, `tests/quest_waypoint_test.gd`. Visual previews: `tests/npc_recast_preview.gd`.
