# Trash Train: editor guide

Everything about a **map** lives in a scene you build in the Godot editor with ordinary nodes.
The game code (`trash_train.gd`) knows nothing about any particular map. It loads a level scene
and wires itself to whatever that scene contains.

Tested on Godot 4.4.1 and 4.7 (GDScript only). The sample scenes were generated and run by the engine itself,
but I could not open the editor while building this: the editor-side steps below use standard Godot tools
(Path2D curve tool, collision shape handles, the ReferenceRect box) and are the first thing to try on your machine.

---

## 1. Folder map

| Path | What it is |
|---|---|
| `trash_train.tscn` | The game. Root `TrashTrain` with five slots: **Level Scene, Player Scene, Npc Scene, Catalog, Tuning** |
| `levels/level_yard.tscn` | Sample map: fountain, building, benches, hedges, trees, 5 spawn zones, 5 NPC routes |
| `levels/level_template.tscn` | Empty starting point for your own map (Bounds, start point, 2 bins, 1 spawn zone) |
| `player.tscn`, `npc.tscn` | The runner and the NPC. Restyle them or swap them out |
| `items/*.tres`, `items/catalog.tres` | One resource per kind of trash, plus the list a level spawns from |
| `tuning.gd` | Every tweakable **number** (speeds, caps, timers, the clock, the star lines). No map data in it |
| `run_result.gd`, `result_panel.gd`, `hud.gd` | The result data, the end-of-run screen, the score / clock / "tap to start" overlay |
| `PLAYTEST.md` | A one-page plan for the first playtest, and how to turn it into numbers |
| `strings.gd` | All player-facing text (Vietnamese + English) |
| `tools/build_defaults.gd` | Regenerates the sample content if you delete or break it |

## 2. Make your own map in 10 minutes

1. In the FileSystem dock, right-click `levels/level_template.tscn` and choose **Duplicate**. Name it `my_map.tscn`. Open it.
2. **Art:** delete the `Ground` node and add your own background (Sprite2D, TileMapLayer...) as a child of the root.
3. **Bounds:** select the `Bounds` node (a ReferenceRect) and drag its handles over the playable area.
   The camera, the invisible outer walls and the spawn margin all follow it.
4. **PlayerStart:** drag the Marker2D to where the runner begins.
5. **Obstacles:** under `Obstacles`, add a **StaticBody2D**. Give it a **CollisionShape2D** (or CollisionPolygon2D)
   and a Sprite2D for looks. Repeat. Anything under `Obstacles` is made solid for you.
6. **Bins:** select a bin under `Bins`, edit its collision shape (that is the zone), set **Accepts**
   (e.g. `ewaste`) and add a Sprite2D for looks. Duplicate it for more bins.
7. **Spawn zones:** under `SpawnZones` add or edit **TrashSpawnZone** nodes. Draw their shapes where trash may appear.
8. **NPC routes:** under `Routes` add a **TrashNpcRoute** (it is a Path2D). Use the Path2D toolbar: click to add points,
   drag to curve. Set `Count`, `Mode`, `Speed Scale`.
9. Open `trash_train.tscn`, select the root, and drag `my_map.tscn` into the **Level Scene** slot. Press **F6**.

The root node of a level shows a yellow warning triangle if `Bounds` or `PlayerStart` is missing.

## 3. The level scene

```
LevelYard                 TrashLevel (level.gd)    export: Catalog, Boundary Thickness
|- Ground                 any art (here a TrashGroundGrid placeholder)
|- Bounds                 ReferenceRect            REQUIRED name: the playable rectangle
|- PlayerStart            Marker2D                 REQUIRED name: where the runner starts
|- Obstacles              Node2D                   REQUIRED name for solid things (see below)
|   '- Fountain, Bench ... StaticBody2D + CollisionShape2D + your Sprite2D
|- Bins                   Node2D                   any parent works: bins are found automatically
|   '- BinEwaste ...       TrashBin (Area2D) + CollisionShape2D (the zone) + your Sprite2D
|- SpawnZones             Node2D                   any parent works
|   '- ZoneWest ...        TrashSpawnZone (Area2D) + shapes
'- Routes                 Node2D                   any parent works
    '- FountainLoop ...    TrashNpcRoute (Path2D) + a drawn curve
```

Only `Bounds`, `PlayerStart` and `Obstacles` are looked up **by name**. Bins, spawn zones and routes are found wherever you put them.

### Obstacles (what the runner must walk around)
* Put any **StaticBody2D / PhysicsBody2D** under `Obstacles`. Its physics layer gets the *walls* bit added automatically.
* A **TileMapLayer** under `Obstacles` works too. Give its TileSet a physics layer and draw collision polygons on the tiles;
  the layer is put on *walls* for you.
* Solid parts of other nodes (e.g. a StaticBody2D inside a bin) are **not** touched. Set their **Collision Layer to 4 (walls)** yourself.
* Your art draws below the runner (z 200). For a tree canopy that should cover the runner, give it `z_index` above 200.
* The runner slides along walls. NPCs ignore obstacles, so design their routes around them.

### Bounds
A ReferenceRect named `Bounds`. It is invisible in game. The camera is clamped to it, four invisible wall slabs are built
around it, and items never spawn or land outside it (spawn margin in `tuning.gd`).

### Bins (`TrashBin`)
| Property | Meaning |
|---|---|
| zone | **Any CollisionShape2D / CollisionPolygon2D children you draw**. Walking into it banks matching items |
| `accepts` | Item `bin_id`s it takes (e.g. `ewaste`). **Empty = takes everything** (the single-bin fallback) |
| `label_key` | Key in `strings.gd` for the text on the bin (empty = no label) |
| `color` | Zone tint and popup colour |
| `draw_zone` | Draw the coloured placeholder zone. Untick when you add your own Sprite2D |

Banking pays `sum(points) x (1 + multiplier_per_item x items banked in that visit)`. Each bin takes only what it accepts,
wherever those items sit in the tail, and the rest of the tail closes the gap.

### Spawn zones (`TrashSpawnZone`)
Draw where trash may appear. Points are picked **uniformly inside the shapes**; the zone follows its own position,
rotation and scale.

| Property | Meaning |
|---|---|
| shapes | CollisionShape2D (Rectangle, Circle, Capsule, ConvexPolygon) and/or CollisionPolygon2D (concave is fine, no self-crossing) |
| `weight` | Relative share of spawns this zone gets |
| `kinds` | Only these item kinds spawn here (empty = the level's whole catalog) |
| `max_alive` | Cap on this zone's items lying on the ground (0 = no cap) |

A candidate point is rejected if it overlaps a wall, is within `bin_keepout` of a bin zone, is too close to the runner or
another item, or is outside the bounds margin. A level with **no** spawn zones spawns anywhere inside `Bounds`.

### NPC routes (`TrashNpcRoute`, a Path2D)
| Property | Meaning |
|---|---|
| curve | Drawn with the Path2D tools. Bezier handles give smooth curves |
| `mode` | **PING_PONG**: walk to the end, turn, walk back. **LOOP**: wrap at the end. For a closed loop, finish the curve on its first point |
| `count` | How many NPCs walk it, spread evenly along the curve |
| `speed_scale` | Multiplies `tuning.npc_speed` |
| `start_ratio` | Where the first NPC starts (0 to 1) |
| `npc_scene` | A different NPC for this route (empty = the game's default `npc.tscn`) |
| `enabled` | Untick to switch the route off |

`tuning.npc_count` limits how many NPCs are active overall (the first N in the scene). The **Routes** button (or `R`) in the
debug overlay draws every curve in game so you can check them against your obstacles.

## 4. Items (`TrashItemDef`, a Resource)

Right-click in FileSystem, **New Resource**, pick `TrashItemDef`, save it as `items/battery.tres`, then add it to
`items/catalog.tres` (or your own `TrashItemCatalog`).

| Property | Meaning |
|---|---|
| `id` | Unique name |
| `tier` | NORMAL, HEAVY or GLITCH. Points, slowdown and the flicker-and-vanish behaviour come from the tier (numbers in `tuning.gd`) |
| `bin_id` | Which bins take it (matches a bin's `accepts`). Invent new ones freely |
| `spawn_weight` | How often it appears among the catalog |
| `texture`, `texture_scale`, `texture_offset` | Your art. Empty = coloured placeholder shape |
| `pickup_shape` | **The area the runner must touch** (any Shape2D). Empty = a circle slightly bigger than the item |
| `tail_shape` | **What an NPC can hit while the item trails behind you.** Empty = a circle slightly smaller than the item |

Assign the catalog on the level root (**Catalog**) so each map can have its own item set. The `TrashTrain` root has a fallback
slot.

## 5. The runner and the NPC

`player.tscn` (TrashPlayer, a CharacterBody2D) and `npc.tscn` (TrashNpc, an Area2D) are normal scenes.
To restyle: open one, add a Sprite2D or AnimatedSprite2D, **untick Draw Placeholder** in the inspector, edit the collision shape.
* The runner's **CollisionShape2D** decides how it fits through gaps and how close it gets to walls.
* An NPC's **hit area** (the shapes under it) is what cuts your tail: touching the runner drops the whole tail, touching a tail item
  cuts there. Draw it a bit smaller than the sprite so near misses do not count.
* Use **Scene -> New Inherited Scene** to make variants. Point a route's `npc_scene` at one, or set the root's `Player Scene` / `Npc Scene`.

## 6. Physics layers

| Layer | Used for |
|---|---|
| 1 | The runner's body |
| 3 | NPC hit areas |
| 4 | **Walls**: obstacles and the outer boundary |
| 5 | Bin zones |
| 6 | Tail followers |

You can name them in Project Settings, Layer Names, 2D Physics (optional). Pickups and spawn zones sit on no layer.

## 7. Troubleshooting

| Problem | Likely cause |
|---|---|
| The runner walks through my obstacle | It is not under `Obstacles`, or has no collision shape, or you used a non-physics node (Area2D does not block) |
| No trash spawns | The zone has no shapes, every shape is inside walls, or `max_alive` / `max_pickups` is reached |
| Trash only appears in some zones | `weight` is 0, or the zone is mostly inside walls or the bin keep-out |
| A bin never banks | Its `accepts` does not match any item's `bin_id`, or it has no zone shape |
| An NPC does not move | The curve has fewer than 2 points, `enabled` is off, or `tuning.npc_count` is lower than its place in the scene |
| NPC hits feel unfair | Shrink its hit area, or raise `bump_invulnerability` |
| "TrashLevel root required" error in the Output | The level scene's root node must use `level.gd` |
| Identifier not declared | Project -> Reload Current Project so the class names register |

## 8. The run: clock, result, retry

```
LOADING -> READY ("tap to start") -> RUNNING (the clock) -> ENDED (result panel) -> Retry -> READY ...
```
* **READY / ENDED freeze the world.** Everything under the `World` node (NPCs, spawn timer, glitch countdowns, physics)
  stops, without touching your game's own pause. The first press on the free part of the screen starts the clock and
  that same press keeps steering.
* **Retry builds a fresh world** from the level scene (new items, NPCs back at their starts, empty tail, score 0).
* **When time runs out** whatever is still in the tail is lost (it is shown as "not banked" on the result screen).
  A bank on the very last frame still counts.

| Setting (`tuning.gd`, group Run) | Default | Meaning |
|---|---|---|
| `run_duration` | 80 | Seconds on the clock (the brief says 75 to 90) |
| `good_run_score` | 100 | What a *good* run banks. **A guess: set it from playtests** (see `PLAYTEST.md`) |
| `pass_ratio` | 0.33 | 1 star = a pass, at this share of a good run (33 points by default) |
| `two_star_ratio` / `three_star_ratio` | 0.66 / 1.0 | 2 and 3 stars |
| `assist_after_fails` | 2 | After this many failed attempts the clock quietly gets extra time (0 = never) |
| `assist_bonus_seconds` | 10 | The extra time. It does not stack and is never announced |

Unlimited retries; failing never locks anything.

### Talking to your game (`TrashTrain` root)
| | |
|---|---|
| `signal run_finished(result)` | Every attempt, the moment time is up. Award the Time Stone when `result.passed` |
| `signal closed(result)` | The player pressed **Continue** (only offered after a pass). Close the minigame on this one so they see their stars |
| `failed_attempts` | **Set it from your save data before the run**, and read it back from the result. It drives the quiet extra time |
| `auto_start` | Tick it to skip the "tap to start" screen (start the clock from your own countdown with `start_run()`) |
| `start_run()`, `end_run()`, `restart()` | Drive it from code |
| `rng_seed` | 0 = random. Any other number = the same starting items every time (use it for playtests) |
| `log_runs` | Append every attempt to `user://trash_train_runs.csv` (Godot: Project -> Open User Data Folder) |

`TrashRunResult` has `passed`, `stars`, `banked_score`, `bumps_taken` (the four the quest system needs) plus `items_banked`,
`items_lost`, `unbanked_points`, `time_used`, `duration`, `assist_applied`, `attempt`, `failed_attempts`, and `to_dict()`.

## 9. Limits

* NPCs follow their curve and ignore obstacles; avoid collisions by drawing routes around them.
* Tail followers do not collide with walls (they follow the runner's path).
* Spawn zones read their shapes once at start. Call `zone.rebuild()` if you change them in code.
* ConcavePolygonShape2D (segment lists), Segment and WorldBoundary shapes are not supported as zone shapes.
* Time Pulse (step 5) is not built yet; `TrashNpcs.freeze_all(seconds)` is already there for it.
* The `run_finished` / `closed` signals are in, but the hand-over to your quest system is finalised in step 8.
