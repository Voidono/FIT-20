# First playtest: turning guesses into numbers

Almost every number in `tuning.gd` is a guess. This is a short plan (one afternoon) to replace the important ones with data.
FIT Runner should get the same treatment with the same testers, so you can check that neither option is the obvious easy pick.

## Set up
1. Build for phone web and for PC. Use the sample yard first, then your own map.
2. On the `TrashTrain` root set **Rng Seed** to any non-zero number (say 2026). Every tester then starts with the same items.
3. Leave **Log Runs** on. Each attempt is appended to `user://trash_train_runs.csv`
   (PC: Godot's *Project -> Open User Data Folder*). On a phone you cannot read it easily, so the observer copies the numbers
   from the result screen onto paper.

## Who and how
* 6 to 8 testers: at least 3 on a phone, 2 on PC, 2 who have never seen the game.
* About 10 minutes each: **3 timed attempts**, then 3 questions. The observer stays silent and does not explain the controls:
  what the screen says is all they get.
* Watch for: where the finger hides the runner, whether they find both bins, the moment they stop understanding something,
  and whether they ask to play again.

| Tester | Device | Mode (A/B) | Attempt | Passed | Stars | Score | Bumps | Not banked | Hesitated at... |
|---|---|---|---|---|---|---|---|---|---|

Questions: *Was it clear what to do? What annoyed you most? Would you play again for 3 stars?*

## Set `good_run_score` first
It decides the pass line (33%) and the stars (66%, 100%). Have 2 or 3 people who know the game play 5 practice runs, then 3
scored runs each. Take each person's best, take the median of those, and put it in `good_run_score`.
(For scale: a simple bot banks about 100 in 60 s on the sample yard, but a bot is not a person.)

## Read the results
| You see | Try |
|---|---|
| Fewer than half of the newcomers pass within 2 attempts | lower `pass_ratio` (0.25), lengthen `run_duration` toward 90, or use fewer NPCs |
| Most newcomers pass first time with 2 or 3 stars | raise `good_run_score` |
| Median bumps 5 or more | slower `npc_speed`, longer `bump_invulnerability`, fewer NPCs, smaller NPC hit areas |
| Big "not banked" at time-up (over a fifth of the score) | the clock is cutting trips: lengthen it, or add an auto-bank at the end |
| Nobody uses the second bin, or they look confused | set one bin's `accepts` to empty (a single catch-all bin) and compare |
| Everyone runs a full 12-item tail every trip | compare `tail_cap` 12 against 8 and against 0 (unlimited) |
| Fingers hide the runner in mode A on phones | make mode B the touch default |
| Pass rate on this minigame is far from FIT Runner's | move `pass_ratio` or `run_duration` until they feel alike |

Change one thing at a time and re-run the same three attempts. Write the winning values back into `tuning.gd`.
