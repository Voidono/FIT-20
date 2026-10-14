# FIT Runner (starter) - Godot 4.4, GDScript only

Baseline for the **FIT Runner** minigame in *FIT: THE TIME STONE*. Hold to push, release to recover. One input
feeds one effort value (0-1); pace, stamina, the par ghost and the HUD all hang off it. Placeholder shapes, no audio,
Vietnamese + English strings, landscape 16:9 on a 640x360 canvas.

## Read this first
- **Nobody has pressed F5 on this yet.** I built it where there is no Godot. The stamina model was checked in a Python
  mirror (numbers below) and the scripts were linted for syntax, but expect to fix a typo or two. Open it in 4.4, look at
  the Output panel, and send me the first error.
- Open the project in the editor once before anything else: it imports the font and registers the `class_name`s.

## Run
1. Godot 4.4 -> Import -> `project.godot` -> F5. Main scene is `scenes/main.tscn` (a stand-in for the main game).
2. Controls: hold **Space** or **left mouse** or **touch anywhere**. **Esc / P** pauses. **F1** or the **DBG** button opens
   the tuning overlay. Tap to start, 3-2-1, run.
3. Phones: keep *Input Devices > Pointing > Emulate Mouse From Touch* on (default). A tap arrives as a left click.

## Scene tree (`scenes/fit_runner.tscn`)
```
FitRunner (Node2D, fit_runner.gd)      emits run_finished(result), quit_requested
+- World (Node2D)                      scrolled by hand, no Camera2D, so it never fights the main game's camera
|  +- CourseView (course_view.gd)      sky, hills, ground that follows the profile, signs, finish arch
|  +- GhostView  (runner_view.gd)      translucent par runner
|  +- RunnerView (runner_view.gd)
+- Hud (CanvasLayer 10, hud.gd)        everything readable sits in the centre 60%
+- DebugOverlay (CanvasLayer 20)       readouts + live sliders
```

## Hooking it into the main game
```gdscript
var game := preload("res://scenes/fit_runner.tscn").instantiate() as FitRunner
add_child(game)
game.run_finished.connect(func(r: RunResult) -> void:
    if r.passed: award_time_stone(1)           # r.stars, r.time_sec, r.walls_hit, r.attempt, r.par_time
)
game.quit_requested.connect(go_back)           # the main game owns scene changes
game.start({"attempt": 1, "assist": 0})        # optional; _ready() already starts a run
```
`push` is registered in code if it does not exist, so merging needs no Project Settings changes. `main.gd` shows the
window scaling (canvas_items + keep, 640x360 up to about 18.4:9, bars beyond that). Copy `_update_scale()` if the main game
does not already scale.

## Tuning
Everything is in `scripts/runner_tuning.gd` (a Resource, groups in the Inspector). Create a `.tres` from it, assign it
to `FitRunner.tuning`, or just use the overlay: sliders change the live values; track length, mode and presets restart the
run so par is rebuilt. **Copy log** puts a CSV of effort/stamina/pace every 0.5 s plus all tuning values on the clipboard
(check it works in the itch.io build on an iPhone).

## The two input schemes (open question A vs B)
Both only produce `effort`. Switch live in the overlay.
- **A hold/release**: effort rises while held, falls on release (never below a slow jog), and moves slowly inside the cruise
  band so feathering sticks. The band is stickier early and less so later.
- **B tiers**: hold 0.55 s to climb a tier (0.30 / 0.60 / 0.80 / 1.00), let go 0.50 s to drop one. Short taps leave the tier alone.
- A third scheme (alternating taps): subclass `EffortInput`, add it to `EffortFactory`. Nothing else changes.

## Defaults I applied (the ones you approved)
- Water: **let go inside the zone** to take the cup (+15 stamina, 1.6 s slowdown). Keep holding to skip.
- Wall: at 0 stamina pace is capped at 45% until stamina is back to 35. While walled, **holding stops recovery**; let go to recover.
- Drain is a **smooth curve** through your four tier numbers (anchors at pace 0.25 / 0.60 / 0.80 / 0.95), not four steps.
- Hills change ground speed for free; uphill also drains more. Final spurt (last 15%): pace cap 1.12, drain x0.6.
- Par and ghost come from a **par bot** that plays the same model with the same input scheme. 1 star = finish before par x1.5,
  2 stars = par x1.25, 3 stars = par x1.05. Two walls quietly cut drain 10%.
- HUD: colour + hatch + glyph + name for zones, effort gauge with the cruise band, "enough to finish" indicator (a copy of the
  model runs ahead at your recent average effort), +/- seconds against par, whole-course strip with elevation.
- Auto-pause on focus loss and in portrait ("rotate your phone"). Fixed 60 Hz simulation: same run, same time, any device.

## Numbers: what the model says (`tools/strategy_sim.gd` should print the same; if it is far off, tell me)
| | A hold/release | B tiers |
|---|---|---|
| par bot = ghost | 95.4 s, 1 wall | 97.1 s, 1 wall |
| steady 0.62 effort + full spurt | 97.8 s | 106.3 s |
| mash, lets go at the wall | 123.0 s (+29%) | 121.7 s (+25%) |
| mash, never releases | 126.1 s | 126.3 s |
| cutoff (par x1.5) | 143.2 s | 145.7 s |

- **I changed two of your numbers.** Sprint drain -5 -> **-8** and wall exit 25 -> **35**. With your originals the masher is only
  ~6% slower than steady pacing in A, and in B mashing *wins* by ~6%. With the new values pacing is worth about 25%.
  Overlay -> **Your numbers** restores the originals in one tap.
- Strongest levers on time, from re-optimised bots: final spurt about 5 s, water about 3 s, hill about 2 s, slope-aware effort
  about 1 s. Hills are the weakest lever; raise `uphill_*` / `downhill_*` or the hill height in `course_points` if you want them to matter.
- Even a player who never lets go at the wall still passes (126 s < 143 s). Nobody is locked out.

## Web export (itch.io)
Compatibility renderer is already set. Leave **Thread Support off** (single-threaded export is the default from 4.3 as far as I
know - check the Web export docs); then no special headers are needed. Test on a real iPhone: touch hold, auto-pause when you
switch tabs, clipboard copy, and that the page does not scroll or zoom while you hold.

## You still need to give me
- `assets/branding/fit_logo.png` (finish arch, ready and result screens pick it up automatically).
- The storyline text. `STORY_READY` in `scripts/strings.gd` is a placeholder. Please review all the Vietnamese.
- Font: DejaVu Sans Bold subset (free licence, in `assets/fonts`) covers every Vietnamese letter and the symbols used. Poppins, a
  common game font, does **not** have Vietnamese stacked marks. Keep the diacritics test line in the overlay when you swap fonts.

## Not in this baseline
Audio (browsers need a tap first, you have one), pixel art, leaderboard, Time Stone Surge, drafting, start-line boost, a
proper tutorial (only the READY text and in-run prompts), screen shake (so reduced-motion has nothing to disable yet).

## Plan to 26 Oct
- Oct 13-14: open, fix errors, run on desktop, export to itch.io (draft page) and run on 2 phones.
- Oct 15-17: A vs B with 4-6 people (2 runs each, alternate the order, send me the logs). Pick one.
- Oct 18-20: tune from the logs: pass rate, walls per run, stars. Set 3 stars where about 12% of second attempts land.
- Oct 21-23: logo, storyline, Vietnamese review, pixel art swap, polish. Second playtest.
- Oct 24-25: integrate `run_finished`, buffer. Cut order if late: leaderboard, ghost, Marathon Master, simplify water.
