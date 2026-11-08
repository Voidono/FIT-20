# Chapter 1 implementation

Current cast: thầy Dũng replaces Minh at the entrance, and thầy Tùng is the Nhà C lecturer. Legacy node and quest IDs are retained for saves; see `NPC_CAST.md`.

Confirmed choices: named activities; return to the lecturer for Stone #1; Minh near the right-side gate/start; lecturer beside the blue Nhà C building.

## Playable route

1. Play opens the campus with the player near the right-side gate. The quest tracker asks the player to approach Minh and interact.
2. Minh explains the 2006 → 2026 premise, four stones, working controls, and the route to the blue building. Completing the conversation saves the introduction and activates the lecturer objective.
3. The stationary Nhà C lecturer offers named Garbage Quest and FIT Runner choices, explains their actual rules, then launches the shared activity host. Returning after an unfinished/failed attempt allows retry, choosing the other activity, or leaving.
4. A passing activity saves quest completion immediately. It does not award the stone inside the minigame.
5. Talking to the lecturer after either activity passes grants Stone #1, completes Chapter 1, and activates the Room 417 objective in one save. Repeating the conversation gives directions without another reward.
6. The existing Nhà C entrance stays locked until Stone #1 is owned. It then opens `scenes/mapsides/t_2_c.tscn`, arriving at (2000, 100). The shared entrance spans x=1900–2100 at y=100 and leads back outside. The hallway doorway at (3100, 150) opens `scenes/chapters/room_417.tscn`; only entering the room completes the Room 417 objective. Leaving the classroom returns just in front of that doorway at (3100, 210), since (3100, 150) intersects the existing wall collision.

The hallway and both return routes are connected. Door arrivals require stepping off the threshold before it can trigger again. The existing classroom interior is preserved; seating, FIST/POISON selection, and the Room 417 quiz remain later work.

## Scene setup and editable placement

`scenes/mapsides/nửa đầu.tscn` now attaches `scenes/chapters/chapter1.gd` and contains stationary `NPC/Minh` and `NPC/Lecturer` instances of the existing dialogue NPC template. Existing optional NPCs remain in place. The existing quest tracker is reused.

Chapter1 exports these local positions in Godot's Inspector:

| Property | Local position |
|---|---|
| starting_position | (300, 100) |
| minh_position | (380, 100) |
| lecturer_position | (1158, -915) |

The campus root itself is offset by (431, 65). Its player remains `Map/Character`. Camera limits now cover the actual map extents, including the right-side starting area. The entrance uses the existing Area/Area2D shape at (1158.75, -1023); if the building entrance is moved later, move that collision shape too.

NPC sprites and name tags render above ground layers. The new arrow-key bindings match the introduction and existing desktop control hint. The introduction uses different instructions for touch devices and does not advertise unimplemented sprint or Space interaction.

## Verification

- `tests/chapter1_test.gd`: 18 checks for dialogue compilation, choice/switching, failure handling, both reward routes, saved selection, atomic handover, and duplicate prevention.
- `tests/chapter1_dialogue_test.gd`: executes the real arrival/reward/repeat dialogue through Dialogue Manager using a disposable save.
- `tests/chapter1_world_test.gd`: checks campus staging, the locked entrance, hallway arrival at (2000, 100), the Room 417 doorway at (3100, 150), both return routes, and campus reentry without immediate doorway loops.

Tests use separate save files in `res://tests/`; they do not overwrite the player's game save. Run from the project root with Godot 4.7.2, for example:

```text
godot --headless --path . --script res://tests/chapter1_test.gd
godot --headless --path . --script res://tests/chapter1_dialogue_test.gd
godot --headless --path . --script res://tests/chapter1_world_test.gd
```

The world test allows up to 60 seconds for scene loading rather than assuming a fixed load time. Live visual inspection and complete human-played runs of both activities remain necessary. Existing engine certificate-store and shutdown-resource warnings occurred during checks; no story-flow assertions failed in the final runs.
