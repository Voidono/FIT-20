# Quest waypoints

The quest journal now owns a small gold destination marker. An offscreen
destination gets an edge arrow and a short label. Onscreen destinations get a
diamond above the NPC or door; an NPC's own interaction prompt takes over when
the player gets close. Markers hide during dialogue and outside exploration.

`journey_guidance.gd` remains the source of the current objective. The waypoint
does not start or complete quests. `quest_destination.gd` maps that objective to
a live scene node, so moving the NPC or door in Godot also moves its marker.

Routing points to the next local step: the Nhà C entrance, the correct upstairs
or downstairs staircase, a classroom exit, or the final NPC/door. Stage-one
retries point to the lecturer who launches the selected activity. Both valid
seating groups in 417C are marked; the player still chooses their skill.

The arrow gives the direction to that interaction, not a path through walls or
around buildings. It avoids the journal and leaves the menu and touch controls
clear. The overlay ignores pointer input.

Files: `scenes/UI/quests/quest_destination.gd`, `quest_waypoint.gd`, and the journal
integration in `quest_tracker.gd`.

`tests/quest_waypoint_test.gd` resolves every mapped objective against the five
actual maps (campus, three floors, and 417C), verifies floor routing and seating
choices, and checks live progress updates, dialogue visibility, input handling,
and compact-screen bounds. Add `-- render` to capture previews.
