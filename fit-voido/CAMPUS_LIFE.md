# Campus life

42 optional characters and 84 Vietnamese conversations are placed in the actual
campus (`nửa đầu.tscn`) and Nhà C floors 2–4: 21 outside and seven on each floor.

Every character has a funny nickname and two different exchanges. The first is
chosen randomly; the next interaction avoids immediately repeating it. Topics
are food, group assignments, AI prompts, Wi-Fi, photos, sleep, deadlines, and
other student nonsense. A few replies let the player misunderstand modern slang;
the conversations do not reveal the time-travel plot or change quest progress.

Examples: Tiệm Phở Anh Hai, Bánh Mì Bách Khoa, Chủ Tịch Aura Âm,
Nhóm Trưởng Đang Nhập, Git Đổ Tại Máy Em, Vịt Cao Su Không Lương.

## Placement and artwork

- All existing full-body campus NPC artwork is used. The main character frames,
  object sheets, and Trash Train's floating-head icons are not used as students.
- Existing `NPC_1` and `NPC_2` directional animations are reused. The numbered
  `boykopho` frames now form a third walking skin, with its right walk mirrored
  for left movement. Walkers wander locally or follow short ping-pong routes.
- Static portraits remain stationary. Each of the six professor portraits has
  one visible owner, including Tùng in the existing classroom. The copied floor-3 recipient uses
  a generic student portrait instead of repeating the floor-2 professor.
- Reused student sprites are at least 600 map units apart within the same map.
- The entrance's nine old demo NPCs were replaced by the distributed ambient
  cast. Minh, the Nhà C lecturer and Thầy Tuấn retain their story dialogues and
  locations. Existing quest doors, quizzes and progression scripts are untouched.

## Editing

Each map has a `CampusLife` scene instance. Open the corresponding scene under
`scenes/ambient/` to move characters or edit movement in the Godot Inspector:

- `campus_life.tscn`
- `t_2_life.tscn`, `t_3_life.tscn`, `t_4_life.tscn`

The dialogue resource is `Dialogues/campus_banter.dialogue`. Its cue names match
the character node IDs. Runtime selection and the additional walking skin live
in `scenes/ambient/ambient_npc.gd`, which extends the existing NPC template and
uses the existing pixel dialogue bubble.

`campus_cast.json` is the authored source used to generate these scenes and the
dialogue. `python tools/build_campus_life.py` regenerates those files, overwriting
direct edits to the generated scenes/dialogue; update the JSON first if using
the generator. It does not rewrite the four map scenes.

## Checks

`tests/ambient_life_test.gd` checks all 84 exchanges, unique names and professor
portraits, reuse spacing, walk frames, spawn clearance, patrol routes and wander
envelopes. It runs movement, checks static characters stay still, and exercises
real conversations to verify pause/resume and non-repeating dialogue selection.

`tests/ambient_map_preview.gd` renders overviews and a real conversation using a
disposable save. `tests/floor_stairs_test.gd` checks all four stair routes.
