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
