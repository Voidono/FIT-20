# boss_fight: CON BUG boss battle module (Godot 4.7)

A self-contained Undertale-style boss fight. Copy this one folder into your project. It needs no autoloads, no
Project Settings and no Input Map edits.

## Merge in 3 steps
1. Copy `boss_fight/` into your project's `res://`. Moving it later in the FileSystem dock is safe: nothing in it
   uses string paths (skills and difficulties are child nodes, scenes are references).
2. Start the fight from your game code:
```gdscript
const BOSS_FIGHT := preload("res://boss_fight/boss_fight.tscn")

var config := BossFightConfig.new()
config.skill_id = &"poison"              # decided by the earlier part of your game ("fist" / "poison")
# config.difficulty_id = &"easy"         # leave empty and the player gets the difficulty menu

var fight := BOSS_FIGHT.instantiate() as BossFight
fight.config = config
some_canvas_layer.add_child(fight)       # fills its parent. Put it on a CanvasLayer above your UI.
var result: BossFightResult = await fight.finished
if result.spared(): ...                  # result.outcome (&"win"/&"spared"), .deaths, .seconds, .skill, .difficulty
```
3. `dev_harness/` is optional: open `dev_harness/harness.tscn` in your project and press F6 to try the fight (it plays the
   role of your game). Delete the folder when you no longer need it.

## What it touches in your project
| Thing | Behaviour |
|---|---|
| Autoloads, Project Settings | none needed (for phone exports, set landscape orientation yourself: Project Settings > Display > Window > Handheld) |
| Input Map | while a fight exists, adds Z / X / WASD to `ui_accept` / `ui_cancel` / `ui_*` and removes exactly those again afterwards (`BattleInput` exports turn it off) |
| Physics | its own `World2D`, plus layer 32 for bullets, so it cannot touch your game's physics |
| Groups | only `boss_fight` (on the BossFight node) |
| Canvas layers | all inside its own viewport, so they cannot clash with yours |
| Global classes | prefixed: BossFight, BossFightConfig, BossFightResult, BossBattle, BossEnemy, BossPhase, BossAttack, BossSpeech, BossSpeechBubble, Battle* (Soul, Bullet, Laser, Box, Menu, Hud, Stats, Text, ChoiceList, FightBar, Option, Skill, Difficulty, DifficultyMenu, TouchControls, DebugPanel, Input), BattleResourceRef, AssetSlot. Check for clashes. |
| Theme | your project-wide custom theme (Project Settings > GUI > Theme) still applies to its Buttons and Labels |

## How it fits into any host
`BossFight` renders the 640x480 fight in its own `SubViewport` and scales it to the space it is given (whole-number
scale when 2x or more, nearest filtering, black letterbox). The host's resolution and stretch mode do not matter.
- While it is on screen, hide or disable your own UI and take focus away from it: the fight reads `ui_*` keys too.
- Your game may pause itself behind the fight: it keeps running while the tree is paused (`run_while_tree_paused`).
- `fight.game_to_screen(pos)` converts a fight position to your canvas space.
- Add it to a plain Node2D/Node instead of a Control if you like: it still fills the viewport.
- Test the fight alone by running `boss_fight/battle/boss_battle.tscn` (F6).

## Cues (SFX / music hooks)
`BossFight.cue(cue_name, data)` is emitted for: `fight_started`, `menu_move`, `menu_confirm`, `bar_stopped` {accuracy},
`enemy_hit` {damage, perfect}, `enemy_miss`, `enemy_poison` {damage}, `phase_changed` {phase}, `attack_started` {name},
`attack_ended`, `player_hit` {damage, hp}, `player_heal` {amount}, `player_died`, `enemy_defeated`, `spared`.
Connect it to your audio manager. Text blips: add an `AudioStreamPlayer` named `Blip` under a `BattleText` node.
Fight music: set `BossFight.music` (bus on its `Music` node).

## Skills and difficulty (no string paths)
They live as child nodes of `BossBattle/Library` in `battle/boss_battle.tscn` (`BattleResourceRef` nodes pointing at the
`.tres` files in `data/`). To add one, duplicate a `.tres`, add a `BattleResourceRef` node, drag the resource in.
Look-up is by the resource's `id`. The player's difficulty menu and the debug panel list whatever is in the Library.

## Boss content
- Boss: `boss/enemies/con_bug.tscn` (stats, texts). Another boss = another scene with a `BossEnemy` root, passed as
  `BossFightConfig.enemy_scene`.
- Phases: `BossPhase` nodes under `Phases` (HP threshold, tint, texts). Their children are that phase's attacks.
- Attacks: `boss/attacks/*.tscn`. New one: scene whose root script `extends BossAttack`, override `_on_start()` /
  `_on_stop()`, call `spawn_bullet(pos, velocity)`. Write numbers for Normal; difficulty scaling is automatic.
- ACT / ITEM entries: `BattleOption` nodes under `Acts` (boss) and `Items` (battle).
- All art is an `AssetSlot` node: set a texture, or add an AnimatedSprite2D child. Fonts: set the project / theme font.

## Phones
On native Android / iOS (and web exports on them) a big `VirtualJoystick` appears only while dodging; elsewhere
keyboard, mouse drag and touch drag work. Size and look: `battle/battle_touch_joystick.tscn`. Switch with the
`TouchControls` node (`mode`, `joystick_on_right`). The mouse can only drive the joystick on desktop when your
project has "Emulate Touch From Mouse" on (everything else works without it).

## Dialogue Manager 4.x
The battle only calls `await speech.say(event, context, anchor)` on the `Speech` node (`BossSpeech`). The default is a
placeholder bubble. `boss/speech/dialogue_manager_speech.gd.example` plus `con_bug.dialogue.example` sketch a Dialogue
Manager adapter (cues `turn_p1`, `phase_enter_p2`, `defeat`, `spare`...). It is untested because the addon is not in
this project. Your balloon's CanvasLayer must be above the one BossFight sits on.

## Debug
`BattleDebugPanel` (F1 or the DBG button) exists only in debug builds: switch difficulty / skill, jump to a phase, fill
mercy, heal, toggle phone controls.
