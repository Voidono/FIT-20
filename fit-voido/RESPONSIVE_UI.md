# PC and phone UI check

The game remains designed for landscape play. The UI was checked at 640×360,
960×540, 1280×720, 1170×540 and 540×960 logical viewport sizes. Portrait layouts
were checked for clipping; a physical phone/browser run is still required for
safe-area insets, browser chrome, audio, multitouch feel and performance.

Changes:

- Main menu preserves its authored composition while resizing; volume sliders
  use a centered layout and stack on narrow screens.
- Campus VirtualJoystick now maps directly to movement actions. The previous
  `axis_changed` connection was invalid for Godot's built-in joystick. Its
  footprint adapts to height, interaction uses a released action pulse, and
  scene exit clears held movement.
- Dialogue/quiz widths adapt to the viewport. Responses have touch-sized
  targets; guides use a touch hint on phones.
- Activity return button stays anchored to the top right during resizing.
- Trash results wrap details, scroll on short screens and support keyboard
  focus. Runner pause/result buttons have larger targets. Boss choices and
  main actions have taller phone targets within its scaled viewport.
- Volume sliders avoid duplicate signal connections.

Verification:

`tests/responsive_audit.gd -- --touch-controls` checks actual menus, sliders,
quiz, guide, Trash HUD/results, Runner ready/running/results, boss viewport/pause,
gate and campus HUD. It injects a real screen-touch/drag into the campus joystick
and checks movement plus release on scene exit. Add `render` to save screenshots
under `tests/responsive_*.png`. `--touch-controls` also allows desktop preview
of phone UI without changing platform detection.

`tests/activity_host_smoke.gd` checks each real activity launch/return and resizes
the existing host overlay during play. The existing journal, boss pause,
introduction and ending tests cover their respective behavior.

Existing asset diagnostics (TileSet missing atlas cells and Runner's serialized
`run` animation during scene instantiation) are separate from these UI checks.
