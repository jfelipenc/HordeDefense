# Hold the Hearth

Godot 4.7 (Mobile renderer), portrait 1080x1920. A horde-defense game in the style of Kingshot's Viking Vengeance: defend one wall through 20 waves in four phases, with milestone waves at 5, 10, 15 and 20. The design lives in `docs/superpowers/specs/`, the implementation plans in `docs/superpowers/plans/`.

## Layout

- `autoload/` EventBus, GameState, SaveManager (stub), SceneSwapper (fade), DebugPanel
- `scenes/` Main (entry), Battle (the battle screen); `scenes/debug/` placeholder and asset test scenes
- `scripts/` pure battle logic (`Battle`, `PhaseMachine`, `Horde`, `CombatResolver`, `BattleState`, `WaveSpawner`, `WaveBudget`, `Formation`, `TroopPool`, `Triangle`), the `Resource` classes (`TuningData`, `StageData`, `EnemyData`, `TroopData`, `TowerData`, `HeroData`) and the view layer (`BattleView`, `BattleHud`, `RegroupScreen`, `battle_scene.gd`)
- `resources/` authored `.tres` data: tuning, stages, enemies, troops, towers, heroes (a new enemy, tower or stage = a new file)
- `assets/` imported KayKit and Kenney files; `assets/ASSETS.md` lists every file, its pack and license
- `tools/` asset import, clip listing, `sim_battle.gd` (balance probe), `screenshot.gd`
- `tests/` headless tests; `tests/kit.gd` holds shared builders
- `ui/` reserved for real HUD scenes (M5)

## Run

Open the project in Godot and press F5. The battle opens on the regroup screen: set the troop ratio and where each kind stands, pick towers, read the scout report, press Ready. During waves tap the hero skill (aims at the busiest lane) and the Sortie button of a section that has cavalry.

Debug panel (debug builds): F1 or a 3-finger tap. It jumps to wave N, skips to the next phase, sets the stage, adds gold and toggles 4x speed. The stage setter only stores `GameState.current_stage`; stage 1 is the only authored stage, so nothing reads it yet.

## Test

```
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/run_tests.gd -- test_formation
```

The second form runs one suite. Run `godot --headless --path . --import` once after adding a new `class_name` script or asset.

## Balance

`resources/tuning/default.tres` holds the defaults from `scripts/tuning_data.gd` (override them in the Inspector); the enemy, troop, tower and hero `.tres` files hold explicit numbers. To see how a setup plays out without opening the game:

```
godot --headless --path . -s res://tools/sim_battle.gd
```

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
