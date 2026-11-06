# FIT: The Time Stone — prioritized completion checklist

Based on the supplied full-journey proposal and the source review of 6 November 2026. The proposal defines the intended journey; this checklist distinguishes that intent from the implementation found in the repository. Completion boxes describe work still to verify or implement, not proof that every component is absent.

## P0 — Shared progression and one complete chapter

### 1. Establish the progression contract

- [ ] Represent four individually earned stones, selected skill (FIST/POISON), chapter progress, document possession/delivery, and ending completion in saved state.
- [ ] Define prerequisites for entering each required room/activity and provide useful locked-door feedback.
- [ ] Make rewards permanent and award each only once; replaying activities must not duplicate rewards or regress progress.
- [ ] Remember a safe return scene/location when entering a minigame.
- [ ] Connect minigame success to quest completion and saving; Continue returns to the host location.
- [ ] Handle invalid destinations with a visible Back/Retry route.

Done when: a result can update saved progression and return the player correctly, including after closing and reopening the game.

### 2. Finish Chapter 1 end to end

- [ ] Connect the 2006 → 2026 arrival and Minh conversation to the actual starting route.
- [ ] Teach actual movement and interaction through a short playable introduction.
- [ ] Place the lecturer at Nhà C and connect the two-activity choice.
- [ ] Replace Runner's Nathan sample dialogue and repair its launch destination.
- [ ] Launch Trash Train through a host that records results and handles return.
- [ ] Complete either activity → return to lecturer → award Stone #1 → unlock Nhà C/Room 417.
- [ ] Allow retry, return to campus, and switching the chosen activity without losing progress.

Done when: both choices work independently from a clean save and lead to the same saved unlock.

## P1 — Complete the required story in order

### 3. Chapter 2: Room 417, seating choice, and FIT Quiz

- [ ] Make Room 417 accessible after Stone #1.
- [ ] Stage Human Students at the front and Snake Students at the back; make the seating choice understandable.
- [ ] Persist FIST or POISON from that choice and show confirmation.
- [ ] Finalize 5–7 questions covering FIT history, teacher recognition/tributes, and student experience.
- [ ] Supply approved teacher images and verify answers with the project owner.
- [ ] Require all answers correct, as specified in the proposal. A failed attempt must offer an explanation and retry, not permanently mark the chapter passed.
- [ ] Award Stone #2 once and direct the player toward Room 416.

Done when: both seating choices survive a restart and a perfect quiz result unlocks Chapter 3.

### 4. Chapter 3: teacher search and document chain

- [ ] Room 416: implement a four-digit keypad, the FIT founding-year clue, incorrect-answer feedback, and persistent door unlock.
- [ ] Rescue Teacher 1 and deliver the hint directing the player to Room 419.
- [ ] Room 419: Teacher 2 assigns the search for the marathon-shirt teacher at the sports ground.
- [ ] Sports ground: provide student runners and a recognizable marathon-shirt teacher.
- [ ] Connect the Yes/No verification sequence; correct completion grants the document once.
- [ ] Track document possession and provide a clear destination: Teacher 3 near the faculty/head's office area.
- [ ] Deliver the document → award Stone #3 → trigger the disturbance and boss-room objective.
- [ ] Add useful repeat dialogue at every step so returning players can recover their objective.

Done when: the entire chain works in order, cannot be skipped accidentally, and resumes correctly after restarting at each handoff.

### 5. Chapter 4: rescue and boss reward

- [ ] Repair the battle NPC's missing destination and launch the existing CON BUG module through a host.
- [ ] Read the saved Chapter 2 skill and pass it to the fight.
- [ ] Stage the attack on the faculty head and explain the combat controls.
- [ ] Support retry, difficulty selection, and returning safely after abandoning the fight.
- [ ] Boss victory → rescue dialogue → award Stone #4 once → direct the player to Văn phòng Khoa.
- [ ] Decide and document whether the implemented Spare outcome also counts as rescue; the proposal only specifies defeating the boss.

Done when: both FIST and POISON can complete the chapter and produce the same required story progression.

### 6. Final: Time Gate and return to 2006

- [ ] Build the four-slot gate at Văn phòng Khoa.
- [ ] Check actual stone ownership; show useful feedback if a stone is missing.
- [ ] Allow placing each owned stone in its matching slot and persist placement if the sequence is interruptible.
- [ ] Activate the gate only after all four slots are filled.
- [ ] Show the light transition, “20 NĂM FIT – HÀNH TRÌNH ĐƯỢC VIẾT NÊN BỞI CHÚNG TA”, and the 2006 ending image/scene.
- [ ] Save ending completion; provide credits and a deliberate return-to-menu/replay choice.

Done when: a fresh save can reach the ending through normal gameplay with no developer intervention.

## P2 — Make the whole journey clear and reliable

- [ ] Add a production objective panel and four-stone display; the tutorial mock HUD is not sufficient.
- [ ] Give required rooms, stairs, sports ground, and offices readable signs and recognizable entrances.
- [ ] Fix campus doorway signal handling and test all required travel in both directions.
- [ ] Make advertised arrows, sprint, Space interaction, and controller interaction work, or remove unsupported promises consistently.
- [ ] Provide pause, retry, continue, and exit across all activities; support keyboard focus and intended touch/controller inputs.
- [ ] Add New Game/Continue behavior and safe resume locations; save assistance counters and activity results where needed.
- [ ] Replace placeholder text, align Vietnamese terminology, review jokes, and standardize UI/audio behavior.
- [ ] Keep mandatory historical clues discoverable before testing them.

Done when: a first-time player can navigate the full journey without external instructions or becoming stuck.

## P3 — Balance, presentation, and release

- [ ] Playtest both Chapter 1 routes with new players and compare pass rates, duration, and attempts to success.
- [ ] Test the current Runner checkpoint/stamina model rather than relying on older README simulation results.
- [ ] Tune Trash Train scoring, ten-NPC scene setup, tail loss, banking clarity, and timeout warning from observation.
- [ ] Test both boss skills, every supported difficulty, telegraph readability, and the chosen victory/Spare rule.
- [ ] Inspect phone readability, touch occlusion, keyboard navigation, scaling, audio levels, and supported-device performance.
- [ ] Test a complete exported build from a clean save; restart after every stone and during each Chapter 3 handoff.
- [ ] Test replay rewards, failed quizzes, abandoning activities, failed loading, and interrupted ending sequences.
- [ ] Include required art, teacher-image permissions, credits, and asset licenses.

Done when: the exported game completes the entire required story reliably on every declared supported platform.

## Decisions to settle before implementing affected content

| Proposal | Current implementation | Decision needed |
|---|---|---|
| Runner: 2–3 campus laps with obstruction | Separate stamina-pacing course with checkpoint timing | Keep the current module and revise the narrative, or implement actual laps. Recommended minimum scope: keep pacing and make its course represent the campus run. |
| Garbage Quest: bring trash to an NPC | Timed collection and banking into bins | Keep bin scoring, then return to the lecturer to claim the story reward; update instructions accordingly. |
| FIST short range; POISON longer range | Timing-based attacks, damage-over-time, and dodge-speed differences | Keep the existing combat model and describe skills truthfully, or expand combat to implement range. Recommended minimum scope: keep the current model. |
| Boss must be defeated | Module also supports Spare | Choose whether both outcomes rescue the head and earn Stone #4. |
| Three-teacher search | Includes an additional marathon teacher intermediary | Identify each teacher and exact room/position so dialogue, portraits, and objectives stay consistent. |

These recommendations preserve the journey while limiting new systems. They are proposed scope choices, not changes already approved or implemented.

## Defer until the required journey ships

Achievements, leaderboards, optional memory collectibles, the digital museum, extra minigames, and additional branching endings. These are extensions in the proposal and are not required for the four-stone ending.

## Immediate working order

1. Shared saved progression and activity host/return flow.
2. Both Chapter 1 routes through saved Stone #1 and Room 417 unlock.
3. Chapter 2 seating, saved skill, perfect-score quiz, and Stone #2.
4. Chapter 3 room puzzle, teacher search, document delivery, and Stone #3.
5. Boss integration, saved skill, rescue, and Stone #4.
6. Four-slot gate, ending, credits, and ending save.
7. Whole-journey usability, balance, and exported-build verification.
