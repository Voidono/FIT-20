# Art slots

Nothing in the scripts depends on a picture. Every image below is a texture assigned in a scene, a theme or a resource,
so you can overwrite a file with your own (same name) or re-point the texture in the Inspector. Pixel art: the project
filter is Nearest, internal canvas 640x360, so draw at 1:1 for that canvas.

## Character (`character/`)
| File | Size | Used by |
|---|---|---|
| `runner_sheet.png` | 192x288 = 6x6 cells of **32x48**, character faces right, feet on the bottom edge | `runner_frames.tres` |
| `runner_frames.tres` | SpriteFrames, one AtlasTexture per frame | `Sprite` in `scenes/character/runner_character.tscn` |

Animations the game plays (names are exports on `RunnerCharacter`, a missing one falls back to `run`):
`idle` 2 frames, `jog` 6, `run` 6, `push` 6, `sprint` 6, `stumble` 4 (at the wall), `drink` 4. Frames per second are set per
animation in the SpriteFrames panel. Different frame size: change `Sprite > Offset` in the character scene to `(-width/2, -height)`
so the feet stay on the origin. The ghost is the same scene with a translucent `modulate` set in `fit_runner.tscn`.
Also in the character scene: `Shadow`, `Dust` and `Splash` particles (textures `world/dust.png`, `world/splash.png`), and the two
status icons assigned on the root node (`world/status_wall.png`, `world/status_drink.png`).

## UI (`ui/`)
`fit_theme.tres` is the project theme (Project Settings > GUI > Theme). Its StyleBoxTexture slots take these nine-patches:
| File | Size / margins | Theme slot |
|---|---|---|
| `panel.png` | 24x24, 8 | PanelContainer (pause, results, debug panel) |
| `button_normal.png` `button_hover.png` `button_pressed.png` | 24x24, 6 | Button and OptionButton states |

Texture slots on nodes (open the scene, select the node, Inspector > Textures):
| Scene | Node | Files |
|---|---|---|
| `stamina_bar.tscn` | StaminaBar (TextureProgressBar) | `bar_under.png` `bar_fill.png` (white, tinted by zone) `bar_over.png`, 24x16, margin 3 |
| | Pattern, ExitMark | zone patterns come from the ZoneStyle nodes; `exit_mark.png` 2x16 |
| `effort_gauge.tscn` | Track, CruiseBand | `gauge_track.png` 24x14 (3), `gauge_band.png` 8x8 (2) |
| | Tick1-4, PaceMarker, EffortMarker | `gauge_tick.png` 2x14, `marker_pace.png` 3x14, `marker_effort.png` 12x9 |
| `progress_strip.tscn` | Bar, zones, dots | `strip_under.png` `strip_fill.png` 24x8 (2), `zone_water.png`, `zone_spurt.png`, `dot_player.png` 10x10, `dot_ghost.png` 8x8 |
| `hud.tscn` | Root/Zones/* (ZoneStyle nodes) | per zone: colour, icon (`icon_*.png` 12x12), bar pattern (`pattern_*.png`) |
| | PauseButton | `pause.png` |
| `result_panel.tscn` | root, Stone | `star_full.png` `star_empty.png` 24x24 (exports on the root), `time_stone.png` 36x36 |
| `ready_overlay.tscn`, `finish_arch.tscn` | Logo | `branding/fit_logo.png` |

Zones are shown by colour **and** pattern **and** icon **and** name. Keep at least two of those distinct when you restyle.

## World (`world/`)
| File | Size | Used by |
|---|---|---|
| `sky.png` | 4x64 gradient, stretched with linear filtering | `SkyLayer/Sky` in `fit_runner.tscn` |
| `hills_far.png` `hills_near.png` | 640x120 / 640x90, must tile horizontally | Parallax2D nodes `FarHills`, `NearHills` (`repeat_size` = texture width) |
| `grass_tile.png` | 32x32, tiles | `Ground` Polygon2D in `course.tscn` (1 world px = 1 texture px) |
| `track_tile.png` | 32x16, tiles along the track | `Track` Line2D (width 16) |
| `flag_pole.png` `banner.png` | 3x46, 78x18 (banner is tinted per sign) | `sign_flag.tscn`, `water_station.tscn` |
| `table.png` | 28x14 | `water_station.tscn` |
| `distance_post.png` | 4x18 | `distance_post.tscn` |
| `arch_post.png` `arch_banner.png` `chequer.png` | 6x90, 80x30, 8x16 | `finish_arch.tscn` |

Props are scenes under `Course/Props`. To add one: instance a prop scene (or any Node2D with `course_prop.gd`), set
`track_fraction` (0 start, 1 finish) in the Inspector. `Course` puts it on the ground. Water station width is `span_fraction`.

## Branding, font, text
- `branding/fit_logo.png`: placeholder, overwrite with the real logo (any size, it is scaled to fit).
- `fonts/DejaVuSans-Bold-vi.ttf`: Vietnamese-capable placeholder (licence in the same folder). Swap it in `fit_theme.tres` (`default_font`).
  The debug overlay has a diacritics test line: check every letter of your pixel font there.
- Text lives in `i18n/strings.csv` (`keys,vi,en`). Godot imports it into `.translation` files, listed in Project Settings > Localization.
  Labels in the scenes hold the key, so they translate themselves.
