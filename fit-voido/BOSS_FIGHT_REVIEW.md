# CON BUG review — 7 November 2026

Subsequent implementation: the Spare story dead end identified here has been
resolved with an approved hidden ending. Both outcomes rescue the head; Spare
earns a separate ending badge rather than combat points. See `ENDING.md`.

## Scope and verdict

Reviewed the entry wrapper, development harness, boss controller, all six attack
implementations, three phases, skills, difficulty, player movement, damage,
healing, mercy, UI, retry assistance, scoring and story host. This is a source
review plus automated checks and rendered UI inspection, not a human playthrough
or a phone performance test.

The combat foundation is substantial: isolated physics, timing-based attacks,
six dodge patterns, phase transitions, limited healing, mobile controls and
retry assistance. The main remaining work is skill balance, clear story outcomes,
pause/onboarding and sound. It should not be considered release-balanced yet.

## Changes made

- Phase 1 uses `assets/Phase1.png`, phase 2 `assets/phase2.png`, phase 3
  `assets/phase3.png`. Per-phase textures and scale replace the tinted BUG box.
  Monochrome colours are preserved; the art fits above the text/dodge area.
- Removed character level from both player stats and the HUD. Difficulty remains.
- Victory points are `(1000 + round(1000 * final HP / max HP)) * multiplier`,
  rounded to an integer. Easy ×1, Normal ×1.5, Hard ×2. Full-health maxima are
  2,000 / 3,000 / 4,000. Half-health Normal earns 2,250. HP is sampled at victory
  from the winning attempt. Healing contributes to the remaining-health bonus.
- Spare earns zero victory points. Failed/spared replays cannot raise best score.
  Saves keep the maximum score, rather than accumulating a replay currency.
- The difficulty screen explains scoring; the main host shows the breakdown and
  best score, and the development harness reports HP and score.
- Fixed the difficulty screen's zero-size root under the Node2D battle. It now
  explicitly fills the 640×480 battle viewport, with space for score instructions.
- Debug controls now require explicit opt-in. The harness opts in; story launches
  do not. This prevents the normal editor-run game from offering heal/phase/skill
  cheats while recording points.

## Findings, in recommended order

### 1. High: Spare is a successful-looking dead end for the story

ACT can fill mercy and MERCY ends the fight as `spared`, but the main host counts
only `won()` as the rescue. The player is returned without Stone #4 after spending
several turns resolving the encounter peacefully. The current defeat-required
rule was preserved. Before release, either make this limitation explicit before
the fight, remove the peaceful route from story encounters, or approve Spare as
rescue while deciding its separate score rule.

Evidence: `boss_battle.gd::_do_mercy`, `BossFightResult.won`,
`scenes/UI/activity_host.gd::_on_boss_finished`.

### 2. High: FIST and POISON have very different exposure to danger

On Normal, a perfect FIST deals 60 against 240 HP: four attacks and normally three
dodge turns. A perfect POISON hit deals about 17 directly plus 6 at the following
enemy turn. Repeated perfect poison attacks therefore need about eleven player
turns and ten dodge turns. Reapplying poison refreshes three turns; it does not
stack the damage. POISON's wider timing window and 15% faster movement help, but
source numbers alone do not establish that these routes have comparable effort.

Recommendation: playtest both before tuning; consider stronger poison, fewer
required dodge turns, or an explicit defensive advantage. Do not compare raw
damage without counting damage-over-time and the number of enemy turns.

Evidence: `data/skills/*.tres`, `boss_enemy.gd::apply_poison/tick_poison`,
`boss_battle.gd::_do_fight/_enemy_turn`.

### 3. Medium: delayed bullets are dangerous during their visual warning

`BattleBullet` uses the damage collision layer while `start_delay` only fades the
visual and pauses movement. Breakpoint uses this delayed spawn. A player moving
into a waiting ring projectile can be hit before it launches. Lasers explicitly
disable their hit layer until activation, so the two warning systems differ.

Recommendation: decide whether waiting projectiles are hazardous. If they are
meant as safe telegraphs, disable their damage layer until the delay expires.
This behavior was identified by source inspection, not reproduced in a manual run.

### 4. Medium: no dedicated pause, limited first-time teaching

The fight has difficulty selection, retry and a main-host exit, but no equivalent
of Runner's pause flow. The introductory line simply announces CON BUG. Desktop
hints cover movement/confirm/cancel, but do not explain FIGHT timing, poison,
healing, mercy or telegraphs. Add a short skippable introduction and a pause screen
that freezes the isolated viewport without breaking retry timers or touch input.

### 5. Medium: music and SFX hooks exist, production audio is not assigned here

The wrapper supports music and forwards combat cues. Its default fight scene does
not assign music, and the shared host does not subscribe to those cues. Hits,
phase changes and warning/activation events need consistent audio feedback and
volume handling. The speech bubble remains the module's built-in bubble rather
than the campus Dialogue Manager style.

### 6. Medium: difficulty changes and assistance affect score comparability

Death assistance persists within one boss session, reducing attack damage, speed
and duration. It resets when the module is exited and relaunched. The new score
uses final HP and selected difficulty, without a death/assist penalty. This follows
the agreed rule, but assisted and unassisted scores can tie. That is acceptable
for a personal best; competitive leaderboards would need an additional policy.

### 7. Presentation and device polish

Boss art now changes visibly across all phases. Other art slots (heart, bullets,
arena and timing bar) still use the simple native visual system; that is not a
missing asset if the minimalist look is intentional. Menu labels and keyboard
hints mix English and Vietnamese. Verify 640×480 letterboxing in the 960×540
host and on actual phones, especially joystick overlap, text wrapping, touch
targets and input transitions after death. Current renders verify desktop art
placement only; they are not phone usability evidence.

## Verification

- `tests/boss_redesign_test.gd`: phase textures and size bounds, no LV HUD,
  difficulty score maxima, non-victory score, persisted best-score behavior.
- The same test with `-- render`: captures all three forms in the real battle UI.
- `tests/chapter4_test.gd`: prerequisites, saved skill choices, Spare versus
  victory, rescue dialogue, Stone #4, save/reload and duplicate prevention.
- `tests/activity_host_smoke.gd`: real module launches and return locations,
  using synthetic outcomes. It does not establish that every boss difficulty
  can be beaten by a human.

Recommended next work: settle Spare's story behavior, playtest FIST versus POISON,
then implement pause/onboarding and production audio. A human uninterrupted win
with each skill on each supported difficulty remains required before release.
