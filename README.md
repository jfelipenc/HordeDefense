# Hold the Hearth

Godot 4.7 (Mobile renderer), portrait 1080x1920. Design and plan live in `docs/`.

## Layout

- `autoload/` EventBus, GameState, SaveManager (stub), SceneSwapper (fade), DebugPanel
- `scenes/` Main, Gate, WallPlaceholder; `scenes/debug/` placeholder and asset test scenes
- `scripts/` gate run, squad, formation, and the `Resource` classes (Section, Gate, Enemy, Unit, Card, Hero data)
- `resources/` authored `.tres` data (new gate, enemy, card or section = new file)
- `assets/` imported KayKit and Kenney files; `assets/ASSETS.md` lists every file, its pack and license
- `tools/` asset import and clip listing
- `tests/` headless tests
- `ui/` reserved for HUD scenes (M5)

## Run

Open the project in Godot and press F5. Drag (or touch-drag, or arrow keys) to steer through the gates.
`resources/sections/section_test.tres` defines the run; edit it to change gates, order or the blocker.

Debug panel (debug builds): F1 or a 3-finger tap. It spawns a wave (stub), sets the section, adds gold and toggles 4x speed.

## Test

```
godot --headless --path . -s res://tests/run_tests.gd
```

Run `godot --headless --path . --import` once after adding a new `class_name` script or asset.

## Assets

Source packs stay untouched in `D:\ASSETS\KayKit`. Re-import with:

```
python tools/import_assets.py
godot --headless --path . --import
godot --headless --path . -s res://tools/list_clips.gd
python tools/import_assets.py --docs-only
```

## Export

`export_presets.cfg` has "Windows Desktop" and "Android". Android debug exports with the editor's configured SDK/JDK:

```
godot --headless --path . --export-debug "Android" build/android/HoldTheHearth-debug.apk
```

Windows export needs the Windows export templates installed (only the Android ones are present on this machine).
