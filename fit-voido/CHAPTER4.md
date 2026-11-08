# Chapter 4: Room 210 entrance and rescue

The hallway 210 doors now enter `scenes/mapsides/phòng210.tscn`. The user's room
art, corner position for thầy Thắng, and CON BUG sprite are used directly.
Three stones and the saved room-417 skill remain the story prerequisites.
Room 419 has its own talking-door scene, so its Chapter 3 clue is unaffected.
The outdoor Nhà C lecturer is now thầy Tùng. Thắng appears only inside office 210.

On first entry, the room camera frames the office and movement is locked. CON
BUG rushes around the floor while thầy Thắng shakes and panics in the corner.
The existing pixel dialogue bubble opens automatically. Lines advance after a
reading delay, and the player can tap or press Enter to advance sooner.
The cutscene contains no fight/leave choice. Once it finishes, the intro-seen
flag is saved and the boss module opens directly at difficulty selection.
Its pause menu still has the full how-to-play guide.

The battle checkpoint is inside the office. After victory or Spare, returning
plays the rescue automatically and awards Stone 4 through the existing guarded
reward method. The room settles, thầy Thắng leaves the corner, and a spared
CON BUG remains small and friendly. Talking to thầy Thắng opens the Time Gate
or lets the player stay. The normal and hidden endings are preserved.

Backing out or returning without victory allows free movement in the office.
Interacting with thầy Thắng or CON BUG plays a short retry lead-in and launches
the fight. The full introduction does not repeat and there is no automatic
retry loop. The lower door returns to the hallway position used to enter.
That session-local hallway return is separate from the saved boss checkpoint.
The Time Gate's back button also returns inside the office.

Overlapping opposing hallway door ranges are resolved by proximity when E is
pressed. This prevents an adjacent classroom from taking the office-door input.
No hallway geometry, door positions, or duplicated door layout was changed.

Implementation:
- `scenes/chapters/office210.gd`: cinematic, automatic line timing, rampage,
  panic, rescue, retry and exit.
- `office210_entrance.gd`: gated hallway entrance.
- `Dialogues/office210.dialogue`: new Vietnamese scene and handoffs.
- `room419_talking_door.tscn`: independent Chapter 3 door.
- `scene_loader.gd`: separate hallway return and closest-door selection.

Verification: `tests/office210_flow_test.gd` exercises entry, automatic launch,
win/Spare rescue and both endings through the teacher, retry, backing out,
collision-free arrival and same-hallway return. The Chapter 3 room tests and
quest-waypoint tests cover the unaffected clue chain and updated routing.
Screenshots are saved as `tests/office210_intro.png`, `office210_rescued.png`
and `office210_spared.png` when passing `-- render`.
