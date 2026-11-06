# Place your own scene-changing doors

Drag `scenes/templates/scene_door.tscn` from Godot's FileSystem panel into the map you are editing. It is a reusable Area2D with a rectangular CollisionShape2D. No signal wiring is needed.

1. Move the door instance onto the doorway. Use its **Transform → Position** for coordinates in your current map.
2. On the root door instance, set **Destination → Target Scene** to the scene file to open.
3. Set **Target Position** to the player's arrival coordinates in that destination scene. Place this in clear floor space in front of its doorway, not inside a solid wall.
4. Set **Interaction → Activation** to **Walk In** for automatic travel, or **Interact** to use the existing E/touch interaction action while inside the area.
5. Set **Story Lock → Required Chapter** to **1** for an unlocked door. **2** requires Stone #1, **3** requires the first two stones, etc. You can edit the locked message.
6. To resize the trigger, right-click the instance and enable **Editable Children**, select **CollisionShape2D**, and adjust its rectangle handles or Shape → Size. Each instance has its own shape resource.

For a return door, add another instance in the destination scene and reverse the Target Scene and Target Position. Incoming players must step off a trigger before it can activate again, preventing immediate back-and-forth scene changes.

## Current hallway examples

Both are children of the root in `scenes/mapsides/t_2_c.tscn`:

| Instance | Position in t_2_c | Destination | Arrival position |
|---|---|---|---|
| CampusEntrance | (2000, 100) | nửa đầu.tscn | (1258, -850) |
| Room417Door | (3100, 150) | chapters/room_417.tscn | (567, 614) |

Select **Room417Door** in the Scene tree to move the door or change which room it opens. Moving it does not change its Target Position: that field always belongs to the destination scene. Duplicate an instance with Ctrl+D to create another door.

The template is invisible in the running game; its collision rectangle is visible in the editor. Optional door art or signs can be added as children. Keep the trigger reachable from clear floor space. It detects physics bodies in the `player` group on physics layer 1, matching the project's Character scene.
