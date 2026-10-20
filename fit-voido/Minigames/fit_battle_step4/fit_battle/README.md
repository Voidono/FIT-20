# FIT: THE TIME STONE - Boss Battle (step 4)

Open `project.godot` in Godot 4.7 and press F5. First launch: let the editor finish importing.

Flow in this project: `launcher` (placeholder for the earlier part: pick a seat, i.e. a skill) -> difficulty menu ->
fight (restarts on death) -> back to the launcher. Press F6 on `battle/battle.tscn` to test the fight alone.

## Controls
| | Keyboard | Touch / mouse |
|---|---|---|
| Move heart | Arrows / WASD | Touchscreen laptop: drag anywhere (relative drag). Phone: on-screen joystick |
| Menus | Arrows + Z / Enter | Tap |
| Confirm (text, attack bar) | Z / Enter / Space | Tap anywhere |
| Cancel / skip text | X / Esc | BACK button / tap |
| Debug panel | F1 or DBG button | debug builds only |

## Hand the skill over from the earlier part (placeholder: a string)
```gdscript
var battle: BossBattle = preload("res://battle/battle.tscn").instantiate()
battle.skill_id = "poison"                         # loads res://data/skills/poison.tres
battle.finished.connect(_on_battle_finished)       # &"win" or &"spared"
add_child(battle)
```
`launcher/launcher.gd` does exactly this. Delete the `launcher` folder when your real flow exists.
Prefer a resource? Set `battle.skill` instead. Unknown id -> error in the Output panel and FIST is used.

## Difficulty menu
The battle shows it by itself when `difficulty` is empty. Set `battle.difficulty = BossBattle.difficulty_from_id(&"easy")`
to skip it. The game-over screen offers RETRY and CHANGE DIFFICULTY (turn off with `allow_difficulty_change`).
`BattleDifficultyMenu` is reusable anywhere: `var d = await menu.pick(current)`. Presets = the path list on the node.

## Phones (mobile)
- On phones and tablets (native Android / iOS, or a web export running on them) a big on-screen joystick appears
  **only while you are dodging**: Godot 4.7's built-in `VirtualJoystick`, dynamic mode, so it shows up under your
  thumb inside the bottom-left corner. Base 190 px, tip 84 px in the 640x480 game space (about 2.7 cm on a typical phone).
  It drives the `ui_*` actions the heart already reads.
- Everything else is tap: menus, lists (taller buttons on phones), attack bar (tap anywhere), BACK button.
- Desktops and touchscreen laptops never get the joystick; they keep keyboard + drag-anywhere.
- Test on a desktop: debug panel (DBG) > "Toggle mobile controls", or set `TouchControls.mode = ALWAYS`.
  Mouse works because Emulate Touch From Mouse is on.
- Tuning: `battle/touch_joystick.tscn` (`joystick_size` is the **diameter**; `tip_size`, `deadzone_ratio`, mode
  Fixed / Dynamic / Following, and the four theme styleboxes for your own art). `TouchControls` node: `mode`
  (AUTO / ALWAYS / NEVER) and `joystick_on_right`.
- Project is set to sensor-landscape orientation. Android / iOS export presets are up to you.

## Merging into your main project
1. Copy `battle/`, `core/`, `data/` together (move them in Godot's FileSystem dock so references update).
2. No autoloads.
3. Global classes are prefixed to avoid collisions: BossBattle, BossEnemy, BossPhase, BossAttack, BossSpeech,
   BossSpeechBubble, BattleSoul, BattleBullet, BattleLaser, BattleBox, BattleMenu, BattleInput, BattleOption,
   BattleText, BattleChoiceList, BattleFightBar, BattleHud, BattleStats, BattleSkill, BattleDifficulty,
   BattleDifficultyMenu, BattleTouchControls, BattleDebugPanel, AssetSlot. Check your project for clashes.
4. `BattleInput` adds Z / X / WASD to the built-in `ui_*` actions only while a battle exists. Turn it off in its
   exports if your game already maps those keys.
5. If your main game already has its own phone controls, set `TouchControls.mode` to NEVER.
6. Mouse testing on a desktop needs Project Settings > Input Devices > Pointing > Emulate Touch From Mouse
   (on here). A real touchscreen needs nothing.

## Undertale placeholder layout (640x480)
Box 575x140 at (32, 250), bottom-anchored. HUD at y=394: name + LV, then HP + bar (1.2 px per HP) + numbers.
Buttons FIGHT/ACT/ITEM/MERCY at x = 32 / 185 / 345 / 500, y = 432, 110x42, heart at the left of the focused
button. ACT/ITEM lists use two columns. Speech bubble: white, rounded, tail pointing at the boss.
All art is an `AssetSlot` (drop a texture in, or add an AnimatedSprite2D child), so real assets replace placeholders
without touching code.

## Where things live
| What | Where |
|---|---|
| Boss stats / text | `battle/enemies/con_bug.tscn` root |
| Phases (HP thresholds, tint, texts) | `ConBug/Phases/PhaseN`; its children are that phase's attacks |
| Attacks | `battle/attacks/*.tscn`, overridable per instance |
| ACT / ITEM entries | `ConBug/Acts`, `Battle/Items` (`BattleOption` nodes) |
| Skills / difficulty presets | `data/skills`, `data/difficulty` (`.tres`) |

## Balance (Normal, untested guesses: tune with the debug panel)
- Round ~15-18 s. FIST ~28 per hit (perfect x1.5), POISON ~10 + 6 poison per turn. Boss 240 HP -> 3-5 minutes.
- Spare needs ~8 ACTs (mercy is limited by `uses`). Every death eases the next attempt (`assist_per_death`).

## Add content
- Attack: scene whose root script `extends BossAttack`; override `_on_start()` / `_on_stop()`; call
  `spawn_bullet(pos, velocity)`. Write numbers for Normal; difficulty scaling is automatic.
- Phase: add a `BossPhase` node under `Phases` and drop attack scenes under it.
- Difficulty / skill: duplicate a `.tres`, add its path to the menu / debug panel.

## Dialogue Manager 4.x (you use 4.1.0, for Godot 4.7)
`BossBattle` only calls `await speech.say(event, context, anchor)`. Events: `&"turn"`, `&"phase_enter"`,
`&"defeat"`, `&"spare"`; `context` = `{text, phase, turn}`. The placeholder `BossSpeechBubble` types `context.text`.
`battle/speech/dialogue_manager_speech.gd.example` + `con_bug.dialogue.example` are an uncompiled sketch of the
Dialogue Manager version (cues `turn_p1`, `phase_enter_p2`, `defeat`, `spare`...). A custom balloon can implement
`set_anchor(global_position)` to appear next to the boss.
