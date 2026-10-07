# Hold the Hearth

3D low-poly horde-defense game (Godot 4.7, GDScript, Mobile renderer, portrait 1080x1920).
Design: `docs/Horde Defense Village Game – Design Document.md`. Plan: `docs/Hold the Hearth – Implementation Plan.md`.

## Folder layout

| Folder | Contents |
| --- | --- |
| `autoload/` | Global singletons: `EventBus`, `GameState`, `SaveManager` |
| `scenes/` | One scene per screen (`Main.tscn`, battlefield, village, ...) |
| `scripts/` | Gameplay scripts not owned by a single scene, and Resource classes (`scripts/data/`) |
| `resources/` | Data-driven `.tres` files: sections, enemies, units, gates, cards, heroes |
| `assets/` | Imported art and audio (`assets/kaykit/`, `assets/kenney/`), inventory in `assets/ASSETS.md` |
| `ui/` | HUD and menu scenes, debug panel |

Also: `tests/` (headless tests), `tools/` (asset import scripts), `docs/`.

## Tests

```
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -s tests/run_tests.gd -- <file-filter>
```

```
python -I -m unittest discover -s tests/tools   # asset importer tests
```

## Assets

Art comes from `D:/ASSETS/KayKit` (KayKit and Kenney, all CC0). The source folder is never modified.
`tools/asset_manifest.json` lists exactly which files are used. To re-import after changing it:

```
python tools/import_assets.py
godot --headless --path . --import
godot --headless --path . -s tools/dump_clips.gd
python tools/gen_assets_md.py
```

`assets/ASSETS.md` (generated) is the inventory: every imported file, its pack and license, plus the animation clip names of the `Rig_Medium` and `Rig_Large` files. `scenes/test/asset_test.tscn` plays Knight + a CombatMelee clip next to a Hexagon castle.
