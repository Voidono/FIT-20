# Campus life

The current cast has fourteen optional walkers: eight in `nửa đầu.tscn` and two on each of Nhà C floors 2–4. Five additional university students are spread around the outdoor campus. A ninth outdoor NPC, **Chủ Tịch AFK**, is an explicitly stationary guest using `T1.png`, placed at `(3800, -290)` within `CampusLife`. His sprite is scaled to match the surrounding characters. All other ambient characters use animated skins and wander or follow short ping-pong routes.

Each ambient NPC has two Vietnamese conversations, selected randomly without an immediate repeat. Each conversation has two pickable replies: 30 conversations and 60 branches in total. Topics include HANU, deadlines, AI, Wi-Fi, modern slang, and the player's curious stones or old habits. These conversations do not change quest progression.

White-shirt `NPC_1` and red-shirt `NPC_2` are university students. The suited `boykopho` walkers are visitors or delivery guests, and speak accordingly.

The six named professors have distinct story roles. See [NPC_CAST.md](NPC_CAST.md) for assignments and Khánh's expert race ghost. The room 417 teacher is an unnamed guest lecturer.

## Editing

Each map has a `CampusLife` instance from `scenes/ambient/campus_life.tscn`, `t_2_life.tscn`, `t_3_life.tscn`, or `t_4_life.tscn`. Floor 3 uses its own scene.

Author the cast, coordinates, routes and choice dialogue in `scenes/ambient/campus_cast.json`, then run:

```text
python tools/build_campus_life.py
```

The generator validates population limits and animated skins, with T1 as the one permitted stationary campus guest. It overwrites the generated life scenes and `Dialogues/campus_banter.dialogue`; it preserves map-level instance transforms. Use `--location campus` to regenerate only the outdoor scene and shared dialogue. Runtime conversation selection and the extra walking skin are in `scenes/ambient/ambient_npc.gd`.

## Checks

`tests/ambient_life_test.gd` checks every response branch, population limits, unique professor assignments, walking frames, spawn clearance, patrol and wander areas, actual movement, and pause/resume during real conversations.

`tests/npc_recast_preview.gd` renders the dialogue choices, Tuấn's doorway entrance, and Khánh's race ghost with disposable progress. `tests/reconnected_rooms_test.gd`, `tests/fit_runner_modes_test.gd`, and `tests/quest_waypoint_test.gd` cover their story and race integration.
