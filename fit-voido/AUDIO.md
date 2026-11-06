# Audio setup

The Music autoload (`scenes/UI/music.tscn`) persists across scenes. It uses a
non-positional AudioStreamPlayer on the Music bus, loops tracks, and fades out
before switching and fading in. Master controls all audio; Music controls BGM.
Footsteps use the existing `sound effect` bus.

## Walking sounds

1. Import short, non-looping WAV or OGG footstep files.
2. Select the player node using `scenes/Character/character.gd` in your player scene.
3. Add clips to **Footstep Sounds** in the Inspector. Multiple clips are randomly
   selected with slight pitch variation.
4. Adjust **Footstep Distance** (default 48 world pixels) and **Footstep Volume Db**.

Steps follow actual distance travelled, so walking into a wall makes no steps.
Stopping or dialogue movement locks reset the distance counter. Empty arrays are
silent. No footstep asset is bundled or assigned by this change. This integration
is for the overworld character; standalone minigame controllers are separate.

## Different music for each game

Open `scenes/UI/music.tscn` and select its root. In **Activity Tracks**, add String
keys and drag an AudioStream into each value:

| Key | Game |
| --- | --- |
| `fit_runner` | Running game |
| `garbage_quest` | Trash train |
| `boss_fight` | Boss battle |

Unassigned games use **Default Track**, preserving the existing soundtrack.
Returning to the campus selects the campus/default music automatically. Loading
screens keep the current track. The same music across scenes keeps its position;
returning after a different song starts the campus song from the beginning.

For a specific map, menu, or standalone minigame, add its exact `res://...tscn`
path to **Scene Tracks**. Activity Tracks take precedence inside the activity host.
An explicit null entry means silence. Use **Fade Seconds** to adjust transitions
(each fade takes this duration). Music continues while gameplay is paused.

Code can also call `Music.play_music(preload("res://soundtrack/your_track.ogg"))`
or `Music.play_music(null)` to stop. Automatic selection runs on the next scene
change, so use the Inspector mappings for permanent scene assignments.

Volume settings also now restore the saved music value independently of Master.
