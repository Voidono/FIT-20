# Reconnected rooms and hallway plaques

The current map geometry, stair placements, nested door structure, duplicate
classroom/boss links and classroom return position `(2723, 300)` are preserved.

Floor 4 now has:

- `SceneDoor`, at `(2723, 345)`: Room 417 entrance, Chapter 2 gate, existing
  classroom interior and arrival `(567, 614)`.
- `SceneDoor2`, at `(3100, 135)`: existing Room 416 keypad and trapped-lecturer
  sequence. Entering 2006 unlocks the rescue and next clue.
- `Room419Door`, beside the existing artwork at `(2860, 449)`: closed-door
  conversation that sends the player to Thầy Tuấn. No interior is needed.

Waypoints now find the nested stairs and canonical doors recursively. The 416
and 419 objectives point to their own interactions, and the 417 route points to
the reconnected floor-4 classroom door. Quest markers sit above the room plaques.

The reference-inspired signs are original native Godot artwork: a white panel,
small navy room description and a blue number tab. They stay attached to the
door when it moves. Floors 2 and 3 each have 16 numbered plaques; floor 4 has
416, 417 and 419. The canonical faculty office is 210 on floor 2. Existing
duplicated door behaviors are retained; the signs identify their map locations.

Open the door's `RoomNumberSign` child and edit `room_number`, `room_title` or
`subtitle` in the Inspector. The reusable template is
`scenes/templates/room_sign.tscn`; drawing is in `room_sign.gd`.

Checks: `reconnected_rooms_test.gd` exercises the actual 416 hint/keypad/rescue,
419 handoff, classroom entrance and sign counts. `quest_waypoint_test.gd`
checks every story target on all maps. Stair and classroom-exit tests now use
the current placement/return point. `room_sign_preview.gd` renders both halls.
