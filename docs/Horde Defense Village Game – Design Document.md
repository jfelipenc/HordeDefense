# Horde Defense Village Game – Design Document

Oct 7, 2026 · @João Felipe Nunes Carvalho

## Overview & hook

Working title: **Hold the Hearth**. A 3D low-poly horde-defense game for mobile and PC, built in Godot 4, where you hold a wall around your town center against ever-larger hordes and spend the loot to grow your village between battles.

**The hook, in one line:** *Run your army through the gates, then hold the wall.* Each battle has two beats the player recognizes from the first second of any trailer:

1. **Gate run (10–20 s):** your squad marches down a road and you steer it left or right through math gates (+10, x2, -5, "Archers +3"). The army visibly grows.
2. **Wall hold (60–120 s):** the multiplied army lines up on the wall in front of the town center and a horde floods in. You tap to drop hero skills and place quick defenses while hundreds of enemies pile up.

The gate run is the "ad feeling" (instant, readable, satisfying math). The wall hold is the real game. Losing a wall section shows enemies streaming toward the town center, which is the fail state.

### Design pillars

- **Readable at a glance.** Any screenshot should show: our army, their horde, the wall, the town center. No menus during combat beyond one pick-1-of-3 card.
- **Big numbers, short sessions.** A battle lasts 2–3 minutes. Damage numbers, army counts and kill counters are always on screen.
- **Progression lives outside the fight.** Upgrades happen in the village menu. In battle the player only decides gates, skill timing and one card per wave.
- **The village is the scoreboard.** Every upgrade changes how the town looks behind the wall, so progress is visible in battle too.

### Target

- **Audience:** casual-to-midcore players who clicked on Last War or Kingshot style ads and wanted the ad game.
- **Platform:** Android/iOS portrait first, PC (Steam/itch) in a 9:16 or windowed layout second.
- **Business model (suggested):** premium or ad-light free-to-play with rewarded ads only. No energy timers blocking battles.

## Core loop

The game runs on one tight loop: upgrade in the village, fight one section, bring loot home. Battles are short enough that the player always feels "one more".

&#91;embedded content: core loop · 6 steps\]

The loop works on three timescales:

- **Moment to moment (seconds):** pick a gate, tap a hero skill, watch numbers fly.
- **Session (3–5 minutes):** one full battle plus one or two upgrades.
- **Meta (days):** clear regions, evolve unit types, unlock heroes, then chase Endless mode scores.

## Battle gameplay

A battle is one gate run followed by 3–5 horde waves on the same wall, ending in a boss wave. The player wins by keeping the town center alive until the last wave dies.

### Battlefield layout (portrait)

- **Top third:** horde spawn edge, terrain from the current map section (forest, swamp, ruins).
- **Middle:** kill zone with 2–3 lanes. Some lanes have traps or rubble that slow enemies.
- **Bottom third:** the wall (3 segments: left, center, right), your units behind it, the town center and visible village buildings at the very bottom.

### Gate run

- Squad starts at its base size (from village upgrades, e.g. 20 soldiers).
- 4–6 gate pairs appear. The player drags left/right; the squad passes through one gate per pair.
- Gate types: **additive** (+8), **multiplier** (x2), **negative** (-10, shown in red), **type** ("+5 Archers"), **buff** ("+20% fire damage this battle").
- A small enemy group can block the road mid-run so the player sees combat before the wall.
- The final count is capped by **Barracks capacity** so gates feel big without breaking balance. Overflow converts to gold.

### Wall hold

- Units auto-deploy to wall segments in proportion to lane threat; the player can drag a squad icon to shift units between segments.
- Each wall segment has HP. If it breaks, enemies in that lane walk to the town center.
- Town center HP at 0 = defeat. Rewards scale with waves survived, so a loss still pays something.
- Between waves (5 s pause): **pick 1 of 3 cards** (e.g. "Archers fire twice", "Repair wall 30%", "Spawn 2 catapults"). This is the only in-battle decision screen.

### Hero

One hero per battle stands on the wall and auto-attacks. Each hero has a **tap skill** with a cooldown (8–20 s) and a passive.

| Hero | Role | Tap skill | Passive |
| --- | --- | --- | --- |
| Knight Captain | Tank | Shield bash knocks back a lane | Wall segments +15% HP |
| Ranger | DPS | Arrow rain on a circle | Archers +10% attack speed |
| Mage | AoE | Fire meteor, burns 3 s | Fire damage +20% |
| Engineer | Support | Drops a turret for 15 s | Defenses repair 1%/s |

### Units (player side)

| Unit | Range | Strength | Counter to |
| --- | --- | --- | --- |
| Soldier | Melee on wall | Cheap, high HP | Swarmers |
| Archer | Long | High single-target DPS | Fast runners |
| Spearman | Short | Bonus vs large enemies | Brutes |
| Mage | Medium | Splash damage | Dense packs |

Units fight from behind the wall. Melee units only engage enemies touching the wall, which keeps the simulation cheap.

### Defenses (built in the village, placed per battle)

- **Arrow tower**, **cannon**, **spike trap**, **barricade** (extra wall HP on one segment), **oil pot** (lane-wide burn).
- Defense slots per wall segment are unlocked in the village. Placement is a drag before wave 1, then locked.

### Horde (enemy side)

| Enemy | Behavior | Why it exists |
| --- | --- | --- |
| Grunt | Walks straight | Bulk of every wave |
| Runner | Fast, low HP | Punishes no-archer builds |
| Brute | Slow, huge HP, hits walls hard | Punishes no-spear builds |
| Shaman | Heals or buffs nearby | Priority target for hero skills |
| Climber | Ignores wall, jumps to units | Forces backline defense |
| Siege | Ranged, targets wall from afar | Forces push or catapults |
| Boss | One per battle, 50–100x Grunt HP | Climax of the fight |

## Progression

Progression uses three currencies, one village screen and no timers: every upgrade is instant, so the player is always one tap away from the next battle.

### Currencies

| Currency | Earned from | Spent on |
| --- | --- | --- |
| Gold | Every kill, wave and battle | Building and unit upgrades |
| Hero shards | Boss kills, section clears | Unlocking and starring heroes |
| Relics | First clear of each map section | Permanent global perks (rare, chunky) |

### Village screen

The village is one 3D diorama around the town center with a big **FIGHT** button. Each building is tappable and shows a single upgrade button with cost and the next stat.

| Building | Upgrades | Battle effect |
| --- | --- | --- |
| Town Center | Levels 1–30, gates all other building caps | Town center HP, unlocks new buildings |
| Barracks | Base squad size, army cap | Starting count and gate-run cap |
| Archery Range / Spear Hall / Mage Tower | Per-unit-type level | Damage and HP of that unit type, unlocks unit types |
| Walls | Wall level | Segment HP and visual tier (wood, stone, iron) |
| Workshop | Defense types and levels | Towers, traps, slots per segment |
| Tavern | Hero roster, hero levels and stars | Hero stats and skill upgrades |
| Treasury | Gold bonus % | Faster economy, a soft catch-up tool |

### Rules that keep progression out of the fight

- **Town Center is the gate.** No building can exceed TC level. One number tells the player how strong they are.
- **One recommended upgrade.** After each battle, a glowing arrow points at the cheapest upgrade that fixes what killed you (wall broke → Walls; runners leaked → Archery Range).
- **Power score.** Every map section shows a recommended power; the village shows yours. Green, yellow or red tells the player whether to fight or upgrade.
- **Unit evolution, not equipment.** Every 10 levels a unit type evolves (Soldier → Knight → Paladin), changing its model and adding one trait. That's the big, visible milestone.
- **No losses of stuff.** Units are not consumed; a battle never makes you weaker.

### Unlock pacing (first hour target)

| Minute | Unlock |
| --- | --- |
| 0 | Soldiers, Knight Captain, wood wall, first gate run |
| 3 | Archers + first village upgrade tutorial |
| 8 | Arrow tower, pick-1-of-3 cards |
| 15 | First boss, Ranger hero |
| 25 | Spearmen, second map region visible |
| 40 | Stone wall, cannon, first unit evolution |
| 60 | Mage unit and hero, relics |

## Difficulty scaling

Difficulty is driven by one number, the **threat level** of each battle, which grows about 12% per map section while player power from a full upgrade pass grows about 15%. Players who keep upgrading slowly pull ahead; players who rush fall behind and are nudged back to the village.

### Wave budget

Each wave gets a point budget. The spawner buys enemies from the section's allowed list until the budget is spent.

```latex
\text{budget}(s, w) = B_0 \cdot 1.12^{s} \cdot (1 + 0.35\,w)
```

where s = map section index (0, 1, 2…), w = wave index inside the battle (0–4), B0 = 100 points. Enemy HP and damage scale separately and more gently:

```latex
\text{enemyStat}(s) = \text{base} \cdot 1.06^{s}
```

Splitting growth between **count** (budget) and **stats** keeps hordes looking bigger every section, which is the fantasy, while each enemy still dies in a satisfying number of hits.

### Enemy costs

| Enemy | Cost (points) | First section |
| --- | --- | --- |
| Grunt | 1 | 0 |
| Runner | 2 | 2 |
| Brute | 8 | 4 |
| Shaman | 6 | 7 |
| Climber | 4 | 10 |
| Siege | 10 | 14 |
| Boss | Fixed, last wave | Every section |

### Wave shape inside a battle

- Wave 1: mostly Grunts, teaches the lane layout.
- Waves 2–3: introduce the section's "theme" enemy (e.g. a Runner-heavy swamp).
- Wave 4: a spike, about 1.6x the previous budget, often from two lanes at once.
- Final wave: boss plus escorts. Boss HP = 60x Grunt HP x section stat multiplier.

### Safety valves

- **Rubber band:** after 2 losses on the same section, the next attempt gets +1 free card pick and a one-time 10% threat reduction (shown honestly as "The horde is tired").
- **Endless mode:** unlocked after section 10. Budget keeps rising 8% per wave forever, with a leaderboard. This is the long-term retention loop and a great source for trailer footage.
- **Tuning knobs** (one resource file): B0, the 1.12 and 1.06 growth rates, per-enemy cost, wave multiplier 0.35. Tune with a spreadsheet that simulates player power per section.

**Open question:** target clear rate on first attempt. A starting suggestion is 70% on story sections, 35% on boss sections.

## World map & content structure

The world map is a fog-covered island around your village, split into 5 regions of 6 sections each (30 sections at launch). Clearing a section lifts the fog, and the cleared land visibly becomes part of your kingdom (farms, banners, a road).

| Region | Sections | Theme enemy | Boss | Unlocks on clear |
| --- | --- | --- | --- | --- |
| Greenfields | 1–6 | Grunts, Runners | Goblin Warchief | Archers, Spearmen, Ranger |
| Dark Forest | 7–12 | Shamans, Climbers | Treant | Mage Tower, Mage hero |
| Bone Marsh | 13–18 | Skeleton swarms, Siege | Lich | Iron walls, cannons |
| Ash Mountains | 19–24 | Brutes, fire enemies | Ogre King | Engineer, oil pots |
| Fallen Capital | 25–30 | All types, mixed | Horde Lord | Endless mode, prestige |

### Section rules

- Each section = one battle (gate run + waves + boss). First clear grants a relic and a big gold chest.
- Cleared sections stay replayable for gold and hero shards ("farm" with an auto-battle button at 2x speed once 3-starred).
- **Stars:** 1 = survive, 2 = town center above 50%, 3 = no wall segment broken. Stars give a small bonus, not a hard gate.
- Every 3rd section in a region has a **twist modifier** (night with limited vision, fog lanes, double boss, enemies from behind) to keep battles fresh with the same assets.

### Optional side content (post-launch)

- **Raid camps:** short battles where you attack a horde camp instead of defending, reusing the gate-run tech.
- **Daily siege:** one random section with a modifier and boosted rewards.

## UI/UX & game feel

The "ad feeling" comes from feedback, not from mechanics: every action produces a number, a sound and a bit of motion within 100 ms.

### Battle HUD (portrait)

- **Top:** wave counter ("Wave 3/5"), horde remaining bar, pause.
- **Middle:** nothing but the battlefield.
- **Bottom:** army count per wall segment, hero portrait with skill cooldown ring (big thumb target), town center HP bar.

### Juice checklist

- Floating damage numbers; crits in larger yellow text; kill counter ticks up with a soft click.
- Gate pass: squad flashes, count number pops and scales up, new units visibly spawn in.
- Hit-stop of 40–60 ms on boss hits and hero skills; small camera shake on wall impacts.
- Coins fly from dead enemies toward the bottom of the screen and land in a gold counter.
- Wall segments crack in 3 visual stages before breaking.
- "Close call" slow-motion when town center drops below 15%.
- Victory: horde shatters, camera pulls back to show the whole village, reward chest bursts.

### Village UX

- One screen, no submenus deeper than one level.
- Upgrade buttons show **what you get** ("+12% wall HP") rather than only a level number.
- A red dot appears only when an upgrade is affordable; the recommended one gets a bouncing arrow.
- The FIGHT button always shows the next section's power check color.

### Onboarding

The first battle starts before any menu: the game opens on a gate run, then a wall hold the player can't lose. The village is introduced after that win, with exactly one upgrade to buy.

## Art & audio (free or cheap assets)

The whole game can ship on KayKit characters plus Kenney environments and audio, for roughly $0–40 total. Both share a chunky low-poly, flat-color style, so they mix well with one shared palette.

### Asset plan

| Need | Pack | Cost | Notes |
| --- | --- | --- | --- |
| Heroes and player units | [KayKit Character Pack: Adventurers](https://kaylousberg.itch.io) | Free base, paid EXTRA tier | Knight, Barbarian, Mage, Rogue, Ranger; rigged and animated |
| Undead horde | KayKit Character Pack: Skeletons | Free base, paid extras | Perfect for Grunts, Runners, Shamans, Bone Marsh region |
| Shared animations | KayKit Character Animations | Free | Same rig for all KayKit characters, so one AnimationTree setup |
| Village and world map | KayKit Medieval Hexagon Pack | Free base | 200+ hex tiles and buildings; great for the world map and village diorama |
| Forests, rocks | KayKit Forest Nature Pack | Free base | Battlefield dressing |
| Walls, towers, gates | Kenney Castle Kit | Free (CC0) | Modular wall tiers, towers |
| Defenses, projectiles | Kenney Tower Defense Kit | Free (CC0) | Cannons, turrets, paths |
| Village extras | Kenney Fantasy Town Kit | Free (CC0) | Houses, market stalls, fences |
| UI | Kenney UI Pack (incl. RPG expansion) | Free (CC0) | Buttons, panels, bars |
| SFX | Kenney Impact Sounds, Interface Sounds, RPG Audio | Free (CC0) | Hits, clicks, coins |
| Extra monsters (orcs, ogres, bosses) | Quaternius animated monster packs | Free (CC0) | Fills enemy variety beyond skeletons |
| Music | Free CC0/CC-BY fantasy tracks (e.g. OpenGameArt) | Free | Two loops: village calm, battle drums |

If budget allows, the **Complete KayKit Collection** bundle covers every current and future KayKit pack in one purchase and unlocks the extra character variants.

### Style rules

- **One palette:** recolor everything through a shared gradient texture so KayKit and Kenney match. Player side uses blue banners, the horde uses red/purple.
- **Silhouette first:** each enemy type must be readable at 40 px tall. Use scale (Brutes 1.6x), color tint and a held item to differentiate reused models.
- **Evolution visuals:** unit evolutions swap weapon and helmet attachments plus a tint (bronze → silver → gold) instead of new models.
- **Camera:** fixed 3/4 top-down, slight perspective, so 3D assets look like the ads but stay readable in portrait.

### Licensing check

Kenney and Quaternius packs are CC0. KayKit free tiers are also released for commercial use, but confirm the exact license on each pack page before release and keep a credits file anyway.

## Godot technical architecture

Use Godot 4 with GDScript, a small set of autoloads, one scene per screen, and every number stored in Resource files so balancing never touches code.

&#91;embedded content: Godot project architecture · 3 layers\]

### Horde performance (the make-or-break part)

Hundreds of on-screen enemies on a phone will not work as individual CharacterBody3D nodes with full skeletons. Plan for this from day one:

- **No physics bodies for enemies.** Enemies are plain data (position, HP, lane, state) in arrays updated by HordeManager each frame. Lanes are 1D: an enemy only needs its distance along the lane and a small sideways offset.
- **MultiMeshInstance3D per enemy type.** One draw call per type. Animate with vertex animation textures (bake a walk and attack loop) or a simple bob/tilt shader instead of skeletal animation.
- **Skeletal animation only for heroes, bosses and the closest units.** KayKit rigs stay fully animated where the camera notices.
- **Spatial bucketing per lane** for targeting: archers and towers query the front N enemies of a lane rather than searching everything.
- **Pooled damage numbers** (Label3D or a 2D overlay pool of about 64) and pooled projectiles.
- **Soft cap on visible enemies** around 300–500 on mobile; extra enemies in a wave queue off-screen, so the horde still looks endless.
- Profile early on a low-end Android device with the Compatibility or Mobile renderer.

### Practical conventions

- Main.gd swaps scenes with a fade; GameState holds progress; SaveManager writes JSON to user:// after every battle and upgrade.
- EventBus signals (enemy\_killed, wall\_damaged, wave\_cleared, battle\_ended) keep the HUD and audio decoupled from gameplay.
- Cards, gates and twist modifiers are Resources with a small effect script, so new content is a new .tres file.
- Keep a debug panel: spawn wave N, set section, add gold, toggle 4x speed.

## Development roadmap

Build the battle first with grey boxes, and only move on when it's fun to replay without any progression attached. Progression can't save a dull fight, but a fun fight carries thin progression.

&#91;embedded content: roadmap · 4 phases, 3 gates\]

### Prototype milestone checklist

- [ ] Squad of capsules runs through 4 gate pairs; count updates live
- [ ] Wall with 3 segments and HP; enemies walk lanes and attack it
- [ ] Archers auto-target the front of each lane
- [ ] Wave budget spawner reading one SectionData resource
- [ ] One hero tap skill with cooldown
- [ ] 200 enemies at 60 fps on a mid-range phone
- [ ] Pick 1 of 3 card screen between waves

### Scope risks

- **Horde performance on mobile:** solve in the prototype, not later (see architecture).
- **Too many systems:** cut Raid camps, Daily siege and the Engineer hero first if behind schedule.
- **Balance drift:** keep all numbers in Resources and a spreadsheet simulation from week 5.
- **Asset mismatch:** pick the palette and recolor pipeline in the vertical slice, before mixing more packs.
