# Fun Gate: Hold the Hearth, stage 1 (M1-M3 prototype)

Status: PENDING HUMAN PLAYTEST (simulated criteria: FAIL)

Date: 2026-10-07

The simulated criteria FAIL on one point only: battle length. The plan's criterion is 4 to 6 minutes, and the two 600-troop tower wins take 370 s and 380 s, 10 to 20 s over that ceiling. The spec's binding target is stricter, 4 to 5 minutes including regroups, and against it no simulated run passes (details below). All other simulated criteria pass. No resource files were tuned. The Fun Gate itself (PASS or FAIL) is decided by a human after the hand playtest; nothing in this note decides it.

## Simulated balance

Run on 2026-10-07 with `godot --headless --path . -s res://tools/sim_battle.gd` (Godot 4.7.2). `BattleSim.run(battle, true)`: regroup countdowns are skipped, and the hero skill and cavalry sortie are fired on the busiest lane. The probe's "default" rows use the default `Formation` (ratio 50/20/30 infantry/cavalry/archers, shares spread evenly). The game does not open on that: it opens on the recommended formation for the first phase, which is all raiders, ratio `[2.5, 1.0, 6.5]` (65% archers); the last row below is that start. The "recommended" row fixes the hero as `knight_captain` and uses no towers.

```
cap 0, default, no towers          -> LOSE wave  1  tc     0  troops    0  kills    74    36s
cap 300, default, no towers        -> LOSE wave 14  tc     0  troops  237  kills  2323   271s
cap 600, default, no towers        -> LOSE wave 20  tc     0  troops  498  kills  4228   389s
cap 1000, default, no towers       -> WIN  wave 20  tc  2975  troops  999  kills  4229   351s
cap 1500, default, no towers       -> WIN  wave 20  tc  5000  troops 1500  kills  4229   334s
cap 2500, default, no towers       -> WIN  wave 20  tc  5000  troops 2500  kills  4229   317s
cap 600, default, arrow_tower      -> LOSE wave 20  tc     0  troops  517  kills  4228   390s
cap 600, default, crossbow_tower   -> WIN  wave 20  tc  1350  troops  596  kills  4229   370s
cap 600, default, cannon_tower     -> WIN  wave 20  tc   900  troops  597  kills  4229   380s
cap 600, archer-heavy              -> LOSE wave 20  tc     0  troops  599  kills  4228   367s
cap 600, all infantry              -> LOSE wave 15  tc     0  troops  572  kills  2714   296s
cap 600, recommended (game start)  -> LOSE wave 20  tc     0  troops  575  kills  4228   375s
```

Setup notes: the default runs use the `knight_captain` hero. "archer-heavy" is ratio `[3, 1, 6]` with the `ranger` hero and `arrow_tower`. "all infantry" is ratio `[1, 0, 0]` with `knight_captain` and no tower. Town Center full HP is 5000 (`tc 5000`).

## Simulated criteria

Source: Task 15 brief, Step 2.

1. An undefended town loses in the first three waves: PASS. `cap 0` loses in wave 1 (36 s).
2. The default 600 troops, no towers, default formation lose or barely win: PASS. They lose at wave 20 (Town Center 0, 389 s).
3. 1000 troops win with the Town Center hurt: PASS. Win, Town Center 2975 of 5000.
4. 2500 troops win without trouble: PASS. Win, Town Center 5000 of 5000, 999 to 2500 troops intact. (1500 troops also win at full Town Center HP.)
5. Towers matter, at least one tower type turns the 600-troop loss into a win: PASS. `crossbow_tower` wins (Town Center 1350) and `cannon_tower` wins (Town Center 900), against a loss with no tower. `arrow_tower` alone does not (loss, 390 s).
6. Formation matters, an army with no cavalry and no hero cannot get past wave 15: PASS, with a caveat on the probe. The all-infantry army (no cavalry) loses at wave 15. The probe keeps the `knight_captain` hero (a stronger setup than the criterion describes) and it still dies at the siege. A strictly hero-less run is not in the probe table.
7. A battle takes 4 to 6 minutes of simulated time (applies to winning runs; losing runs are informational): FAIL, marginal against the plan's 4 to 6 minutes.
   - The binding target is the spec's: 4 to 5 minutes including regroups. The plan's 4 to 6 minute criterion is the looser one. Against 4 to 5 minutes no simulated run passes: the fastest win is 317 s (2500 troops), already over 300 s, before up to about 60 s of skipped regroup countdowns (four regroups of up to 15 s) are added back.
   - Against the plan's 6 minutes: winning runs at or under 360 s are 1000 troops 351 s, 1500 troops 334 s, 2500 troops 317 s. Winning runs over 360 s are 600 + crossbow 370 s (6:10) and 600 + cannon 380 s (6:20), both over the ceiling by 10 to 20 s.
   - Informational, losing runs: 389 s (600, no towers), 390 s (arrow tower), 367 s (archer-heavy), 375 s (recommended, game start). These are long because of the boss, not a collapsing defence: in every 600-troop loss kills are 4228 of 4229, so everything dies except one enemy (almost certainly the boss). The boss alone wears down the wall and the Town Center. Waves 1 to 19 never threaten a 600-troop army.
   - So "the default 600 loses" and "towers matter" both come down to the boss's HP and damage: whether the army (and a tower) can burn the boss down before it wears the wall and Town Center away decides the battle.
   - The simulation skips regroup countdowns, so real play time will be longer still than these numbers.
   - Levers if the length has to come down (none applied): `spawn_window` (how long a wave takes to arrive), enemy speed, and `breather_seconds`.
   - Overall criteria verdict stays FAIL. The controller ruled to leave the FAIL as is; resource files are untouched.

Overall simulated criteria: FAIL (6 of 7 PASS; the time criterion misses by 10 to 20 s on 2 of 5 winning runs).

## Known tuning note (from the brief)

With the starting numbers troops rarely die (they heal 60% of losses and most enemies die before reaching the wall), so the troop-loss tension the spec wants in phase 4 is weak. Raising Rider and Bowman damage against troops, or lowering troop HP, is the first lever to try. Do not change the milestone structure.

The probe agrees: with `cap 600`, no towers, 498 of 600 troops are still alive at the loss, and every winning run ends with 99% to 100% of the army alive (troops 596 to 2500). Troop-loss pressure is weak.

Two tuning facts for whoever picks this up. `resources/tuning/default.tres` stores no explicit values: every number is a script default in `scripts/tuning_data.gd`, so edit them in the Inspector (which then writes them into the `.tres`). And the Mage hero's `skill_reach` of 10 cannot reach an 18 m siege unit; this is latent, because the battle scene always uses `knight_captain`.

## Hand playtest

PENDING (needs a human). The Fun Gate decision (PASS or FAIL, per brief Step 4) is not made here and stays blank until a person has played.

Play at least five battles in the editor (F5), at 1x speed, varying the formation and towers. After each, write one line: what you chose, how it went, what felt dull or unfair.

| # | Formation and towers chosen | How it went | Dull or unfair |
|---|---|---|---|
| 1 | PENDING | PENDING | PENDING |
| 2 | PENDING | PENDING | PENDING |
| 3 | PENDING | PENDING | PENDING |
| 4 | PENDING | PENDING | PENDING |
| 5 | PENDING | PENDING | PENDING |

Observations to confirm, answer yes or no:

- [ ] PENDING (needs a human): Wave 5 is visibly different (enemies come in from the left side).
- [ ] PENDING (needs a human): Wave 10 rams walk straight past the wall and threaten the Town Center.
- [ ] PENDING (needs a human): Wave 15 siege units sit far back and cannot be hurt without a sortie or the hero skill.
- [ ] PENDING (needs a human): Wave 20 has one big boss with escorts.
- [ ] PENDING (needs a human): Changing the formation at a regroup changed how the next phase went.
- [ ] PENDING (needs a human): You wanted to play again after losing.

## Decision

PENDING (needs a human). Write one of these here after the playtest:

- PASS: the battle is fun to replay. List what to carry into M4/M5 and any tuning deferred.
- FAIL: list the specific problems and which spec section each points at. Do not start M4. Bring the list back for a spec revision.
