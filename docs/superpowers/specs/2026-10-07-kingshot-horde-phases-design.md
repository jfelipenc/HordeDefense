# Hold the Hearth – Game Design (Kingshot-style horde phases)

Oct 7, 2026 · replaces *Horde Defense Village Game – Design Document* and *Hold the Hearth – Implementation Plan*

## 1. Overview and intent

**Hold the Hearth** is a 3D low-poly horde-defense game for mobile and PC, built in Godot 4. The player defends a town behind a wall through a **20-wave horde event** in the style of Kingshot's Viking Vengeance, then spends the rewards to grow the town between battles.

**What changed from the previous design.** The first design used Last War as its reference: a gate run (math gates that multiply the squad) followed by a wall hold. That was the wrong reference and the gate run is removed entirely. Kingshot is the reference now, and the structured defense of escalating waves, with milestone waves that change the problem, is the most important feature.

### What the player asked for (source of truth)

- Resemble **Kingshot**. Last War was a wrong reference.
- Most important feature: **phases of defending against hordes**.
- Phase shape: **Viking Vengeance** style. One defensive line, numbered waves, milestone waves. Four phases of five waves, milestones at waves **5, 10, 15, 20**.
- Player agency: **pre-set formation, then light tactics**. Decisions are made at the regroup between phases. During waves the player only taps a hero skill and a cavalry sortie.
- Troop model: **Infantry / Cavalry / Archers** with the Kingshot counter triangle.
- Losses: troops die during the battle, **60% of a phase's losses return at each regroup**, all troops return after the battle.
- Clear scope: remove the gate-run code and replace both docs. Keep the M0 foundation (autoloads, scene swapper, debug panel, asset pipeline, test runner).

### Assumptions to confirm during review

- Kingshot facts come from community guides, not official sources, and the guides disagree in places. The design borrows the troop triangle, the tower-defense-around-the-walls idea and the Viking Vengeance wave structure. It does not try to copy Kingshot's alliance, rally or timer systems.
- "Hold the Hearth" stays as the working title.
- Single player only. No alliances or online coordination.

### Design pillars

- **Readable at a glance.** Any screenshot shows: our troops, their horde, the wall, the Town Center, and the wave counter.
- **Phases give the battle its shape.** The wave counter and the four phases are always on screen. A milestone wave must feel different from the waves around it.
- **Decide before, watch during.** The interesting choices are made at the regroup. The assault is where the choice pays off or fails.
- **Big numbers, short sessions.** A battle is 4–5 minutes. Damage numbers, troop counts and kill counters are always visible.
- **Progression lives outside the fight.** Upgrades happen in the village. The village is also the scoreboard, since every upgrade changes how the town looks behind the wall.

### Target

- **Audience:** casual-to-midcore players who clicked on Kingshot-style ads and wanted the defense game.
- **Platform:** Android/iOS portrait first, PC (Steam/itch) in a 9:16 or windowed layout second.
- **Business model (suggested):** premium or ad-light free-to-play with rewarded ads only. No energy timers blocking battles.

## 2. Core loop

1. **Defend** one stage: a 20-wave horde event.
2. **Collect** gold and hero shards by waves reached.
3. **Upgrade** buildings, troop tiers, towers and heroes in the village. Every upgrade is instant.
4. **Choose** the next stage using its recommended power, then defend again.

Timescales:

- **Moment to moment (seconds):** watch the wave, tap the hero skill, tap a section for a cavalry sortie.
- **Session (5–8 minutes):** one battle plus one or two upgrades.
- **Meta (days):** clear stages, raise troop tiers, unlock heroes, then chase Endless Horde scores.

## 3. Battle structure

A battle is one defense on one wall in front of the Town Center. The player wins by killing the wave 20 boss. The player loses when the Town Center's HP reaches 0.

### Phases and milestone waves

| Phase | Waves | Milestone wave | What the milestone does |
| --- | --- | --- | --- |
| 1 | 1–5 | **5: Flank** | A second group arrives from the side and hits one wall section. It tests how troops are spread. |
| 2 | 6–10 | **10: Keep strike** | A ram group ignores the wall and heads straight for the Town Center. It is a priority-kill problem. |
| 3 | 11–15 | **15: Siege** | Siege units fire at the wall from outside tower range. It forces cavalry or a hero skill. |
| 4 | 16–20 | **20: Boss** | A boss with escorts. The last wave. |

Escalation across phases:

- Phase 1 teaches the lanes with Raiders.
- Phase 2 adds Riders.
- Phase 3 adds ranged Bowmen and Siege.
- Phase 4 mixes everything at the highest budget.

### Within a phase

Waves follow each other with a short breather (about 4 seconds). There are no menus. A wave takes about 8 seconds of active fighting, so a full battle is about 4–5 minutes including regroups.

### Regroup (between phases)

A regroup of about 15 seconds sits after waves 5, 10 and 15 (and one before wave 1, as the initial setup). At the regroup the player can:

- Change the troop ratio and the section assignment (see section 4).
- Place or change towers in the 6 slots.
- Read the **scout preview** of the next phase: enemy mix and where they come from.

At the regroup the game also:

- Returns 60% of the phase's troop losses.
- Resets the hero skill cooldown.
- Repairs wall sections by a fixed share (provisional: 30% of max HP).

The regroup has a visible countdown, and the player can start the next phase early.

### Battlefield layout (portrait)

- **Top third:** the horde spawn edge and terrain from the stage's region.
- **Middle:** the kill zone with 3 lanes, one per wall section.
- **Bottom third:** the wall (3 sections: left, center, right), troops behind it, the 6 tower slots on the wall, and the Town Center with visible village buildings at the very bottom.
- **Flank entrance (wave 5):** a side entrance to the left or right section. The scout preview marks it.

### Win, lose and rewards

- **Win:** the wave 20 boss dies.
- **Lose:** Town Center HP reaches 0. A broken wall section opens its lane to the Town Center.
- Rewards scale with the highest wave reached, so a loss still pays something.
- **Stars:** 1 = win, 2 = Town Center above 50%, 3 = no wall section broken. Stars give a small bonus, not a hard gate.

## 4. Troops and formation

### Troop types

| Troop | Role | Strong against | Weak against |
| --- | --- | --- | --- |
| Infantry | Holds the wall. Highest HP, and raises the durability of its wall section. | Cavalry | Archers |
| Cavalry | Reserve. Charges out on tap to hit a section. | Archers | Infantry |
| Archers | Behind the wall. Highest damage, fragile. | Infantry | Cavalry |

Enemy Raiders, Riders and Bowmen follow the same triangle. A counter-matchup multiplies damage by a provisional 1.5 and the countered side by 0.75. Rams, Siege and the Boss are outside the triangle.

### Formation

- **March capacity** is the total troops fielded, set by the Town Center level.
- The player sets the **ratio** of the three types, for example 50/20/30, and assigns each type's share to the three wall sections.
- Formation is set at the first regroup and can be changed at each later regroup.
- The default formation is recommended by the game based on the stage's enemy mix, which keeps new players safe.

### Troop display

Troops are numbers on screen. A visible squad of models stands in for them (for example, one model per 100 troops). The numbers are the real values and the models are decoration.

### Light tactics during a wave

- **Hero skill:** tap, with a cooldown (8–20 s).
- **Cavalry sortie:** tap a wall section and that section's cavalry charges out for 4 seconds (3x damage, reach 22 m), then returns. Cavalry that are not sortieing fight at the wall at half damage. One shared 10-second cooldown; it only works in a section that has cavalry.
- Nothing else is live. Towers and formation change only at a regroup.

### Losses

- Troops die during waves.
- At each regroup, 60% of that phase's losses return as healed wounded. The other 40% are gone for this battle only.
- After the battle all troops return. Units are never permanently lost.

## 5. Heroes

One hero per battle stands on the wall. Each hero has a **tap skill** and a **passive** that buffs a troop type, as Kingshot heroes do.

| Hero | Buffs | Tap skill | Passive |
| --- | --- | --- | --- |
| Knight Captain | Infantry | Shield bash knocks back a section | Infantry +15% HP |
| Ranger | Archers | Arrow rain on a circle | Archers +10% attack speed |
| Mage | Towers | Fire meteor, burns 3 s | Tower damage +20% |

No cavalry hero yet. A fourth hero is decided after the vertical slice.

## 6. Enemies

| Enemy | Triangle role | Behavior | Appears |
| --- | --- | --- | --- |
| Raider | Infantry-type | Walks to the wall and attacks it. The bulk of every wave. | Wave 1 |
| Rider | Cavalry-type | Fast. Picks the least-defended section and goes for the archers behind the wall. | Phase 2 |
| Bowman | Archer-type | Stops 8 m from the wall and shoots the wall and the troops on it (half each). | Phase 3 |
| Ram | Off-triangle | Slow, high HP. Reserved for wave 10, where it ignores the wall and hits the Town Center directly. | Wave 10 |
| Siege | Off-triangle | Stops 18 m from the wall and fires from there. Archers (12 m) and towers (10–14 m) cannot reach it; only a cavalry sortie (22 m) or the hero skill can. Reserved for wave 15. | Wave 15 |
| Boss + escorts | Off-triangle | Wave 20 only. | Wave 20 |

Enemy silhouettes must be readable at 40 px tall. Scale, tint and a held item differentiate reused models.

## 7. Towers

- 6 slots, two per wall section. Placement happens at a regroup and is fixed during a phase.
- **Arrow tower:** fast and cheap. Strong against Riders and Bowmen.
- **Crossbow tower:** slow, piercing. Strong against Raiders and Rams.
- **Cannon tower:** splash damage. Strong against dense packs and Siege.
- Slots and tower types unlock through the Workshop in the village.

## 8. Difficulty and wave budget

Difficulty is driven by the wave budget of each wave in a stage. The spawner buys enemies from the stage's allowed list until the budget is spent.

```latex
\text{budget}(L, w) = B_0 \cdot g_L^{\,L} \cdot g_w^{\,w} \cdot m(w)
```

- L is the stage index (0, 1, 2…) and w is the wave index (1–20).
- m(w) is the milestone multiplier: 1.0 for ordinary waves and about 1.5 for waves 5, 10, 15 and 20.
- Provisional values: B0 = 100 points, g_L = 1.12, g_w = 1.10. The special group of a milestone wave takes a share of that wave's budget: 40% for the wave 5 flank, 10% for the wave 10 rams and the wave 15 siege units, and 50% for the wave 20 escorts (the boss itself is free).
- Enemy HP and damage scale separately and more gently: `enemyStat(L) = base · 1.06^L`.

Splitting growth between **count** (budget) and **stats** keeps hordes looking bigger every stage while each enemy still dies in a satisfying number of hits.

### Enemy costs (provisional)

| Enemy | Cost (points) | First stage |
| --- | --- | --- |
| Raider | 1 | 1 |
| Rider | 2 | 1 |
| Bowman | 3 | 1 |
| Ram | 8 | 1 (wave 10 only at first) |
| Siege | 10 | 1 (wave 15 only at first) |
| Boss | Fixed, wave 20 | Every stage |

### Safety valves

- **Rubber band:** after 2 losses on a stage, the next attempt gets a free full heal at one regroup, shown as "The horde is tired".
- **Endless Horde:** unlocked after the last stage. Waves continue past 20 on a budget that keeps rising, with a leaderboard.
- **Tuning knobs** (one resource, `resources/tuning/default.tres`): B0, g_L, g_w, m(w), the three milestone shares, the stat growth, per-enemy cost, the triangle multipliers, the heal and repair shares, wall and Town Center HP, and the sortie numbers. Tune with a spreadsheet that simulates player power per stage.

**Open question:** target clear rate on first attempt. A starting suggestion is 70% on ordinary stages and 35% on boss-heavy stages.

## 9. Progression and the village

Two currencies, one village screen and no timers. Every upgrade is instant.

| Currency | Earned from | Spent on |
| --- | --- | --- |
| Gold | Every kill, wave and battle | Buildings and troop tiers |
| Hero shards | Boss kills and first clears | Unlocking and starring heroes |

### Village screen

The village is a 3D diorama around the Town Center with a big **DEFEND** button. Each building shows one upgrade button with its cost and the next stat.

| Building | Effect in battle |
| --- | --- |
| Town Center | Its level caps every other building. Raises march capacity and Town Center HP. |
| Barracks / Stables / Archery Range | Troop tier for Infantry / Cavalry / Archers (T1 → T4): more HP and damage and a new model look. |
| Walls | Wall section HP and visual tier (wood, stone, iron). |
| Workshop | Tower slots, tower types and levels. |
| Tavern | Hero roster, levels and stars. |

### Rules that keep progression readable

- **Town Center is the gate.** No building can exceed its level.
- **One recommended upgrade.** After each battle, an arrow points at the upgrade that addresses what went wrong (a wall section broke → Walls; archers died → Archery Range).
- **Power score.** Every stage shows a recommended power. The village shows the player's. Green, yellow or red tells them whether to fight or upgrade.
- **Tier evolution, not equipment.** Troop tiers change model and add one trait.
- **No permanent losses.**

### Unlock pacing (first hour target)

| Minute | Unlock |
| --- | --- |
| 0 | Infantry, Knight Captain, wood wall, stage 1 with a preset formation |
| 3 | Archers, first village upgrade |
| 8 | Cavalry and the cavalry sortie, first tower slot (arrow) |
| 15 | First boss reward, Ranger hero, crossbow tower |
| 25 | Troop tier 2, second region visible |
| 40 | Stone wall, cannon tower |
| 60 | Mage hero, tier 3 |

## 10. Stages and content

30 stages in 5 regions of 6. Each stage is one 20-wave event.

| Region | Stages | Theme enemy | Boss | Unlocks on clear |
| --- | --- | --- | --- | --- |
| Greenfields | 1–6 | Raiders, Riders | Goblin Warchief | Archers, Cavalry, Ranger |
| Dark Forest | 7–12 | Bowmen, climbing raiders | Treant | Mage hero |
| Bone Marsh | 13–18 | Skeleton swarms, Siege | Lich | Iron walls, cannons |
| Ash Mountains | 19–24 | Rams, fire enemies | Ogre King | Tier 3 |
| Fallen Capital | 25–30 | All types, mixed | Horde Lord | Endless Horde |

- Every third stage has a **twist** (night with limited vision, fog lanes, double boss, enemies from behind) to keep battles fresh with the same assets.
- Cleared stages stay replayable for gold and shards. An auto-battle at 2x speed unlocks once a stage is 3-starred.

## 11. UI and game feel

Every action produces a number, a sound and a bit of motion within 100 ms.

### Battle HUD (portrait)

- **Top:** wave counter ("Wave 7/20"), a **phase bar** with the four phases and the milestone waves marked, horde remaining, pause.
- **Middle:** the battlefield.
- **Bottom:** troop count per wall section, hero portrait with skill cooldown ring (big thumb target), cavalry sortie buttons on the sections, Town Center HP bar.
- **Regroup screen:** formation sliders and section assignment, the six tower slots, the scout preview, a countdown and a "Ready" button.

### Juice checklist

- Floating damage numbers; crits in larger yellow text; the kill counter ticks up with a soft click.
- Milestone wave banner ("Wave 10: Keep strike!") with a short horn.
- Hit-stop of 40–60 ms on boss hits and hero skills; small camera shake on wall impacts.
- Coins fly from dead enemies toward the gold counter.
- Wall sections crack in 3 visual stages before breaking.
- Close-call slow motion when Town Center HP drops below 15%.
- Victory: the horde shatters, the camera pulls back to show the village, a reward chest bursts.

### Onboarding

The first battle starts before any menu: stage 1 with a preset formation, a guided first regroup, and a wave 5 flank the player can't lose. The village is introduced after that win with exactly one upgrade to buy.

## 12. Art and audio

The whole game can ship on KayKit characters plus Kenney environments and audio. Both share a chunky low-poly flat-color style, so they mix well with one shared palette. Assets already imported are listed in `assets/ASSETS.md`.

### Asset plan

| Need | Pack | Notes |
| --- | --- | --- |
| Heroes and player troops | KayKit Adventurers 2.0 FREE | Knight, Barbarian, Mage, Rogue, Ranger; rigged and animated. Infantry = Barbarian or Knight, Archers = Ranger, Cavalry = Rogue (no mount available, see gaps) |
| Horde | KayKit Skeletons 1.1 FREE | Raider = Skeleton_Warrior, Rider = Skeleton_Rogue, Bowman = Skeleton_Minion with a held item, Ram/Boss = Skeleton_Warrior scaled up |
| Animations | KayKit Character Animations 1.1 | One rig for all KayKit characters |
| Village and walls | KayKit Medieval Hexagon 1.0 FREE | Buildings, towers, fences/walls, props |
| Battlefield dressing | KayKit Forest Nature 1.0 FREE | Trees, bushes, rocks |
| Props | KayKit Dungeon 1.1 FREE | Barriers, banners, coins, chests, crack stages |
| UI and UI sounds | Kenney UI Pack, Kenney Interface Sounds | HUD |
| Towers and projectiles | Kenney Tower Defense Kit (in `D:\ASSETS`, not yet imported) | Cannon and crossbow tower models. Check the license on import and record it in the credits file |

### Gaps to decide before they block a milestone

- **No cavalry mount model:** use Rogue with a gallop-style animation, or a different silhouette, until a mount is found. Decide in M2.
- **Combat SFX, coin sounds and music loops:** not in the imported packs. Decide in M5.
- **Siege and boss models:** re-skin existing models (scale, tint, props) unless a CC0 monster pack is added. Decide before M3.
- **HUD icons, hero portraits and the cooldown ring:** draw simple icons in Godot and render portraits from the character models. Decide in M5.

### Style rules

- **One palette:** recolor everything through a shared gradient texture so KayKit and Kenney match. The player side uses blue banners, the horde uses red/purple.
- **Silhouette first:** each enemy type is readable at 40 px tall.
- **Tier visuals:** tier changes swap weapon and helmet attachments plus a tint (bronze → silver → gold).
- **Camera:** fixed 3/4 top-down, slight perspective.

## 13. Godot technical architecture

Godot 4 with GDScript, a small set of autoloads, one scene per screen, and every number stored in Resource files so balancing never touches code.

### Horde performance (the make-or-break part)

Hundreds of enemies on a phone won't work as individual CharacterBody3D nodes with full skeletons.

- **No physics bodies for enemies.** Enemies are plain data (position, HP, lane, state) in arrays updated by a HordeManager each frame. Lanes are 1D: an enemy needs only its distance along the lane and a small sideways offset.
- **MultiMeshInstance3D per enemy type.** One draw call per type, animated with a bob/tilt shader or baked vertex animation instead of skeletons.
- **Skeletal animation only for heroes, bosses and the closest troops.**
- **Spatial bucketing per lane** for targeting.
- **Pooled damage numbers and projectiles.**
- **Soft cap on visible enemies** around 300–500 on mobile; extra enemies queue off-screen.
- Troops are numbers plus a small number of stand-in models, so troop simulation is a few per-section aggregates, not individual units.
- Profile early on a low-end Android device with the Mobile renderer.

### Systems

- **BattleController:** owns the wave counter, the phase state machine (assault → breather → regroup) and the milestone events.
- **WaveSpawner:** reads a `StageData` and spends the wave budget.
- **HordeManager:** enemy arrays, movement, targeting and MultiMesh updates.
- **WallSection / TownCenter:** HP and break behavior.
- **TroopSimulation:** per-section aggregates by troop type, damage resolution with the triangle multipliers, losses and healing.
- **TowerController, HeroController, SortieController:** the live player-triggered and automatic effects.
- **RegroupScreen:** the formation, tower and scout-preview UI.

### Data classes (Resources)

- `StageData` (replaces `SectionData`): stage index, region, allowed enemies, twist.
- `TuningData`: every balance number, in one `.tres`.
- `WaveData`: a runtime object (not an authored file) built by `WaveSpawner`: budget, milestone type and the list of spawns.
- `EnemyData`: gains a triangle type and a target behavior (wall, archers, Town Center).
- `TroopData` (replaces `UnitData`): type and tier.
- `TowerData`: new.
- `HeroData`: gains the troop type it buffs.
- `CardData` is removed.
- Tuning values (B0, growth rates, milestone multiplier, triangle multipliers, heal share) live in one resource file.

### Practical conventions

- `SceneSwapper` swaps scenes with a fade. `GameState` holds progress. `SaveManager` writes JSON to `user://` after every battle and upgrade.
- `EventBus` signals (`enemy_killed`, `wall_damaged`, `wave_started`, `wave_cleared`, `phase_cleared`, `regroup_started`, `battle_ended`) decouple the HUD and audio from gameplay. The gate-run signals are removed. Class scripts (`Battle`, `PhaseMachine`) emit their own signals and the battle scene forwards them to `EventBus`, because class scripts cannot name autoloads when the headless test runner compiles them.
- The debug panel gains: spawn wave N, jump to a phase, set the stage, add gold, 4x speed.
- Headless tests cover the pure logic: wave budget, triangle math, loss and healing, phase state machine.

## 14. What changes in the repository

### Deleted

- Scripts: `gate_run`, `squad`, `squad_state`, `formation`, `gate_data`, `gate_pair_data`, `gate_view`, `blocker_data`, `wall_placeholder`.
- Scenes: `Gate.tscn`, `WallPlaceholder.tscn`.
- Resources: `resources/gates/*`, `resources/sections/section_test.tres`, `resources/cards/*`, `resources/units/soldier.tres` (replaced by troop data).
- Tests: `test_gate_math`, `test_formation`, `test_squad`, `test_gate_run`, `test_handoff`. `test_resources` is deleted only if it covers gates alone.
- `CardData` and the old design and plan documents.

### Kept, with edits

- `SceneSwapper`, `DebugPanel`, `SaveManager`, the headless test runner.
- The KayKit/Kenney import pipeline and `assets/ASSETS.md`.
- `GameState`: loses `barracks_cap`, `base_squad_size` and `relics`; gains march capacity and the stage index.
- `EventBus`: gate signals out, phase and wave signals in.
- `main.gd`: rewritten.
- `README.md`: updated to match.

## 15. Development roadmap

Build the battle first with grey boxes, and move on only when a battle is fun to replay without any progression attached.

| Milestone | Goal |
| --- | --- |
| M0 | Foundation. Already done. Minimal edits only. |
| M1 | Battle core: wall with 3 sections, Town Center, enemies walking lanes, the 20-wave budget spawner and the wave counter. |
| M2 | Troops and regroup: three troop types, the counter triangle, the formation screen, losses and 60% healing. |
| M3 | Phases and milestones: the four milestone waves, towers, hero skill, cavalry sortie. **Fun Gate:** a stage is fun to replay with grey boxes. |
| M4 | Horde performance: 300+ enemies at 60 fps on a mid-range phone. **Perf Gate.** |
| M5 | Vertical slice: real art and juice. **Look Gate.** |
| M6 | Village and progression. |
| M7 | Stages, regions and Endless Horde. |
| M8 | Polish, balance, release. |

Detailed tasks and sizes belong to the implementation plan, which comes after this document is approved.

### Prototype checklist (M1–M3)

- [x] Wall with 3 sections and HP; enemies walk lanes and attack it
- [x] Wave budget spawner reading one `StageData` resource
- [x] 20 waves in 4 phases with a visible phase bar
- [x] Regroup screen: formation, towers, scout preview
- [x] Triangle math and 60% healing verified by tests
- [x] Flank, keep strike, siege and boss milestone waves
- [x] One hero tap skill and the cavalry sortie, each with a cooldown
- [ ] 200 enemies at 60 fps on a mid-range phone

### Scope risks

- **Horde performance on mobile:** solve in the prototype, not later.
- **The regroup screen:** it is the main decision UI and also the biggest UI risk. Prototype it with plain Control nodes in M2 before any art.
- **Milestone waves need distinct behavior:** each is a small special-case system. Build them one at a time and cut the Siege milestone first if behind.
- **Too many systems:** cut the cavalry sortie, Endless Horde and stage twists first.
- **Balance drift:** keep all numbers in Resources and run a spreadsheet simulation from the first vertical slice.
- **Asset mismatch:** pick the palette and recolor pipeline in the vertical slice, before mixing more packs.

## 16. Open questions

- Target first-attempt clear rate per stage type (starting suggestion: 70% ordinary, 35% boss-heavy).
- Whether the regroup should have a hard time limit or only the visible countdown with "Ready" to skip.
- Whether Cavalry needs its own hero (decide after the vertical slice).
- Whether the project keeps the working title.
