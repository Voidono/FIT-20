# FIT Runner: Campus Circuit

## Venue and camera

A flat, two-lap, 1 km field circuit inspired by the supplied campus field reference: four football pitches, striped green turf, pale markings, charcoal running lanes, trees, fencing and spectators. The close race camera unfolds the circuit into a side view; the rounded rectangular overview communicates the physical route and lap progress. It is a stylized circuit rather than a survey of the real field's dimensions.

The field artwork is native Godot drawing in `scripts/course/field_circuit.gd`, so it stays editable and sharp without introducing generated image dependencies. The overview is `scripts/ui/circuit_map.gd`. Existing runner sprites and checkpoint prop scenes are retained.

## Story integration

Chapter 1 launches activity `fit_runner` in locked Practice mode. A pass completes
the Chapter 1 challenge; the Nhà C lecturer still awards Stone #1.

Chapter 3 launches `fit_runner_race` in locked Ghost Race mode from Thầy Tuấn at
the sports ground. The Room 419 lead and his three-question identity quiz are
prerequisites. A podium finish activates return-to-Tuấn; his conversation grants
`marathon_documents` once and starts the delivery objective. The document recipient
and Stone #3 handover remain separate Chapter 3 content.

The two activity IDs have independent attempts, assistance and saved completion.
Story results cannot be credited to the other mode. Standalone launches retain
the mode selector. Campus return uses the existing shared activity host.

The race view uses concrete paving and perimeter fencing to match the campus map.

## Two modes, shared mechanics

| | Practice | Ghost Race |
|---|---|---|
| Field | Player + optional pace guide | Player + five ghost rivals |
| Goal | Finish before the generous cutoff | Finish within the cutoff and place in the top three |
| Assistance | Contextual coaching, wider/slower timing windows | Standard timing windows, live placement |
| Cutoff | At least 2x par | Tuning's cutoff multiplier, default 1.5x par |
| Stars | Existing time-relative thresholds | First: 3, second: 2, third: 1, otherwise: 0 |

Stamina drain, easing-off recovery, acceleration, course length, checkpoint rewards, and final-spurt behavior are shared. Easing off restores stamina, including after exhaustion; continuing to push at exhaustion prevents recovery. Four checkpoint events occur at 12.5%, 37.5%, 62.5%, and 87.5% (two bends per lap). The final spurt remains automatic in the last 15%, with the player choosing how much effort to apply.

Rivals simulate the same stamina/effort model in advance. Their plans favor early aggression, steady pacing, a late kick, caution, or chasing. Each has a deterministic mix of GOOD and PERFECT checkpoints. They do not teleport, scale their speed to the player, or gain hidden rubber-banding. All racers share simulation time, including QTE slowdown and pauses. Lane offsets are visual; there is no collision or lane steering.

## Controls

- Push: hold Space, W, Up, left mouse, or the mobile RUN button.
- Recover: release push and allow effort to fall.
- Checkpoint: Enter, J, K, Down, or the mobile checkpoint button.
- Pause: Esc, P, or pause button. Quit returns through the host's existing signal.
- Choose mode: ready-screen tabs; after a race, Choose mode returns to the briefing.

Practice can be replayed or skipped; competition is not locked behind a tutorial flag. Existing story progression is retained: either a successful practice finish or a race podium is reported as `passed`. The module no longer claims to award a Time Stone itself; the host owns rewards and persistence.

## API

```gdscript
var config := FitRunnerConfig.new()
config.race_mode = FitRunnerConfig.RaceMode.COMPETITION # default: PRACTICE
var runner := FitRunnerLauncher.create(config)
runner.run_finished.connect(on_result)
runner.quit_requested.connect(on_quit)
add_child(runner)
```

Results retain existing fields and add `race_mode`, `completed`, `placement`, and `entrants`. `completed` distinguishes crossing the line from timing out; `passed` is the mode's success condition. Exact finish times determine final placement, with simultaneous finishes sharing a placement. The practice guide does not count as a competitor.

## Verification

From the project root:

```text
godot --headless --path . --script res://tests/fit_runner_modes_test.gd
godot --headless --path . --script res://tests/activity_host_smoke.gd
godot --path . --rendering-method gl_compatibility --script res://tests/fit_runner_preview.gd -- --out=ABSOLUTE_OUTPUT_DIRECTORY
```

The mode test runs full races, checks a GOOD-input podium, checkpoint counts, results, timeouts, non-podium finishes, retries, mode switching, pause and exhaustion recovery. The renderer captures the real ready, running, checkpoint, result, Vietnamese, small-screen and touch layouts. The host smoke test uses disposable save data and validates campus returns.
