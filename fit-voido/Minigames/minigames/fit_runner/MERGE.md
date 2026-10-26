# Merging FIT Runner into the main game

The module is one folder, `minigames/fit_runner/`. Nothing outside it is needed or touched: no autoload, no project setting, no
input binding of yours, no locale change, and your camera is handed back when it leaves.

## 1. Copy it in
- Copy `minigames/fit_runner/` into your project at the **same path**. Scenes and resources store absolute `res://` paths, so a different
  location needs one extra step: move the folder inside the Godot FileSystem dock (Godot fixes the references), or move it anywhere and run
  `python tools/relocate.py res://your/path/fit_runner`.
- Open the project in Godot 4.4 once. It imports the PNGs and the font. Look at the Output panel and send me the first error if there is one.
- Commit the `.uid` and `.import` files Godot creates, the way your repo handles the rest.

## 2. Check for clashes
`python minigames/fit_runner/tools/check_conflicts.py /path/to/your/project`
Every internal class starts with `Fr` (`FrHud`, `FrModel`...). The public ones are `FitRunner`, `FitRunnerConfig`, `FitRunnerResult`,
`FitRunnerLauncher` and `FitRunnerStrings`. Translation keys start with `FR_`, the input action is `fr_push`.

## 3. Launch it
```gdscript
var config := FitRunnerConfig.new()          # optional, every field has a default
config.attempt = attempt_number              # 1, 2, 3...
config.assist_level = 1 if attempt_number > 3 else 0   # a little help after repeated fails
var game: FitRunner = FitRunnerLauncher.create(config)  # create() lets you connect first; launch(parent, config) also adds it
game.run_finished.connect(_on_run_finished)
game.quit_requested.connect(_on_quit_requested)
add_child(game)
```
```gdscript
func _on_run_finished(r: FitRunnerResult) -> void:
    if r.passed:
        award_time_stone(1)     # r.stars 1-3, r.time_sec, r.walls_hit, r.attempt, r.par_time, r.qte_perfect / qte_good / qte_miss
    # failed: nothing to do, the Retry button runs the next attempt inside the minigame

func _on_quit_requested() -> void:   # Continue / Quit was pressed
    game.queue_free()                # your camera comes back automatically; then continue your level flow
```
`dev/example_level1.gd` has the same flow for a Level 1 minigame menu. If you want to control the start (a cutscene first), set
`config.autostart = false` and call `game.start()` yourself.

## 4. What the module expects from your game
| Topic | Detail |
|---|---|
| Godot | 4.4, GDScript only. Compatibility renderer works (the web export needs it). |
| Screen | Landscape, designed on a 640x360 canvas. It reads the viewport size, so other 16:9 sizes work, but the art is authored at 640x360. |
| Project settings | None required. Keep *Input Devices > Pointing > Emulate Mouse From Touch* on (default) so a phone tap is the push input. |
| Input | One action, `fr_push`, created at runtime (Space + left mouse) if you have not defined it. Define it in your Input Map first to use your own keys, or set `config.push_action` to an action you already have. Esc / P pause; turn off with `config.pause_keys_enabled = false`. |
| Language | Registers its own translations (vi, en) at launch and uses whatever locale your game set. Another language: add a block to `scripts/api/fit_runner_strings.gd`. |
| Theme | The module's theme is assigned to its own HUD and labels only. Your project theme is untouched. Swap `assets/ui/fit_theme.tres` to match your look. |
| Camera | Has its own `Camera2D`, made current on start. The previously current camera is restored when the node leaves the tree. |
| Canvas layers | -10 (sky), 10 (HUD), 20 (debug, removed unless `debug_enabled`). Change them in `fit_runner.tscn` and `scenes/ui/hud.tscn` if they collide with yours. |
| Pausing | Runs in `_process` with a fixed 60 Hz simulation, so pausing the tree pauses it. It also pauses itself on focus loss and in portrait. |
| Side effects | No saves, no files, no network. The debug overlay's "Copy log" writes to the clipboard, and it only exists when `debug_enabled` is true. |

## 5. Difficulty per level
Make a `FitRunnerConfig` resource per level (New Resource > FitRunnerConfig) and set `tuning` (`FrTuning`: speed, stamina, wall, water, spurt,
hills) and `qte` (`FrQteSettings`: presets in `resources/qte_*.tres`). The debug overlay (`debug_enabled = true`, F1 or DBG) edits both live;
"Copy log" exports the numbers and a per-event log for playtests.

## 6. Check list before you ship
- [ ] Output panel clean after the first import.
- [ ] `check_conflicts.py` reports no problems.
- [ ] Plays on desktop (Space / mouse) and on a phone (touch anywhere); a tap during the QTE bar is judged, a long hold runs.
- [ ] The camera of your game is back after `queue_free()`.
- [ ] Language switch in your game changes the minigame text (keys `FR_*`).
- [ ] Your logo: overwrite `assets/branding/fit_logo.png`. Your character and UI art: see `assets/README.md`.
- [ ] `debug_enabled` is false in the real config.
- [ ] Web build: Thread Support off (single-threaded is the default from 4.3 as far as I know, check the export docs), tested on an iPhone.

## 7. Removing it
Delete the folder. Nothing else references it.
