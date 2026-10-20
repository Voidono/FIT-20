class_name TrashLayers
extends RefCounted
## Physics layers (bit values) used by Trash Train. Optional: name them in
## Project Settings -> Layer Names -> 2D Physics (1 runner, 3 npc, 4 walls, 5 bins, 6 tail).

const RUNNER := 1  # layer 1: the runner's body
const PICKUP := 2  # layer 2: reserved (pickups only DETECT, they sit on no layer)
const NPC := 4  # layer 3: NPC hit areas
const WALLS := 8  # layer 4: everything solid. Children of the level's "Obstacles" node are put here for you
const BINS := 16  # layer 5: bin zones (so the spawner can keep items away from them)
const TAIL := 32  # layer 6: the items trailing behind the runner
