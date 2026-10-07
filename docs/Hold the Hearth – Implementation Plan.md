# Hold the Hearth – Implementation Plan

Oct 7, 2026 · companion to *Horde Defense Village Game – Design Document*

## Approach

- **Fun before progression.** M1–M3 build the battle with grey boxes and no village. Do not start M6 until the Fun Gate at the end of M3 passes.
- **Performance before content.** The horde must hold 200+ enemies at 60 fps on a mid-range phone (M4) before any real art or content is added.
- **Data-driven from day one.** Every number lives in a `Resource` (`.tres`). New gates, cards, enemies and sections are new files, not new code.
- **Each task is shippable alone.** A task is done when it runs in the debug scene, has no console errors, and (where noted) has a measurable acceptance check.
- **KayKit is the art source.** Characters, animations, buildings, terrain and props come from the packs in `D:\ASSETS\KayKit` (see *Asset source* below). The Kenney UI pack and Kenney interface sounds in that same folder cover the HUD. Anything still missing is listed as a gap with a decision to make, not silently filled.

### Sizing

Estimates assume one developer, part-time-friendly "weeks" of ~20 focused hours. Treat them as relative sizes, not commitments.

| Milestone | Goal | Est. |
| --- | --- | --- |
| M0 | Project foundation | 0.5 wk |
| M1 | Gate run playable | 1 wk |
| M2 | Wall hold core | 1.5 wk |
| M3 | Combat depth + **Fun Gate** | 1.5 wk |
| M4 | Horde performance + **Perf Gate** | 1 wk |
| M5 | Vertical slice + **Look Gate** | 2 wk |
| M6 | Village and progression | 3 wk |
| M7 | World map and content | 4 wk |
| M8 | Polish, balance, release | 3 wk |

---

## Asset source: `D:\ASSETS\KayKit`

Use the **glTF** versions (`.glb` / `.gltf`), which Godot 4 imports natively. The `fbx`, `fbx(unity)` and `obj` folders are not needed. A `.gltf` file needs its `.bin` and texture PNG next to it; the character `.glb` files are self-contained.

| Pack | Folder | What we use it for |
| --- | --- | --- |
| Adventurers 2.0 FREE | `KayKit_Adventurers_2.0_FREE` | Player side: `Knight`, `Barbarian`, `Ranger`, `Mage`, `Rogue`, `Rogue_Hooded` (`Characters\gltf`). Weapons and props in `Assets\gltf` (swords, bows, quiver, crossbow, staff, wand, shields, spellbook) |
| Skeletons 1.1 FREE | `KayKit_Skeletons_1.1_FREE` | Horde: `Skeleton_Minion`, `Skeleton_Warrior`, `Skeleton_Rogue`, `Skeleton_Mage` (`characters\gltf`), plus weapon and shield props |
| Character Animations 1.1 | `KayKit_Character_Animations_1.1` | `Rig_Medium`: General, MovementBasic, MovementAdvanced, CombatMelee, CombatRanged, Special, Simulation, Tools. `Rig_Large`: General, MovementBasic, MovementAdvanced, CombatMelee, Special, Simulation. `Mannequin_Medium` / `Mannequin_Large` for animation tests. **Clip names not checked yet**: verify on import (task 0.8) |
| Medieval Hexagon 1.0 FREE | `KayKit_Medieval_Hexagon_Pack_1.0_FREE` | Village and world map. Tiles (`hex_grass`, `hex_water`, sloped, plus `coast` and `rivers` sets). Buildings in blue / red / yellow / green and neutral: castle, barracks, archery range, tavern, blacksmith, market, towers A/B, catapult tower, church, home A/B, windmill, watermill, well, mine, lumbermill, scaffolding, destroyed. Neutral walls, wall gates, wood and stone fences, bridges, `projectile_catapult`. Nature (trees, hills, mountains, rocks, clouds) and props (flags, crates, barrels, weapon rack, target, bucket of arrows, tent, ladder) |
| Forest Nature 1.0 FREE | `KayKit_Forest_Nature_Pack_1.0_FREE` | Battlefield dressing: trees (including bare trees), bushes, grass, rocks (`*_Color1` variants) |
| Dungeon Pack 1.1 FREE | `KayKit_Dungeon_Pack_1.1_FREE` | Props: `barrier*` (barricades), `banner_*`, `coin_stack_*`, `chest`, `chest_gold`, barrels, crates, torches; `wall_cracked` / `wall_broken` as optional damage stages |
| Kenney UI Pack | `kenney_ui-pack(1)` | **Not KayKit (Kenney).** HUD: SVG buttons, round/square/rectangle, stars, arrows, checks, sliders in several colors; `Kenney Future` fonts |
| Kenney Interface Sounds | `kenney_interface-sounds(1)` | **Not KayKit (Kenney).** UI audio: click, select, confirmation, error, drop, pluck, open/close, toggle, scroll |

**Other packs on `D:\ASSETS` outside the KayKit folder** (not reviewed in detail): Kenney Castle Kit, Tower Defense Kit, Fantasy Town Kit, Nature Kit, RPG Audio, Music Jingles, plus a second copy of several KayKit packs under `D:\ASSETS\3D` (including `KayKit_DungeonRemastered_1.1_FREE`). The plan imports from `D:\ASSETS\KayKit` only. Use anything else only to fill a listed gap, and record it in the credits file.

### Planned mapping (design doc roles to assets)

| Design role | Asset |
| --- | --- |
| Soldier | Adventurers `Barbarian` (or `Knight`, tinted) |
| Archer / Ranger hero | `Ranger` |
| Knight Captain hero | `Knight` |
| Mage unit / Mage hero | `Mage` |
| Engineer hero | `Rogue` (placeholder, first to be cut) |
| Grunt | `Skeleton_Minion` |
| Runner | `Skeleton_Rogue` |
| Brute, Boss | `Skeleton_Warrior` scaled up (1.6x Brute, larger boss) |
| Shaman | `Skeleton_Mage` |
| Wall, wood tier / stone tier | Hexagon `fence_wood_straight` / `wall_straight` (+ `_gate` variants); iron tier by tint |
| Wall crack stages | Overlay shader or swap to Dungeon `wall_cracked` / `wall_broken` if the style fits (check at Look Gate) |
| Barricade | Dungeon `barrier`, `barrier_half`, `barrier_column` |
| Arrow tower / catapult | Hexagon `building_tower_A/B`, `building_tower_catapult`, `projectile_catapult`, `bucket_arrows` |
| Village: Town Center | `building_castle_blue` |
| Village: Barracks / Archery Range / Tavern | `building_barracks_blue` / `building_archeryrange_blue` / `building_tavern_blue` |
| Village: Workshop / Treasury | `building_blacksmith_blue` / `building_market_blue` |
| Village: Spear Hall / Mage Tower | `building_barracks` in another color, or `tower_base` / `tower_A` (no exact model) |
| Village dressing | Windmill, watermill, well, homes, church, mine, lumbermill, crates, flags |
| Upgrade-in-progress / ruined | `building_scaffolding` (brief flash on upgrade), `building_destroyed` |
| Team colors | Blue for the player; red (buildings, flags, banners) for the horde and raid camps |
| World map | Hexagon tiles, hills, mountains, trees, rivers, coast; fog as an overlay shader |
| Region themes | Forest Nature trees / bare trees / rocks, Hexagon mountains, per-region tint |
| Gold and chests | Dungeon `coin_stack_*`, `chest`, `chest_gold` |
| HUD | Kenney UI Pack |
| UI sounds | Kenney Interface Sounds |

### Remaining gaps

| Gap | Impact | Options |
| --- | --- | --- |
| No combat SFX (hits, impacts, arrows) or coin pickup sound; interface sounds are UI only | Juice in M5 | Check `D:\ASSETS\Audio\kenney_rpg-audio`; otherwise add a CC0 impact pack. Decide in M5 |
| No music loops (only Kenney jingles on disk) | Village and battle music in M5 and M8 | Jingles work for win / lose / level-up stingers. Loops still need a CC0 / CC-BY source (e.g. OpenGameArt) |
| Non-skeleton bosses (Treant, Ogre King) | M7 bosses | Re-skin `Skeleton_Warrior` (scale, tint, props), or a CC0 monster pack. Decide before M7 |
| Tile variety: grass, water, coast, rivers only | Swamp, ash and dark regions | Tint plus decoration (bare trees, mountains, rocks); check the map at the Look Gate |
| No fog-of-war asset | World map in M7 | Overlay shader or dark hex tiles with fade |
| No exact Spear Hall, Mage Tower, cannon, spike trap or oil pot models | Village (M6) and defenses (M6, M7) | Recolor existing buildings; cannon and traps from Kenney Tower Defense Kit (in `D:\ASSETS`) or Dungeon props. Decide before M6.15 |
| No icons for gold, shards, relics; no hero portraits; no cooldown ring | HUD in M5 and M6 | Draw simple icons in Godot, render portraits from the character models |
| Kenney 2D UI beside KayKit 3D | Style mismatch | Recolor the UI to the shared palette; check at the Look Gate |
| Free tier has 4 skeleton and 6 adventurer models | Limited variety | Vary with scale, tint, weapon and shield attachments (already in the design doc style rules) |

---

## M0 – Project foundation (0.5 wk)

**Goal:** an empty but correctly structured Godot 4 project that every later task plugs into.

| # | Task | Done when |
| --- | --- | --- |
| 0.1 | Create Godot 4 project, portrait 1080x1920 base, Mobile renderer, stretch mode `canvas_items` / aspect `keep_height` | Project opens, window is 9:16, runs on desktop |
| 0.2 | Folder layout: `autoload/`, `scenes/`, `scripts/`, `resources/`, `assets/`, `ui/` | Layout committed, README lists it |
| 0.3 | Autoloads: `EventBus` (signals `enemy_killed`, `wall_damaged`, `wave_cleared`, `battle_ended`, `gate_passed`), `GameState`, `SaveManager` (stubs) | Autoloads load with no errors; signals emit from a test button |
| 0.4 | `Main.tscn` + scene swapper with fade | Can swap between two placeholder scenes |
| 0.5 | Resource classes: `SectionData`, `EnemyData`, `UnitData`, `GateData`, `CardData`, `HeroData` (fields only) | Each has an editable `.tres` example |
| 0.6 | Debug panel: spawn wave N, set section, add gold, 4x speed toggle | Panel toggles with a key / 3-finger tap, all four actions stubbed |
| 0.7 | Git repo, `.gitignore` for Godot, export presets for Windows and Android | One debug APK installs on a phone |
| 0.8 | Asset import pipeline: copy only the glTF files we use into `res://assets/kaykit/{adventurers,skeletons,animations,hexagon,forest,dungeon}/` and `res://assets/kenney/{ui,audio}/`, keeping `.bin` and textures beside each `.gltf`; source folder stays untouched; script or checklist for re-import. List the animation clip names in `Rig_Medium_*` and `Rig_Large_*` | `Knight.glb`, a Hexagon `building_castle_blue.gltf` and a `Rig_Medium_CombatMelee` clip play in a test scene; clip names written to `assets/ASSETS.md` |
| 0.9 | Asset inventory (`assets/ASSETS.md`): each imported file, its pack and that pack's license. KayKit and Kenney packs are listed separately | Every imported file has a row |

---

## M1 – Gate run (1 wk)

**Goal:** the "ad feeling" half of the hook works with capsules.

| # | Task | Done when |
| --- | --- | --- |
| 1.1 | `Squad` node: base count N, spawns N capsule followers using a simple flocking / grid formation | Squad of 20 looks like a group, not a stack |
| 1.2 | Auto-run along a road path at constant speed; horizontal drag steers squad within road width | Drag works with mouse and touch |
| 1.3 | `Gate` scene driven by `GateData`: additive, multiplier, negative, type, buff | All five types exist as `.tres` files |
| 1.4 | Gate pairs: squad passes through exactly one gate per pair based on its x-position | 4 pairs, never passes two gates in one pair |
| 1.5 | Live count label above the squad; pop-and-scale tween on gate pass; new units visibly spawn in or fall away | Count matches actual unit number at all times |
| 1.6 | Barracks cap: clamp final count; overflow converts to gold | Debug cap of 50 clamps a x4 gate; gold increases by overflow |
| 1.7 | Mid-run enemy blocker group (stub combat: units "fight" for 1 s and lose a few) | Run cannot be completed without meeting the group |
| 1.8 | Level layout from a `SectionData` gate list (types, values, order) | Changing the `.tres` changes the run with no code edits |
| 1.9 | Hand-off: end of road emits `gate_run_finished(count, buffs)` | Value is received by a placeholder wall scene |

**Checkpoint:** a stranger can play the run and understand the numbers without instruction.

---

## M2 – Wall hold core (1.5 wk)

**Goal:** a horde walks lanes and attacks a 3-segment wall; the town center can fall.

| # | Task | Done when |
| --- | --- | --- |
| 2.1 | `Battlefield` scene: 3 lanes, wall (left/center/right), town center, camera 3/4 top-down portrait | Matches the layout in the design doc |
| 2.2 | `WallSegment`: HP, damage intake, 3 crack stages, broken state | HP 0 swaps to broken and opens the lane |
| 2.3 | `TownCenter`: HP, defeat on 0, emits `battle_ended(false)` | Defeat screen placeholder shows |
| 2.4 | `HordeManager`: enemies as plain data (lane, distance, offset, hp, state) in arrays; no physics bodies | 100 enemies updated per frame from one script |
| 2.5 | Enemy states: `walk`, `attack_wall`, `walk_to_center`, `attack_center`, `dead` | State changes visible on debug capsules |
| 2.6 | `EnemyData` for Grunt, Runner, Brute (speed, HP, damage, cost). Runner starting values: speed ~1.6x Grunt, HP ~50% of Grunt, wall damage ~50% of Grunt, cost 2. Runners must be killable by Soldiers alone, since Archers unlock later (see *Design decisions*) | Three `.tres` files tuned by feel; in a Soldier-only test, a mixed Grunt + Runner wave never breaks a wall segment at the expected power for section 3 |
| 2.7 | Wave spawner: `budget(s, w) = B0 * 1.12^s * (1 + 0.35 w)` buying from the section list until spent | Debug print shows budget and bought counts; matches the formula |
| 2.8 | Wave flow: 5 s pause between waves, wave counter, wave-cleared signal | Waves 1–5 run back to back |
| 2.9 | Units from the gate run deploy to wall segments in proportion to lane threat; drag a squad icon to shift units | Shifting units visibly moves capsules |
| 2.10 | Melee units engage only enemies touching the wall | Soldiers kill Grunts at the wall, nothing else |
| 2.11 | Victory (last wave dead) and defeat flow; result screen with waves survived | Both outcomes reachable and show a placeholder reward |
| 2.12 | Basic HUD: wave counter, horde remaining bar, army per segment, town center HP | HUD matches the portrait layout |

---

## M3 – Combat depth and the Fun Gate (1.5 wk)

**Goal:** decisions matter. This ends with the first go/no-go checkpoint.

| # | Task | Done when |
| --- | --- | --- |
| 3.1 | Archer unit: long range, per-lane front-N targeting (spatial bucketing per lane). In the prototype archers come from a debug loadout; the real unlock is the Greenfields clear (6.13) | Archers kill Runners before they reach the wall |
| 3.2 | Projectile pool and hit feedback (numbers, flash) | 64 pooled damage numbers, no allocations in steady state |
| 3.3 | Hero base: stands on the wall, auto-attacks; `HeroData` drives stats. The hero is the one character that uses its real model now: `Knight.glb` with `Rig_Medium_CombatMelee` and `Rig_Medium_Special` clips (everything else stays grey) | Knight Captain placed, attack animation timed to the hit |
| 3.4 | Tap skill with cooldown ring (8–20 s) and lane/target selection: Knight Captain shield bash | Skill knocks back a lane; cooldown ring is a big thumb target |
| 3.5 | Card system: pick 1 of 3 between waves, `CardData` with effect scripts | Draw 3 unique cards, apply one, game resumes |
| 3.6 | Six starter cards (e.g. archers fire twice, repair wall 30%, spawn 2 catapults, +15% damage, extra hero skill charge, barricade) | All six work and stack sanely |
| 3.7 | Spike wave: wave 4 at ~1.6x budget, two lanes at once | Visible pressure spike |
| 3.8 | Boss (Goblin Warchief placeholder): 60x Grunt HP, escorts | Boss wave is a distinct beat |
| 3.9 | Wall repair / defense hooks (barricade, arrow tower as one placeable defense per segment, placed before wave 1) | Placement drag works, locks after wave 1 |
| 3.10 | Playtest pass with 5+ people (or 20 self-runs) and notes | Written list of what felt good and flat |

### Fun Gate

Proceed only if playtesters replay voluntarily at least twice with **no** progression attached and can describe why they won or lost. If not, iterate on M3 rather than starting M6.

---

## M4 – Horde performance and the Perf Gate (1 wk)

**Goal:** solve the make-or-break risk while the scene is still grey boxes.

| # | Task | Done when |
| --- | --- | --- |
| 4.1 | Test scene: spawn N enemies on demand (50 / 200 / 500) via the debug panel | Can switch counts at runtime |
| 4.2 | Extract a static mesh (rest pose) from `Skeleton_Minion`, `Skeleton_Rogue` and `Skeleton_Warrior`, and use those, not capsules, in the test scene so triangle counts are realistic. `MultiMeshInstance3D` per enemy type, transforms written from `HordeManager` arrays | One draw call per type in the profiler; triangle count per enemy recorded |
| 4.3 | Cheap animation: bob / tilt vertex shader (or baked VAT) for walk and attack loops | Horde looks alive with no skeletons |
| 4.4 | LOD rule: skeletal animation only for hero, boss and the nearest N units | Camera-near units animate fully |
| 4.5 | Visible cap of 300–500, off-screen queue for the rest | Wave still ends only when the queue is empty |
| 4.6 | Optimise targeting buckets and damage-number pool | Frame time per system listed in a profiling note |
| 4.7 | Profile on a low-end and mid-range Android phone (Mobile and Compatibility renderers) | Numbers recorded for both renderers |

### Perf Gate

200 enemies at 60 fps on the mid-range phone, 500 at 30+ fps on the low-end phone, **with the real skeleton meshes**. If not met, adjust the visible cap and animation approach before moving on.

---

## M5 – Vertical slice and the Look Gate (2 wk)

**Goal:** one complete section (gate run, 5 waves, boss, result) in final-quality style.

| # | Task | Done when |
| --- | --- | --- |
| 5.1 | Shared palette and recolor pipeline across KayKit packs (Adventurers, Skeletons, Hexagon, Forest, Dungeon each have their own texture atlas) and the Kenney UI colors | A knight, a skeleton minion, a Hexagon wall and a Forest tree share one palette in a test scene; player side blue, horde red/purple |
| 5.2 | Replace capsules with the mapped models: Barbarian (soldier), Ranger (archer), Knight (hero), Skeleton_Minion (grunt), Skeleton_Rogue (runner), Skeleton_Warrior (brute) | All placeholders swapped, mapping table in this plan followed |
| 5.3 | Battlefield and wall: Hexagon `fence_wood_straight` wall with crack stages, town center and a few village buildings behind it, Forest Nature trees, rocks and grass in the top third | Layout matches the design doc and reads in a screenshot |
| 5.4 | One `AnimationTree` for the shared `Rig_Medium` skeleton (Adventurers and Skeletons use the same rig) loading General, MovementBasic, CombatMelee, CombatRanged and Special | Idle / walk / run / melee / ranged / hit / death work on every character |
| 5.5 | Silhouette pass: enemy types readable at 40 px (scale, tint, held item) | Screenshot test at 40 px shows distinct types |
| 5.6 | Battle HUD in final layout with the Kenney UI pack (buttons, bars, stars, `Kenney Future` font); gold icon and cooldown ring drawn in Godot | Matches the design doc layout; SVGs import at a sharp scale on a phone |
| 5.7 | Juice pass 1: floating numbers, coin fly-to-counter, hit-stop (40–60 ms), wall shake, gate pop | Each effect triggers within 100 ms of its action |
| 5.8 | Audio v1: UI from Kenney Interface Sounds; combat hits and coin sounds from a chosen source (see gaps); two music loops; win / lose jingles | Mix is balanced, no clipping |
| 5.9 | Scripted onboarding battle: unlosable first wall hold after the opening gate run | New player always wins battle 1 |
| 5.10 | Credits file and license check per pack: six KayKit packs, Kenney UI Pack, Kenney Interface Sounds, anything else used | Credits file lists each pack and its license; terms confirmed on the pack pages |
| 5.11 | Trailer-style capture of the slice | 30 s clip that shows the full hook |

### Look Gate

Screenshots read at a glance (army, horde, wall, town center) and the clip works as an ad. If asset styles clash (Kenney 2D UI over KayKit 3D, or Hexagon buildings beside Adventurers characters), fix the palette pipeline now, before adding more packs.

---

## M6 – Village and progression (3 wk)

**Goal:** the loop closes: fight, earn, upgrade, fight again.

| # | Task | Done when |
| --- | --- | --- |
| 6.1 | `GameState` and `SaveManager`: gold, shards, relics, building levels, section progress; JSON to `user://` after every battle and upgrade | Quit and relaunch restores everything |
| 6.2 | Village diorama on Hexagon tiles around the town center using the mapping table (castle, barracks, archery range, tavern, blacksmith, market, walls, dressing) | Buildings placed, camera framed, each tappable |
| 6.3 | Building data and tap-to-upgrade UI: one button showing cost and **what you get**; brief `building_scaffolding` flash on upgrade | Upgrade changes the stat and shows e.g. "+12% wall HP" |
| 6.4 | Town Center gating rule: no building above TC level | Locked buildings show the requirement |
| 6.5 | Barracks (squad size, cap), Walls (HP, tier wood → stone), Archery Range (archer level) wired to battle stats | Each upgrade measurably changes a battle |
| 6.6 | Gold economy: kill, wave and battle rewards; loss still pays by waves survived | Reward screen shows the breakdown |
| 6.7 | Treasury (gold bonus %) | Rewards scale with the level |
| 6.8 | Power score per section and in village; green / yellow / red on FIGHT button | Colors match the thresholds in the design doc |
| 6.9 | Post-battle "recommended upgrade" arrow (wall broke → Walls; runners leaked → Archery Range only once Archers are unlocked, before that → Barracks), using the Kenney UI arrow. The first-upgrade tutorial also points at Barracks, since the Archery Range is locked until Greenfields is cleared | Arrow bounces on the right building in test cases; never points at a locked building |
| 6.10 | Red dot only when affordable | No dots when broke |
| 6.11 | Visible village change per upgrade (wall tiers, extra buildings) | Village differs between level 1 and 10 |
| 6.12 | Unit evolution at every 10 levels (attachments from the Adventurers weapon and shield props + tint) | Soldier → Knight swap works |
| 6.13 | Unlock table as data (`UnlockData` `.tres`), each entry with a condition: `start`, `section_clear:N`, `region_clear:R` or `tc_level:N`. **The region table is the source of truth**: clearing Greenfields unlocks Archers, Spearmen and the Ranger hero. Gate pools and card pools offer only unlocked unit types. The design doc's first-hour minute table becomes a pacing target, logged during playtests, not a hard rule. Triggers the region table doesn't cover: arrow tower and cards on section 2 clear, stone wall on Walls level, unit evolution on unit level | Clearing section 6 unlocks all three Greenfields items and nothing earlier does; locked units never appear in gates or cards; a playtest log shows when each unlock was reached versus the minute targets |
| 6.14 | Tavern and hero shards: second hero (Ranger), unlocked by the Greenfields clear | Hero select and tap skill differ clearly; Ranger is locked until section 6 is cleared |
| 6.15 | Workshop: arrow tower and slots per segment (cannon unlocks with Bone Marsh, see 7.13) | Slots unlock via upgrade |
| 6.16 | Rubber band: after 2 losses, +1 free card and 10% threat cut ("The horde is tired") | Triggers once, resets on win |
| 6.17 | Spearman unit and Spear Hall, unlocked by the Greenfields clear | Spearmen do bonus damage to Brutes; locked until section 6 is cleared |
| 6.18 | Author the six Greenfields sections (1–6) as `SectionData`, with the Goblin Warchief boss on section 6, so region unlocks can be tested end to end. Runners first appear in section 3 as a small group in waves 2–3 (about 10–15% of the wave budget), and grow to about 25–30% of the theme waves by sections 5–6. The other 24 sections are task 7.3 | Playing sections 1–6 in order triggers the Greenfields unlocks and the first relic |
| 6.19 | Soldier-only Runner tuning pass: simulate or play sections 3–6 with Soldiers, Barracks and Walls upgrades only, no Archers or Spearmen | First-try clear rate at the recommended power stays near the design doc's 70% target for story sections (section 6 boss near 35%), and Runner leaks into the town center stay rare |

---

## M7 – World map and content (4 wk)

**Goal:** all 30 sections, 5 regions, bosses and the endgame.

| # | Task | Done when |
| --- | --- | --- |
| 7.1 | Hex world map from Hexagon tiles, hills, mountains and trees; fog overlay shader; tap a section, see power check, fight | Fog lifts on clear |
| 7.2 | Cleared land becomes kingdom (blue flags, farms and houses appear; red buildings for horde camps) | Visual change on clear |
| 7.3 | `SectionData` for 30 sections: gate lists, allowed enemies, region, theme | Every section playable from the map |
| 7.4 | Enemy roster: Shaman (Skeleton_Mage), Climber, Siege, plus region variants built from the four Skeleton models with scale, tint and weapon / shield props | Each has behavior and a point cost per the design doc |
| 7.5 | Five bosses (Warchief, Treant, Lich, Ogre King, Horde Lord) with one signature mechanic each. Treant and Ogre King need a source decision (see gaps) | Each boss is distinct |
| 7.6 | Twist modifiers for every 3rd section: night, fog lanes, double boss, enemies from behind | Modifiers are `.tres` files |
| 7.7 | Region unlocks from the design doc table: Dark Forest → Mage Tower, Mage unit and Mage hero; Bone Marsh → iron wall tier and cannons; Ash Mountains → Engineer hero and oil pots; Fallen Capital → Endless mode and prestige | Each unlock fires only on its region clear; unlock table matches the design doc's region table |
| 7.8 | Stars (1 survive, 2 center above 50%, 3 no broken wall) with small bonuses, using the Kenney UI stars | Stars persist in save |
| 7.9 | Relics: first-clear reward, permanent global perks | Relic list screen and effects |
| 7.10 | Replay and 2x auto-battle on 3-starred sections | Auto-battle farms gold and shards |
| 7.11 | Endless mode (after section 10; +8% budget per wave) with leaderboard stub | Local leaderboard works; online optional |
| 7.12 | Balance spreadsheet simulating player power per section (start by week 5) | Targets from the design doc: ~70% first-try clear on story, ~35% on boss sections |
| 7.13 | Remaining defenses from the design doc: cannon (Bone Marsh unlock), spike trap, oil pot (Ash Mountains unlock, burning lane) | Each is placeable once unlocked by its region clear and Workshop level |

---

## M8 – Polish, balance and release (3 wk)

| # | Task | Done when |
| --- | --- | --- |
| 8.1 | Juice pass 2: close-call slow-mo (<15% TC), victory camera pull-back, chest burst | Matches the juice checklist |
| 8.2 | Audio v2: per-region music, boss stinger, more SFX variants | Audio sign-off |
| 8.3 | Full balance pass using playtest data; adjust B0, growth rates, costs in one resource file | Clear rates inside the targets |
| 8.4 | Settings (sound, vibration, language stubs), pause, accessibility checks | Works on touch and mouse |
| 8.5 | Rewarded ads integration (optional, no energy timers) | Test ads show and reward correctly |
| 8.6 | Android + iOS builds, store listing assets, privacy policy | Internal-testing builds installed |
| 8.7 | PC build for itch/Steam, 9:16 and windowed layouts | Both layouts verified |
| 8.8 | Crash and analytics hooks (funnel: battle 1, upgrade 1, section 6) | Dashboards receive test events |
| 8.9 | Soft launch and fix list | Top 10 issues closed |

---

## Design decisions made in this plan

| Decision | Detail |
| --- | --- |
| Region table decides unlocks | Archers, Spearmen and the Ranger arrive when Greenfields (section 6) is cleared. The first-hour minute table is a pacing target only |
| Runners are Soldier-counterable and appear in section 3 | The design doc says Runners "punish no-archer builds", but Archers unlock after section 6. Runners are tuned so Soldiers handle them (tasks 2.6, 6.18, 6.19), and first appear in section 3 (the third section, index 2 in the design doc's 0-based budget formula). Their Archer-counter role only applies from the second region on |
| Unlocks the region table doesn't cover | Arrow tower and cards on section 2 clear, stone wall on Walls level, unit evolution on unit level. Stored in `UnlockData`, so changing them is a data edit |
| Section numbering | Sections are 1-based everywhere in this plan, as on the world map. The design doc's budget and enemy-cost tables use a 0-based index (`s`) |

---

## Risks, cut list and dependencies

| Risk | Mitigation |
| --- | --- |
| Horde performance on mobile | Solved in M4 with real skeleton meshes, before art or content; stay inside the visible cap |
| Too many systems | Cut order: Raid camps, Daily siege, Engineer hero, then Endless leaderboard |
| Balance drift | All numbers in Resources; spreadsheet simulation from week 5 |
| Asset mismatch (six KayKit packs plus Kenney UI) | Palette and recolor pipeline decided in M5, before more packs |
| Remaining asset gaps | See *Remaining gaps*: combat SFX, music loops, non-skeleton bosses, some building and defense models. Each has a decision point before the milestone that needs it |
| Animation clip names unverified | Task 0.8 lists them; if a needed clip is missing, use procedural recoil as the zero-cost fallback |
| License mix (KayKit and Kenney in one folder) | Credits file lists each pack separately (task 5.10); confirm terms on each pack page |
| Fun not proven | Fun Gate in M3 stops progression work until the battle is replayable |

### Dependencies

M1 and M2 can overlap after M0. M3 needs M2. M4 needs a working M3 battle. M5 needs M4. M6 needs M5 and the Fun Gate. M7 needs M6. M8 starts when M7 content is feature-complete.
