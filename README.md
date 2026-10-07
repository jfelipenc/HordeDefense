# Hold the Hearth

Godot 4.7 (Mobile renderer), portrait 1080x1920. Design and plan live in `docs/`.

## Layout

- `autoload/` EventBus, GameState
- `scenes/` Main, Gate, WallPlaceholder
- `scripts/` gate run, squad, formation, resource classes
- `resources/gates/`, `resources/sections/` authored `.tres` data (new gate or section = new file)
- `tests/` headless tests

## Run

Open the project in Godot and press F5. Drag (or touch-drag, or arrow keys) to steer through the gates.
`resources/sections/section_test.tres` defines the run; edit it to change gates, order or the blocker.

## Test

```
godot --headless --path . -s res://tests/run_tests.gd
```

Run `godot --headless --path . --import` once after adding a new `class_name` script.
