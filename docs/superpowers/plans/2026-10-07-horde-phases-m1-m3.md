# Horde Phases (Kingshot refactor, M1-M3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the gate-run prototype with the 20-wave, four-phase horde defense from the spec, playable with grey boxes through the Fun Gate.

**Architecture:** All battle rules live in node-free classes (`Battle`, `PhaseMachine`, `Horde`, `CombatResolver`, `BattleState`, `WaveSpawner` and small pure helpers) that the headless test runner exercises directly, including full simulated 20-wave battles. A thin view layer (`BattleView`, `BattleHud`, `RegroupScreen`, `battle_scene.gd`) reads that state and forwards its signals to `EventBus`. Every balance number is a `Resource`.

**Tech Stack:** Godot 4.7.2 (Mobile renderer), GDScript, the repo's headless test runner (`tests/run_tests.gd`).

**Spec:** `docs/superpowers/specs/2026-10-07-kingshot-horde-phases-design.md`

**Scope:** This plan covers the repository cleanup plus spec milestones M1 (battle core), M2 (troops and regroup) and M3 (phases, milestones, towers, hero, sortie) and ends at the **Fun Gate**. M4 (horde performance), M5 (vertical slice) and later get their own plans after the Fun Gate passes. M0 is already done.

| Spec milestone | Tasks |
| --- | --- |
| Cleanup | 1, 2 |
| M1 Battle core | 3, 5, 6, 7, 8, 9, 10, 11 (budget, spawner, walls, horde, wave counter, battle loop, 3D view) |
| M2 Troops and regroup | 4, 12, 13 (troop pool, formation, HUD, regroup screen) |
| M3 Phases and milestones | 5, 9, 10, 14, 15 (milestone waves, towers, hero skill, sortie, scene wiring, Fun Gate) |

Milestone logic is built early (Task 5) because the tests for every later task use the full wave list; the player-facing pieces land in the order above.

## Global Constraints

- Godot 4 with GDScript, Mobile renderer, portrait 1080x1920 (the existing project settings). Indent with tabs and match the surrounding style (typed GDScript, `##` doc comments).
- A battle is **20 waves in 4 phases of 5**. Milestone waves are **5 (Flank), 10 (Keep strike), 15 (Siege), 20 (Boss)**.
- Troop kinds are **Infantry, Cavalry, Archers** with the triangle **Infantry > Cavalry > Archers > Infantry**. A winning matchup multiplies damage by **1.5**, a losing one by **0.75**. Rams, Siege and the Boss are outside the triangle.
- **3 wall sections** (left, center, right) and **6 tower slots** (two per section). Towers and formation change only at a regroup.
- Regroup: about **15 s** countdown with a Ready button, before wave 1 and after waves 5, 10 and 15. At each regroup **60%** of the phase's troop losses return, walls repair by **30%** of max HP and skill cooldowns reset. All troops return after the battle (nothing is permanent).
- The only live inputs during a wave are the **hero skill** and the **cavalry sortie**.
- Wave budget: `budget(L, w) = B0 * g_L^L * g_w^w * m(w)` with **B0 = 100, g_L = 1.12, g_w = 1.10, m = 1.5** on milestone waves. Enemy HP and damage scale `1.06^L`.
- **Every number lives in a Resource** (`resources/tuning/default.tres` and the enemy, troop, tower, hero `.tres` files). No balance numbers in logic code.
- Enemies are **plain data arrays**, never nodes or physics bodies.
- **Class scripts (anything with `class_name`) must not name autoloads** (`EventBus`, `GameState`, ...): the headless runner compiles them before the autoloads exist. Only autoload scripts and scene scripts (`battle_scene.gd`, `main.gd`) may.
- A battle takes **4-5 minutes** at 1x speed.
- After adding a new `class_name` script run `godot --headless --path . --import` once (the test commands below include it).
- Test command used throughout (Git Bash on this machine: replace `godot` with `/c/Jogos/Godot_v4.7.2/Godot_v4.7.2-stable_win64_console.exe`; PowerShell and cmd find `godot` via `C:\Users\jfeli\.local\bin\godot.cmd`):

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- <suite name, e.g. test_formation>
```

  Omit `-- <suite>` to run everything. The runner prints `RESULT: N passed, M failed` and exits non-zero on any failure or on a suite that does not load.
- Commit messages end with the trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

## Review Focus

Failure modes the spec implies but a happy-path build would miss, most likely first. Each has a test in the task named.

1. **A formation that deals nobody.** All-zero or negative slider weights must still assign every troop (no troops vanish into a rounding gap). Tests: Task 4 `test_apportion_treats_bad_weights_safely`, `test_counts_conserve_troops_for_any_capacity`; Task 13 `test_zero_sliders_everywhere_still_deal_every_troop`.
2. **A stage missing enemy types.** No ordinary enemy for a wave, or a boss with no escorts, must give a short or empty wave, not a crash or an endless loop. Test: Task 5 `test_stage_without_a_matching_enemy_builds_an_empty_wave_instead_of_crashing`.
3. **Defenders that cannot reach attackers.** Siege units stop at 18 m, beyond archers (12 m), towers (10-14 m) and melee. An army with no cavalry sortie or hero skill must be beaten in finite time, not stall the battle. Test: Task 10 `test_an_army_that_cannot_reach_the_siege_is_beaten_in_finite_time`.
4. **More than 500 live enemies.** Late waves exceed the 500 drawn instances: the view must cap what it draws while the simulation keeps every enemy. Test: Task 11 `test_enemy_instances_are_capped`.
5. **Player actions at the wrong time or with bad arguments.** A formation or tower change during an assault, a skill on section 7, a sortie with no cavalry, input after the battle ended: all refused with no side effects. Tests: Task 10 `test_apply_formation_is_refused_during_an_assault`, `test_set_tower_validates_phase_section_and_slot`, `test_hero_skill_only_works_in_an_assault_and_respects_its_cooldown`, `test_a_finished_battle_ignores_further_ticks`; Task 13 `test_ready_outside_a_regroup_changes_nothing`.

---

### Task 1: Clear the gate-run prototype and reshape the foundation

Removes the Last War gate run, the old design and plan docs, and the gate signals and fields. Keeps the M0 foundation (autoloads, scene swapper, debug panel, asset pipeline, test runner) and edits it to match the new design.

**Files:**
- Delete: `scripts/{gate_run,squad,squad_state,formation,gate_data,gate_pair_data,gate_view,blocker_data,wall_placeholder}.gd` and their `.uid` files
- Delete: `scenes/Gate.tscn`, `scenes/WallPlaceholder.tscn`
- Delete: `resources/gates/`, `resources/sections/`
- Delete: `tests/{test_gate_math,test_formation,test_squad,test_gate_run,test_handoff,test_resources}.gd` and their `.uid` files
- Delete: `docs/Horde Defense Village Game – Design Document.md`, `docs/Hold the Hearth – Implementation Plan.md`
- Modify: `autoload/event_bus.gd`, `autoload/game_state.gd`, `autoload/debug_panel.gd`, `scripts/section_data.gd`, `scripts/main.gd`
- Modify: `tests/run_tests.gd`, `tests/test_autoloads.gd`, `tests/test_debug_panel.gd`

**Interfaces:**
- Produces:
  - `EventBus` signals: `enemy_killed`, `wall_damaged(section: int, amount: float)`, `wave_started(wave: int)`, `wave_cleared(wave: int)`, `phase_cleared(phase: int)`, `regroup_started(phase: int)`, `battle_ended(victory: bool)`, `debug_spawn_wave(wave: int)`, `debug_skip_phase`
  - `GameState`: `gold`, `shards`, `current_stage` (1-based), `march_capacity` (default 600), `add_gold(amount)`, `record_battle(victory: bool, highest_wave: int)` (pays `highest_wave * 10`, plus 100 on victory), `reset()`
  - `DebugPanel`: `spawn_wave(wave)`, `set_stage(stage)`, `skip_phase()`, `add_gold(amount)`, `toggle_speed()`, `toggle()`, `is_open()`, `track_touch(index, pressed)`
  - Test runner: runs every `tests/test_*.gd`; `-- <suite name>` after the command runs one; a suite that fails to load counts as a failure.

- [ ] **Step 1: Delete the gate-run code, old tests and old docs**

```bash
git rm scripts/gate_run.gd scripts/gate_run.gd.uid scripts/squad.gd scripts/squad.gd.uid \
  scripts/squad_state.gd scripts/squad_state.gd.uid scripts/formation.gd scripts/formation.gd.uid \
  scripts/gate_data.gd scripts/gate_data.gd.uid scripts/gate_pair_data.gd scripts/gate_pair_data.gd.uid \
  scripts/gate_view.gd scripts/gate_view.gd.uid scripts/blocker_data.gd scripts/blocker_data.gd.uid \
  scripts/wall_placeholder.gd scripts/wall_placeholder.gd.uid
git rm scenes/Gate.tscn scenes/WallPlaceholder.tscn
git rm -r resources/gates resources/sections
git rm tests/test_gate_math.gd tests/test_gate_math.gd.uid tests/test_formation.gd tests/test_formation.gd.uid \
  tests/test_squad.gd tests/test_squad.gd.uid tests/test_gate_run.gd tests/test_gate_run.gd.uid \
  tests/test_handoff.gd tests/test_handoff.gd.uid tests/test_resources.gd tests/test_resources.gd.uid
git rm docs/*Design\ Document.md docs/*Implementation\ Plan.md
```

If a `.uid` file is missing for one of the scripts, drop it from the command; `git rm` aborts on a pathspec that matches nothing.

- [ ] **Step 2: Update the tests first**

Replace `tests/test_autoloads.gd` with:

```gdscript
extends RefCounted

var t
var _hits: Array = []

func test_all_autoloads_present() -> void:
	for n in ["EventBus", "GameState", "SaveManager", "SceneSwapper", "DebugPanel"]:
		t.check(t.root.has_node(n), "autoload %s" % n)

func test_event_bus_signals_emit() -> void:
	var bus = t.root.get_node("EventBus")
	for sig in ["enemy_killed", "wall_damaged", "wave_started", "wave_cleared", "phase_cleared", "regroup_started", "battle_ended"]:
		t.check(bus.has_signal(sig), "signal " + sig)
	_hits.clear()
	var cb := func(v): _hits.append(v)
	bus.battle_ended.connect(cb)
	bus.battle_ended.emit(false)
	bus.battle_ended.disconnect(cb)
	t.eq(_hits, [false], "battle_ended emitted with payload")

func test_game_state_holds_currencies_and_resets() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	t.eq(gs.gold, 0, "gold reset")
	t.eq(gs.shards, 0, "shards reset")
	t.eq(gs.current_stage, 1, "stage is 1-based")
	t.eq(gs.march_capacity, 600, "default march capacity")
	gs.add_gold(25)
	t.eq(gs.gold, 25, "add_gold")
	gs.reset()

func test_save_manager_stub_is_callable() -> void:
	var sm = t.root.get_node("SaveManager")
	t.eq(sm.save_game(), true, "save stub")
	t.eq(sm.load_game(), true, "load stub")

func test_record_battle_pays_more_for_higher_waves_and_victory() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	gs.record_battle(false, 7)
	t.eq(gs.gold, 70, "loss pays 10 gold per wave reached")
	gs.reset()
	gs.record_battle(true, 20)
	t.eq(gs.gold, 300, "win pays wave gold plus 100")
	gs.reset()
```

Replace `tests/test_debug_panel.gd` with:

```gdscript
extends RefCounted

var t
var _waves: Array = []

func _panel():
	return t.root.get_node("DebugPanel")

func test_spawn_wave_emits_on_event_bus() -> void:
	_waves.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(w): _waves.append(w)
	bus.debug_spawn_wave.connect(cb)
	_panel().spawn_wave(3)
	bus.debug_spawn_wave.disconnect(cb)
	t.eq(_waves, [3], "wave 3 requested")

func test_set_stage_updates_game_state() -> void:
	var gs = t.root.get_node("GameState")
	_panel().set_stage(7)
	t.eq(gs.current_stage, 7, "stage set")
	gs.reset()

func test_skip_phase_emits_on_event_bus() -> void:
	_waves.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(): _waves.append(true)
	bus.debug_skip_phase.connect(cb)
	_panel().skip_phase()
	bus.debug_skip_phase.disconnect(cb)
	t.eq(_waves, [true], "skip phase requested")

func test_add_gold_updates_game_state() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	_panel().add_gold(500)
	t.eq(gs.gold, 500, "gold added")
	gs.reset()

func test_speed_toggle_switches_time_scale_4x() -> void:
	var p = _panel()
	p.toggle_speed()
	t.eq(Engine.time_scale, 4.0, "4x on")
	p.toggle_speed()
	t.eq(Engine.time_scale, 1.0, "back to 1x")

func test_panel_toggles_visibility() -> void:
	var p = _panel()
	t.eq(p.is_open(), false, "starts closed")
	p.toggle()
	t.eq(p.is_open(), true, "opens")
	p.toggle()
	t.eq(p.is_open(), false, "closes")

func test_three_finger_tap_toggles_panel() -> void:
	var p = _panel()
	p.track_touch(0, true)
	p.track_touch(1, true)
	t.eq(p.is_open(), false, "two fingers do nothing")
	p.track_touch(2, true)
	t.eq(p.is_open(), true, "third finger opens")
	p.track_touch(0, false)
	p.track_touch(1, false)
	p.track_touch(2, false)
	p.toggle()
```

Replace `tests/run_tests.gd` with (it now discovers suites itself, takes an optional suite name, and fails loudly on a suite that does not load):

```gdscript
extends SceneTree
## Headless test runner: godot --headless --path . -s res://tests/run_tests.gd
## Runs every tests/test_*.gd. Pass a name after `--` to run one suite, e.g. `-- test_formation`.

var _failures: int = 0
var _passed: int = 0

func _initialize() -> void:
	await process_frame  # let the tree finish starting so _ready runs on added nodes
	var only := OS.get_cmdline_user_args()
	var paths: Array = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and (only.is_empty() or f.get_basename() in only):
			paths.append("res://tests/" + f)
	paths.sort()
	for path in paths:
		var script = load(path)
		if script == null or not script.can_instantiate():
			_failures += 1
			printerr("FAIL: could not load " + path)
			continue
		var suite = script.new()
		suite.t = self
		for m in suite.get_method_list():
			if String(m.name).begins_with("test_"):
				await suite.call(m.name)
	print("RESULT: %d passed, %d failed" % [_passed, _failures])
	quit(1 if _failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failures += 1
		printerr("FAIL: " + msg)

func eq(actual, expected, msg: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])
```

- [ ] **Step 3: Run the tests to verify they fail**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_autoloads
```

Expected: failures (`signal wave_started` missing, `GameState.current_stage` not found) and parse errors from the scripts that still reference the deleted gate classes. The exit code is non-zero.

- [ ] **Step 4: Reshape the autoloads, `SectionData` and `main.gd`**

Replace `autoload/event_bus.gd` with:

```gdscript
extends Node

signal enemy_killed
signal wall_damaged(section: int, amount: float)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal phase_cleared(phase: int)
signal regroup_started(phase: int)
signal battle_ended(victory: bool)
## Debug panel requests, handled by the active Battle.
signal debug_spawn_wave(wave: int)
signal debug_skip_phase
```

Replace `autoload/game_state.gd` with:

```gdscript
extends Node

var gold: int = 0
var shards: int = 0
## 1-based, as on the stage list.
var current_stage: int = 1
## Total troops fielded; the Town Center level sets this once the village exists (M6).
var march_capacity: int = 600

func add_gold(amount: int) -> void:
	gold += amount

## Rewards scale with the highest wave reached, so a loss still pays something.
func record_battle(victory: bool, highest_wave: int) -> void:
	add_gold(highest_wave * 10 + (100 if victory else 0))

func reset() -> void:
	gold = 0
	shards = 0
	current_stage = 1
	march_capacity = 600
```

Replace `autoload/debug_panel.gd` with (jump to wave N, skip phase and set stage replace the gate-era stubs):

```gdscript
extends CanvasLayer
## Debug panel: F1 or a 3-finger tap toggles it. Actions publish on EventBus /
## GameState; the active Battle reacts to the requests.

var _panel: PanelContainer
var _wave_box: SpinBox
var _stage_box: SpinBox
var _fast: bool = false
var _touches := {}

func _ready() -> void:
	layer = 99
	_build_ui()
	_panel.visible = false

func is_open() -> bool:
	return _panel.visible

func toggle() -> void:
	_panel.visible = not _panel.visible

func spawn_wave(wave: int) -> void:
	EventBus.debug_spawn_wave.emit(wave)

func set_stage(stage: int) -> void:
	GameState.current_stage = stage

func skip_phase() -> void:
	EventBus.debug_skip_phase.emit()

func add_gold(amount: int) -> void:
	GameState.add_gold(amount)

func toggle_speed() -> void:
	_fast = not _fast
	Engine.time_scale = 4.0 if _fast else 1.0

## Called for every touch press/release; opens the panel when a third finger lands.
func track_touch(index: int, pressed: bool) -> void:
	if pressed:
		_touches[index] = true
		if _touches.size() == 3:
			toggle()
	else:
		_touches.erase(index)

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventScreenTouch:
		track_touch(event.index, event.pressed)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(20, 20)
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	box.add_child(_label("DEBUG"))
	_wave_box = _spin(1, 20, 1)
	box.add_child(_row("Wave", _wave_box, "Spawn", func(): spawn_wave(int(_wave_box.value))))
	_stage_box = _spin(1, 30, 1)
	box.add_child(_row("Stage", _stage_box, "Set", func(): set_stage(int(_stage_box.value))))
	box.add_child(_button("Skip phase", skip_phase))
	box.add_child(_button("+1000 gold", func(): add_gold(1000)))
	box.add_child(_button("Toggle 4x speed", toggle_speed))

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 36)
	return l

func _spin(lo: int, hi: int, v: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = v
	s.custom_minimum_size = Vector2(200, 80)
	return s

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 36)
	b.custom_minimum_size = Vector2(0, 90)
	b.pressed.connect(cb)
	return b

func _row(label: String, spin: SpinBox, action: String, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(_label(label))
	h.add_child(spin)
	h.add_child(_button(action, cb))
	return h
```

`SectionData` keeps compiling until Task 2 removes it; strip its gate fields. Replace `scripts/section_data.gd` with:

```gdscript
class_name SectionData
extends Resource
## Replaced by StageData in Task 2. The gate-run fields are gone.

@export var section_name: String = ""
@export var region: StringName = &"greenfields"
## 0-based index used by the wave budget formula (the plan numbers sections from 1).
@export var section_index: int = 0
@export var allowed_enemies: Array[EnemyData] = []
```

Replace `scripts/main.gd` with:

```gdscript
extends Node
## Entry scene. Starts the battle once the Battle scene exists (Task 14).
```

- [ ] **Step 5: Run the whole suite**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd
```

Expected: `RESULT: 88 passed, 0 failed`. The five remaining suites are `test_data_classes` (old, still valid until Task 2), `test_autoloads`, `test_scene_swapper`, `test_debug_panel` and `test_assets`.

- [ ] **Step 6: Commit**

```bash
git add -A autoload scripts scenes resources tests docs
git commit -m "Remove the gate-run prototype and old docs, reshape autoloads" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Data classes and authored resources

Replaces the gate-era data classes with the spec's Resource classes and the stock `.tres` files the battle uses. The enemy numbers below are the calibrated starting balance: with them an undefended town falls at wave 1, 600 troops lose to the boss, and 1000 troops win.

**Files:**
- Create: `scripts/{unit_role,tuning_data,wave_data,stage_data,troop_data,tower_data}.gd`
- Modify: `scripts/enemy_data.gd`, `scripts/hero_data.gd`
- Delete: `scripts/{card_data,unit_data,section_data}.gd` (+ `.uid`), `resources/cards/`, `resources/units/`, `resources/enemies/grunt.tres`
- Create: `resources/tuning/default.tres`, `resources/enemies/{raider,rider,bowman,ram,siege,boss}.tres`, `resources/troops/{infantry_t1,cavalry_t1,archers_t1}.tres`, `resources/towers/{arrow_tower,crossbow_tower,cannon_tower}.tres`, `resources/stages/stage_01.tres`
- Replace: `resources/heroes/knight_captain.tres`; Create: `resources/heroes/{ranger,mage}.tres`
- Test: `tests/test_data_classes.gd` (replace)

**Interfaces:**
- Produces:
  - `UnitRole.Kind { INFANTRY, CAVALRY, ARCHERS, NONE }`, `UnitRole.TROOP_KINDS`
  - `TuningData` (every field and default shown below)
  - `WaveData` (`RefCounted`): `enum Milestone { NONE, FLANK, KEEP_STRIKE, SIEGE, BOSS }`, `LANE_AUTO = -1`, `wave`, `phase`, `milestone`, `budget`, `spawns: Array` of `{enemy, lane, delay, side}`, `count_of(id) -> int`, `spent() -> int`
  - `EnemyData`: `enum Target { WALL, ARCHERS, TOWN_CENTER }`; `id, display_name, role: UnitRole.Kind, target, speed, hp, dps, attack_range, troop_share, cost, model_scale, first_wave, spawn_weight, milestone: WaveData.Milestone`
  - `StageData`: `stage_name, region, stage_index (0-based), allowed_enemies: Array[EnemyData], flank_lane`
  - `TroopData`: `id, display_name, kind, tier, hp, dps, attack_range, color`
  - `TowerData`: `id, display_name, dps, attack_range, max_targets, strong_vs: PackedInt32Array, strong_mult`
  - `HeroData`: `enum BuffStat { HP, DAMAGE }`; `id, display_name, skill_name, skill_cooldown, skill_damage, skill_reach, skill_knockback, passive_text, buff_kind, buff_stat, buff_towers, buff_mult`
  - Resource files at the paths above

- [ ] **Step 1: Write the failing test**

Replace `tests/test_data_classes.gd` with:

```gdscript
extends RefCounted

var t

func _tuning() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

func test_tuning_defaults_match_the_spec() -> void:
	var tu := _tuning()
	t.check(tu != null, "default tuning loads")
	t.eq(tu.waves_per_battle, 20, "20 waves")
	t.eq(tu.phase_length, 5, "4 phases of 5")
	t.eq(tu.heal_share, 0.6, "60% healing")
	t.eq(tu.milestone_mult, 1.5, "milestone multiplier")

func test_every_enemy_loads_with_core_fields() -> void:
	var expected := {
		&"raider": [UnitRole.Kind.INFANTRY, EnemyData.Target.WALL, WaveData.Milestone.NONE],
		&"rider": [UnitRole.Kind.CAVALRY, EnemyData.Target.ARCHERS, WaveData.Milestone.NONE],
		&"bowman": [UnitRole.Kind.ARCHERS, EnemyData.Target.WALL, WaveData.Milestone.NONE],
		&"ram": [UnitRole.Kind.NONE, EnemyData.Target.TOWN_CENTER, WaveData.Milestone.KEEP_STRIKE],
		&"siege": [UnitRole.Kind.NONE, EnemyData.Target.WALL, WaveData.Milestone.SIEGE],
		&"boss": [UnitRole.Kind.NONE, EnemyData.Target.WALL, WaveData.Milestone.BOSS],
	}
	for id in expected:
		var e := load("res://resources/enemies/%s.tres" % id) as EnemyData
		t.check(e != null, "%s loads as EnemyData" % id)
		if e == null:
			continue
		t.eq(e.id, id, "%s id" % id)
		t.check(e.hp > 0.0 and e.speed > 0.0 and e.dps > 0.0, "%s has hp, speed, dps" % id)
		t.eq(e.role, expected[id][0], "%s triangle role" % id)
		t.eq(e.target, expected[id][1], "%s target" % id)
		t.eq(e.milestone, expected[id][2], "%s milestone" % id)
		if e.milestone == WaveData.Milestone.NONE:
			t.check(e.cost > 0, "%s ordinary enemies cost points" % id)

func test_troops_cover_the_three_kinds() -> void:
	var seen := {}
	for id in ["infantry_t1", "cavalry_t1", "archers_t1"]:
		var tr := load("res://resources/troops/%s.tres" % id) as TroopData
		t.check(tr != null and tr.hp > 0.0 and tr.dps > 0.0, id + " loads with hp and dps")
		if tr:
			seen[tr.kind] = true
	for k in UnitRole.TROOP_KINDS:
		t.check(seen.has(k), "a troop exists for kind %d" % k)

func test_towers_load_and_name_what_they_are_strong_against() -> void:
	for id in ["arrow_tower", "crossbow_tower", "cannon_tower"]:
		var tw := load("res://resources/towers/%s.tres" % id) as TowerData
		t.check(tw != null and tw.dps > 0.0 and tw.attack_range > 0.0, id + " loads")
		if tw:
			t.check(tw.strong_vs.size() > 0, id + " is strong against something")
			t.check(tw.max_targets >= 1, id + " hits at least one target")

func test_heroes_load_with_cooldown_in_design_range() -> void:
	for id in ["knight_captain", "ranger", "mage"]:
		var h := load("res://resources/heroes/%s.tres" % id) as HeroData
		t.check(h != null, id + " loads as HeroData")
		if h:
			t.check(h.skill_cooldown >= 8.0 and h.skill_cooldown <= 20.0, id + " cooldown within 8-20 s")
			t.check(h.buff_kind != UnitRole.Kind.NONE or h.buff_towers, id + " buffs something")

func test_stage_one_lists_all_six_enemies() -> void:
	var st := load("res://resources/stages/stage_01.tres") as StageData
	t.check(st != null, "stage_01 loads")
	if st:
		t.eq(st.stage_index, 0, "first stage index is 0")
		t.eq(st.allowed_enemies.size(), 6, "six enemy types")
		t.check(st.flank_lane >= 0 and st.flank_lane <= 2, "flank lane is a real lane")
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_data_classes
```

Expected: `FAIL: could not load res://tests/test_data_classes.gd` (identifier `UnitRole` / `TuningData` not found).

- [ ] **Step 3: Delete the old data classes**

```bash
git rm scripts/card_data.gd scripts/card_data.gd.uid scripts/unit_data.gd scripts/unit_data.gd.uid \
  scripts/section_data.gd scripts/section_data.gd.uid
git rm -r resources/cards resources/units
git rm resources/enemies/grunt.tres
```

- [ ] **Step 4: Create the classes**

`scripts/unit_role.gd`:

```gdscript
class_name UnitRole
extends RefCounted
## The three corners of the counter triangle, plus NONE for units outside it.

enum Kind { INFANTRY, CAVALRY, ARCHERS, NONE }

const TROOP_KINDS := [Kind.INFANTRY, Kind.CAVALRY, Kind.ARCHERS]
```

`scripts/tuning_data.gd`:

```gdscript
class_name TuningData
extends Resource
## Every balance number in one file (design spec section 8). Provisional until the Fun Gate.

@export_group("Waves")
@export var waves_per_battle: int = 20
@export var phase_length: int = 5
@export var b0: float = 100.0
@export var growth_stage: float = 1.12
@export var growth_wave: float = 1.10
@export var milestone_mult: float = 1.5
## Share of the wave 5 budget spent on the flanking group.
@export var flank_share: float = 0.4
## Share of the wave 10 / wave 15 budget spent on rams / siege units.
@export var special_share: float = 0.1
## Share of the wave 20 budget spent on the boss's escorts (the boss itself is free).
@export var escort_share: float = 0.5
## Enemy HP and damage grow by this factor per stage.
@export var stat_growth: float = 1.06
## Seconds over which a wave's enemies trickle in.
@export var spawn_window: float = 6.0
@export_group("Triangle")
@export var triangle_win: float = 1.5
@export var triangle_lose: float = 0.75
@export_group("Regroup")
@export var heal_share: float = 0.6
@export var wall_repair_share: float = 0.3
@export var breather_seconds: float = 4.0
@export var regroup_seconds: float = 15.0
@export_group("Battlefield")
@export var lane_length: float = 24.0
@export var wall_hp: float = 3000.0
@export var town_center_hp: float = 5000.0
## Extra wall HP per infantry troop assigned to a section (0.0005 x 200 troops = +10%).
@export var infantry_wall_bonus: float = 0.0005
@export var melee_reach: float = 1.0
@export_group("Cavalry sortie")
@export var cavalry_reserve_mult: float = 0.5
@export var sortie_mult: float = 3.0
@export var sortie_reach: float = 22.0
@export var sortie_duration: float = 4.0
@export var sortie_cooldown: float = 10.0
```

`scripts/wave_data.gd`:

```gdscript
class_name WaveData
extends RefCounted
## One wave as built by WaveSpawner. A runtime object, not an authored .tres.

enum Milestone { NONE, FLANK, KEEP_STRIKE, SIEGE, BOSS }

## Lane value meaning "the section with the fewest troops when the enemy spawns".
const LANE_AUTO := -1

var wave: int = 0
var phase: int = 1
var milestone: Milestone = Milestone.NONE
var budget: float = 0.0
## Each entry: { "enemy": EnemyData, "lane": int (0-2 or LANE_AUTO), "delay": float, "side": bool }
var spawns: Array = []

func count_of(id: StringName) -> int:
	var n := 0
	for s in spawns:
		if s.enemy.id == id:
			n += 1
	return n

## Total budget points actually spent (boss counts as its listed cost, which is 0).
func spent() -> int:
	var total := 0
	for s in spawns:
		total += s.enemy.cost
	return total
```

Replace `scripts/enemy_data.gd`:

```gdscript
class_name EnemyData
extends Resource
## One horde enemy type. Stats only; behavior lives in Horde.

enum Target { WALL, ARCHERS, TOWN_CENTER }

@export var id: StringName = &""
@export var display_name: String = ""
## Corner of the counter triangle; NONE for rams, siege and bosses.
@export var role: UnitRole.Kind = UnitRole.Kind.INFANTRY
@export var target: Target = Target.WALL
## Metres per second along the lane.
@export var speed: float = 1.0
@export var hp: float = 10.0
## Damage per second to whatever it attacks.
@export var dps: float = 1.0
## Metres from the wall at which it stops and attacks. 0 = melee.
@export var attack_range: float = 0.0
## Share of dps spent on the troops behind the wall (the rest hits the wall).
@export var troop_share: float = 0.0
## Wave-budget points this enemy costs. Reserved milestone enemies may be 0 (fixed count).
@export var cost: int = 1
@export var model_scale: float = 1.0
## Ordinary enemies (NONE) join the mix from this wave on.
@export var first_wave: int = 1
## Relative share of the mix among ordinary enemies.
@export var spawn_weight: float = 1.0
## Which milestone wave this enemy is reserved for; NONE = ordinary.
@export var milestone: WaveData.Milestone = WaveData.Milestone.NONE
```

`scripts/stage_data.gd`:

```gdscript
class_name StageData
extends Resource
## One 20-wave horde event. Authored as .tres.

@export var stage_name: String = ""
@export var region: StringName = &"greenfields"
## 0-based index used by the wave budget formula.
@export var stage_index: int = 0
@export var allowed_enemies: Array[EnemyData] = []
## Lane (0 left, 1 center, 2 right) hit by the wave 5 flank.
@export var flank_lane: int = 0
```

`scripts/troop_data.gd`:

```gdscript
class_name TroopData
extends Resource
## One troop type at one tier. All values are per troop; the pool holds counts.

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: UnitRole.Kind = UnitRole.Kind.INFANTRY
@export var tier: int = 1
@export var hp: float = 40.0
@export var dps: float = 3.0
## Metres from the wall the troop can hit. 0 = melee.
@export var attack_range: float = 0.0
@export var color: Color = Color.WHITE
```

`scripts/tower_data.gd`:

```gdscript
class_name TowerData
extends Resource
## A wall tower. Placed at a regroup, fixed during a phase.

@export var id: StringName = &""
@export var display_name: String = ""
@export var dps: float = 20.0
@export var attack_range: float = 12.0
## Enemies hit at once (splash or pierce); each takes the full dps.
@export var max_targets: int = 1
## UnitRole.Kind values this tower is strong against.
@export var strong_vs: PackedInt32Array = PackedInt32Array()
@export var strong_mult: float = 1.5
```

Replace `scripts/hero_data.gd`:

```gdscript
class_name HeroData
extends Resource
## A hero: one tap skill with a cooldown and one passive that buffs a troop type or the towers.

enum BuffStat { HP, DAMAGE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var skill_name: String = ""
## Design range is 8-20 s.
@export var skill_cooldown: float = 12.0
## Damage to every enemy within skill_reach of the wall in the chosen section's lane.
@export var skill_damage: float = 200.0
@export var skill_reach: float = 22.0
## Metres the survivors are pushed back.
@export var skill_knockback: float = 3.0
@export var passive_text: String = ""
## Troop kind the passive buffs, or NONE.
@export var buff_kind: UnitRole.Kind = UnitRole.Kind.NONE
@export var buff_stat: BuffStat = BuffStat.HP
@export var buff_towers: bool = false
@export var buff_mult: float = 1.1
```

- [ ] **Step 5: Create the resources**

`resources/tuning/default.tres` (all defaults; edit this file to tune):

```ini
[gd_resource type="Resource" script_class="TuningData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/tuning_data.gd" id="1"]

[resource]
script = ExtResource("1")
```

Enemies. Each file is one `.tres`; the enum values are `role` 0 Infantry / 1 Cavalry / 2 Archers / 3 None, `target` 0 Wall / 1 Archers / 2 Town Center, `milestone` 0 None / 1 Flank / 2 Keep strike / 3 Siege / 4 Boss.

`resources/enemies/raider.tres`:

```ini
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"raider"
display_name = "Raider"
role = 0
target = 0
speed = 3.0
hp = 80.0
dps = 8.0
attack_range = 0.0
troop_share = 0.0
cost = 1
model_scale = 1.0
first_wave = 1
spawn_weight = 6.0
milestone = 0
```

`resources/enemies/rider.tres`:

```ini
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"rider"
display_name = "Rider"
role = 1
target = 1
speed = 6.0
hp = 60.0
dps = 10.0
attack_range = 0.0
troop_share = 0.0
cost = 2
model_scale = 1.0
first_wave = 6
spawn_weight = 3.0
milestone = 0
```

`resources/enemies/bowman.tres`:

```ini
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"bowman"
display_name = "Bowman"
role = 2
target = 0
speed = 2.5
hp = 48.0
dps = 8.0
attack_range = 8.0
troop_share = 0.5
cost = 3
model_scale = 1.0
first_wave = 11
spawn_weight = 3.0
milestone = 0
```

`resources/enemies/ram.tres`:

```ini
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"ram"
display_name = "Ram"
role = 3
target = 2
speed = 1.5
hp = 1500.0
dps = 60.0
attack_range = 0.0
troop_share = 0.0
cost = 8
model_scale = 1.6
first_wave = 1
spawn_weight = 1.0
milestone = 2
```

`resources/enemies/siege.tres`:

```ini
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"siege"
display_name = "Siege"
role = 3
target = 0
speed = 1.2
hp = 900.0
dps = 50.0
attack_range = 18.0
troop_share = 0.0
cost = 10
model_scale = 1.4
first_wave = 1
spawn_weight = 1.0
milestone = 3
```

`resources/enemies/boss.tres`:

```ini
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"boss"
display_name = "Boss"
role = 3
target = 0
speed = 1.0
hp = 40000.0
dps = 250.0
attack_range = 0.0
troop_share = 0.0
cost = 0
model_scale = 2.5
first_wave = 1
spawn_weight = 1.0
milestone = 4
```

Troops:

`resources/troops/infantry_t1.tres`:

```ini
[gd_resource type="Resource" script_class="TroopData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/troop_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"infantry_t1"
display_name = "Infantry"
kind = 0
tier = 1
hp = 40.0
dps = 3.0
attack_range = 0.0
color = Color(0.25, 0.5, 0.95, 1)
```

`resources/troops/cavalry_t1.tres`:

```ini
[gd_resource type="Resource" script_class="TroopData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/troop_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cavalry_t1"
display_name = "Cavalry"
kind = 1
tier = 1
hp = 30.0
dps = 4.0
attack_range = 0.0
color = Color(0.95, 0.75, 0.2, 1)
```

`resources/troops/archers_t1.tres`:

```ini
[gd_resource type="Resource" script_class="TroopData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/troop_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"archers_t1"
display_name = "Archers"
kind = 2
tier = 1
hp = 20.0
dps = 5.0
attack_range = 12.0
color = Color(0.3, 0.85, 0.4, 1)
```

Towers (`strong_vs` holds `UnitRole.Kind` values: arrow vs cavalry and archers, crossbow vs infantry and none, cannon vs none):

`resources/towers/arrow_tower.tres`:

```ini
[gd_resource type="Resource" script_class="TowerData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/tower_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"arrow_tower"
display_name = "Arrow Tower"
dps = 25.0
attack_range = 12.0
max_targets = 1
strong_vs = PackedInt32Array(1, 2)
strong_mult = 1.5
```

`resources/towers/crossbow_tower.tres`:

```ini
[gd_resource type="Resource" script_class="TowerData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/tower_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"crossbow_tower"
display_name = "Crossbow Tower"
dps = 40.0
attack_range = 14.0
max_targets = 3
strong_vs = PackedInt32Array(0, 3)
strong_mult = 1.5
```

`resources/towers/cannon_tower.tres`:

```ini
[gd_resource type="Resource" script_class="TowerData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/tower_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cannon_tower"
display_name = "Cannon Tower"
dps = 30.0
attack_range = 10.0
max_targets = 6
strong_vs = PackedInt32Array(3)
strong_mult = 1.5
```

Heroes (replace `knight_captain.tres`, add the other two):

`resources/heroes/knight_captain.tres`:

```ini
[gd_resource type="Resource" script_class="HeroData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hero_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"knight_captain"
display_name = "Knight Captain"
skill_name = "Shield Bash"
skill_cooldown = 12.0
skill_damage = 150.0
skill_reach = 22.0
skill_knockback = 3.0
passive_text = "Infantry +15% HP"
buff_kind = 0
buff_stat = 0
buff_towers = false
buff_mult = 1.15
```

`resources/heroes/ranger.tres`:

```ini
[gd_resource type="Resource" script_class="HeroData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hero_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"ranger"
display_name = "Ranger"
skill_name = "Arrow Rain"
skill_cooldown = 12.0
skill_damage = 250.0
skill_reach = 22.0
skill_knockback = 0.0
passive_text = "Archers +10% damage"
buff_kind = 2
buff_stat = 1
buff_towers = false
buff_mult = 1.1
```

`resources/heroes/mage.tres`:

```ini
[gd_resource type="Resource" script_class="HeroData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hero_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"mage"
display_name = "Mage"
skill_name = "Fire Meteor"
skill_cooldown = 15.0
skill_damage = 400.0
skill_reach = 10.0
skill_knockback = 0.0
passive_text = "Tower damage +20%"
buff_kind = 3
buff_stat = 1
buff_towers = true
buff_mult = 1.2
```

Stage 1:

`resources/stages/stage_01.tres`:

```ini
[gd_resource type="Resource" script_class="StageData" load_steps=9 format=3]

[ext_resource type="Script" path="res://scripts/stage_data.gd" id="1"]
[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="2"]
[ext_resource type="Resource" path="res://resources/enemies/raider.tres" id="3"]
[ext_resource type="Resource" path="res://resources/enemies/rider.tres" id="4"]
[ext_resource type="Resource" path="res://resources/enemies/bowman.tres" id="5"]
[ext_resource type="Resource" path="res://resources/enemies/ram.tres" id="6"]
[ext_resource type="Resource" path="res://resources/enemies/siege.tres" id="7"]
[ext_resource type="Resource" path="res://resources/enemies/boss.tres" id="8"]

[resource]
script = ExtResource("1")
stage_name = "Greenfields 1"
region = &"greenfields"
stage_index = 0
allowed_enemies = Array[ExtResource("2")]([ExtResource("3"), ExtResource("4"), ExtResource("5"), ExtResource("6"), ExtResource("7"), ExtResource("8")])
flank_lane = 0
```

- [ ] **Step 6: Run the tests to verify they pass**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_data_classes
```

Expected: `RESULT: 72 passed, 0 failed`. Then run everything (no suite name): the remaining suites must still pass.

- [ ] **Step 7: Commit**

```bash
git add -A scripts resources tests
git commit -m "Add the horde-defense data classes and stock resources" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Wave budget and the counter triangle

Two small pure helpers every later task leans on.

**Files:**
- Create: `scripts/wave_budget.gd`, `scripts/triangle.gd`
- Test: `tests/test_wave_budget.gd`, `tests/test_triangle.gd`

**Interfaces:**
- Consumes: `TuningData`, `WaveData.Milestone`, `UnitRole.Kind` (Task 2)
- Produces:
  - `WaveBudget.phase_of(wave: int, tuning: TuningData) -> int` (1-4, clamped), `is_milestone(wave, tuning) -> bool`, `milestone_of(wave, tuning) -> WaveData.Milestone`, `budget(wave: int, stage_index: int, tuning) -> float`, `stat_mult(stage_index: int, tuning) -> float`
  - `Triangle.beats(attacker, defender) -> bool`, `multiplier(attacker, defender, tuning) -> float`, `counter_of(enemy_kind) -> UnitRole.Kind`

- [ ] **Step 1: Write the failing tests**

`tests/test_wave_budget.gd`:

```gdscript
extends RefCounted

var t

func _tu() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

func test_phase_of_groups_waves_in_fives() -> void:
	var tu := _tu()
	for w in range(1, 6):
		t.eq(WaveBudget.phase_of(w, tu), 1, "wave %d is phase 1" % w)
	t.eq(WaveBudget.phase_of(6, tu), 2, "wave 6 starts phase 2")
	t.eq(WaveBudget.phase_of(10, tu), 2, "wave 10 ends phase 2")
	t.eq(WaveBudget.phase_of(11, tu), 3, "wave 11")
	t.eq(WaveBudget.phase_of(20, tu), 4, "wave 20 is phase 4")

func test_phase_of_clamps_out_of_range_waves() -> void:
	var tu := _tu()
	t.eq(WaveBudget.phase_of(0, tu), 1, "wave 0 (before the battle) is phase 1")
	t.eq(WaveBudget.phase_of(99, tu), 4, "waves past the end stay in phase 4")

func test_milestones_are_waves_5_10_15_20() -> void:
	var tu := _tu()
	var found: Array = []
	for w in range(0, 25):
		if WaveBudget.is_milestone(w, tu):
			found.append(w)
	t.eq(found, [5, 10, 15, 20], "milestone waves")

func test_milestone_kinds_in_order() -> void:
	var tu := _tu()
	t.eq(WaveBudget.milestone_of(5, tu), WaveData.Milestone.FLANK, "wave 5 flank")
	t.eq(WaveBudget.milestone_of(10, tu), WaveData.Milestone.KEEP_STRIKE, "wave 10 keep strike")
	t.eq(WaveBudget.milestone_of(15, tu), WaveData.Milestone.SIEGE, "wave 15 siege")
	t.eq(WaveBudget.milestone_of(20, tu), WaveData.Milestone.BOSS, "wave 20 boss")
	t.eq(WaveBudget.milestone_of(7, tu), WaveData.Milestone.NONE, "wave 7 is ordinary")
	t.eq(WaveBudget.milestone_of(25, tu), WaveData.Milestone.NONE, "waves past the end have no milestone")

func test_budget_matches_the_formula() -> void:
	var tu := _tu()
	var expected := 100.0 * pow(1.12, 2) * pow(1.10, 3)
	t.check(is_equal_approx(WaveBudget.budget(3, 2, tu), expected), "stage 2 wave 3 budget")

func test_milestone_waves_get_the_multiplier() -> void:
	var tu := _tu()
	var plain := 100.0 * pow(1.10, 5)
	t.check(is_equal_approx(WaveBudget.budget(5, 0, tu), plain * 1.5), "wave 5 is 1.5x the plain formula")

func test_budget_grows_wave_over_wave_and_stage_over_stage() -> void:
	var tu := _tu()
	t.check(WaveBudget.budget(4, 0, tu) > WaveBudget.budget(3, 0, tu), "later waves are bigger")
	t.check(WaveBudget.budget(3, 1, tu) > WaveBudget.budget(3, 0, tu), "later stages are bigger")

func test_stat_mult_is_gentler_than_budget_growth() -> void:
	var tu := _tu()
	t.eq(WaveBudget.stat_mult(0, tu), 1.0, "stage 0 is the base stats")
	t.check(is_equal_approx(WaveBudget.stat_mult(10, tu), pow(1.06, 10)), "1.06 per stage")
	t.check(WaveBudget.stat_mult(10, tu) < pow(tu.growth_stage, 10), "stats grow slower than count")
```

`tests/test_triangle.gd`:

```gdscript
extends RefCounted

var t

func _tu() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

func test_infantry_beats_cavalry_beats_archers_beats_infantry() -> void:
	t.check(Triangle.beats(UnitRole.Kind.INFANTRY, UnitRole.Kind.CAVALRY), "infantry > cavalry")
	t.check(Triangle.beats(UnitRole.Kind.CAVALRY, UnitRole.Kind.ARCHERS), "cavalry > archers")
	t.check(Triangle.beats(UnitRole.Kind.ARCHERS, UnitRole.Kind.INFANTRY), "archers > infantry")
	t.check(not Triangle.beats(UnitRole.Kind.CAVALRY, UnitRole.Kind.INFANTRY), "not the reverse")

func test_multiplier_win_lose_neutral() -> void:
	var tu := _tu()
	t.eq(Triangle.multiplier(UnitRole.Kind.INFANTRY, UnitRole.Kind.CAVALRY, tu), 1.5, "winning matchup")
	t.eq(Triangle.multiplier(UnitRole.Kind.CAVALRY, UnitRole.Kind.INFANTRY, tu), 0.75, "losing matchup")
	t.eq(Triangle.multiplier(UnitRole.Kind.INFANTRY, UnitRole.Kind.INFANTRY, tu), 1.0, "same kind is neutral")

func test_enemies_outside_the_triangle_are_neutral_for_everyone() -> void:
	var tu := _tu()
	for k in UnitRole.TROOP_KINDS:
		t.eq(Triangle.multiplier(k, UnitRole.Kind.NONE, tu), 1.0, "kind %d vs NONE" % k)
		t.eq(Triangle.multiplier(UnitRole.Kind.NONE, k, tu), 1.0, "NONE vs kind %d" % k)

func test_counter_of_returns_the_kind_that_beats_it() -> void:
	t.eq(Triangle.counter_of(UnitRole.Kind.INFANTRY), UnitRole.Kind.ARCHERS, "archers counter infantry")
	t.eq(Triangle.counter_of(UnitRole.Kind.CAVALRY), UnitRole.Kind.INFANTRY, "infantry counter cavalry")
	t.eq(Triangle.counter_of(UnitRole.Kind.ARCHERS), UnitRole.Kind.CAVALRY, "cavalry counter archers")
	t.eq(Triangle.counter_of(UnitRole.Kind.NONE), UnitRole.Kind.NONE, "nothing counters NONE")
```

- [ ] **Step 2: Run them to verify they fail**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_wave_budget test_triangle
```

Expected: both suites report `could not load` (identifiers `WaveBudget` and `Triangle` not found).

- [ ] **Step 3: Implement**

`scripts/wave_budget.gd`:

```gdscript
class_name WaveBudget
extends RefCounted
## Wave and phase arithmetic from the design spec, section 8. Pure functions, no state.

## Phase (1-4) a wave belongs to; waves past the last phase stay in it.
static func phase_of(wave: int, tuning: TuningData) -> int:
	var phases := tuning.waves_per_battle / tuning.phase_length
	return clampi((wave - 1) / tuning.phase_length + 1, 1, phases)

static func is_milestone(wave: int, tuning: TuningData) -> bool:
	return wave >= 1 and wave <= tuning.waves_per_battle and wave % tuning.phase_length == 0

## FLANK, KEEP_STRIKE, SIEGE or BOSS at waves 5, 10, 15, 20; NONE everywhere else.
static func milestone_of(wave: int, tuning: TuningData) -> WaveData.Milestone:
	if not is_milestone(wave, tuning):
		return WaveData.Milestone.NONE
	return (wave / tuning.phase_length) as WaveData.Milestone

## budget(L, w) = B0 * g_L^L * g_w^w * m(w)
static func budget(wave: int, stage_index: int, tuning: TuningData) -> float:
	var m := tuning.milestone_mult if is_milestone(wave, tuning) else 1.0
	return tuning.b0 * pow(tuning.growth_stage, stage_index) * pow(tuning.growth_wave, wave) * m

## Multiplier on enemy HP and damage for a stage.
static func stat_mult(stage_index: int, tuning: TuningData) -> float:
	return pow(tuning.stat_growth, stage_index)
```

`scripts/triangle.gd`:

```gdscript
class_name Triangle
extends RefCounted
## The counter triangle: Infantry > Cavalry > Archers > Infantry. NONE is outside it.

static func beats(attacker: UnitRole.Kind, defender: UnitRole.Kind) -> bool:
	match attacker:
		UnitRole.Kind.INFANTRY:
			return defender == UnitRole.Kind.CAVALRY
		UnitRole.Kind.CAVALRY:
			return defender == UnitRole.Kind.ARCHERS
		UnitRole.Kind.ARCHERS:
			return defender == UnitRole.Kind.INFANTRY
	return false

## Damage multiplier for `attacker` hitting `defender`: win, lose or neutral.
static func multiplier(attacker: UnitRole.Kind, defender: UnitRole.Kind, tuning: TuningData) -> float:
	if beats(attacker, defender):
		return tuning.triangle_win
	if beats(defender, attacker):
		return tuning.triangle_lose
	return 1.0

## The troop kind that beats `enemy`, or NONE when the enemy is outside the triangle.
static func counter_of(enemy: UnitRole.Kind) -> UnitRole.Kind:
	for k in UnitRole.TROOP_KINDS:
		if beats(k, enemy):
			return k
	return UnitRole.Kind.NONE
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_wave_budget test_triangle
```

Expected: `RESULT: 42 passed, 0 failed` (25 + 17).

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add wave budget and counter triangle helpers" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Troop pool and formation

The living troops per wall section, and the formation that deals them. Rounding must never create or lose a troop.

**Files:**
- Create: `scripts/troop_pool.gd`, `scripts/formation.gd`
- Test: `tests/test_troop_pool.gd`, `tests/test_formation.gd`

**Interfaces:**
- Consumes: `UnitRole.Kind`, `Triangle.counter_of` (Tasks 2-3)
- Produces:
  - `TroopPool.new(initial: Array = [])` where `initial[section][kind]` are ints; `counts`, `lost`; `count(section, kind)`, `section_total(section)`, `kind_total(kind)`, `total()`, `take_losses(section, kind, n) -> int`, `heal(share: float) -> int`, `reset_to(new_counts: Array)`
  - `Formation`: `ratio: Array[float]` (Infantry, Cavalry, Archers), `shares: Array` (`shares[kind][section]`); `counts(total: int) -> Array` (`[section][kind]`, always sums to `total`); `static recommended(enemy_mix: Dictionary) -> Formation` (mix is `{UnitRole.Kind: count}`); `static apportion(total: int, weights: Array) -> Array[int]`

- [ ] **Step 1: Write the failing tests**

`tests/test_troop_pool.gd`:

```gdscript
extends RefCounted

var t

func _pool() -> TroopPool:
	return TroopPool.new([[10, 4, 6], [10, 4, 6], [10, 4, 6]])

func test_totals() -> void:
	var p := _pool()
	t.eq(p.count(0, UnitRole.Kind.CAVALRY), 4, "count")
	t.eq(p.section_total(1), 20, "section total")
	t.eq(p.kind_total(UnitRole.Kind.INFANTRY), 30, "kind total")
	t.eq(p.total(), 60, "total")

func test_empty_pool_is_all_zero() -> void:
	t.eq(TroopPool.new().total(), 0, "default pool is empty")

func test_take_losses_clamps_to_living_troops() -> void:
	var p := _pool()
	t.eq(p.take_losses(0, UnitRole.Kind.ARCHERS, 4), 4, "four die")
	t.eq(p.count(0, UnitRole.Kind.ARCHERS), 2, "two left")
	t.eq(p.take_losses(0, UnitRole.Kind.ARCHERS, 50), 2, "cannot kill more than are alive")
	t.eq(p.count(0, UnitRole.Kind.ARCHERS), 0, "none left, never negative")
	t.eq(p.take_losses(0, UnitRole.Kind.ARCHERS, -3), 0, "negative losses do nothing")

func test_heal_returns_60_percent_of_losses_once() -> void:
	var p := _pool()
	p.take_losses(0, UnitRole.Kind.INFANTRY, 10)
	p.take_losses(1, UnitRole.Kind.ARCHERS, 5)
	t.eq(p.heal(0.6), 9, "6 + 3 troops return")
	t.eq(p.count(0, UnitRole.Kind.INFANTRY), 6, "infantry: 0 left + 6 healed")
	t.eq(p.count(1, UnitRole.Kind.ARCHERS), 4, "archers: 1 left + 3 healed")
	t.eq(p.heal(0.6), 0, "a second heal finds no new losses")

func test_heal_rounds_per_cell_and_never_exceeds_losses() -> void:
	var p := _pool()
	p.take_losses(0, UnitRole.Kind.CAVALRY, 1)
	var before := p.total()
	var healed := p.heal(0.6)
	t.check(healed <= 1, "never heals more than died")
	t.eq(p.total(), before + healed, "total grows by exactly the healed amount")

func test_full_and_zero_heal_shares() -> void:
	var p := _pool()
	p.take_losses(2, UnitRole.Kind.INFANTRY, 7)
	t.eq(p.heal(1.0), 7, "share 1.0 restores everyone")
	p.take_losses(2, UnitRole.Kind.INFANTRY, 7)
	t.eq(p.heal(0.0), 0, "share 0.0 restores no one")
	t.eq(p.count(2, UnitRole.Kind.INFANTRY), 3, "the 7 stay dead")

func test_reset_to_replaces_counts_and_clears_the_loss_log() -> void:
	var p := _pool()
	p.take_losses(0, UnitRole.Kind.INFANTRY, 5)
	p.reset_to([[1, 1, 1], [2, 2, 2], [3, 3, 3]])
	t.eq(p.total(), 18, "new counts in place")
	t.eq(p.heal(1.0), 0, "old losses forgotten")

func test_pool_does_not_alias_the_array_it_was_built_from() -> void:
	var src := [[1, 1, 1], [1, 1, 1], [1, 1, 1]]
	var p := TroopPool.new(src)
	p.take_losses(0, 0, 1)
	t.eq(src[0][0], 1, "source untouched")
```

`tests/test_formation.gd`:

```gdscript
extends RefCounted

var t

func _sum(counts: Array) -> int:
	var n := 0
	for row in counts:
		for v in row:
			n += v
	return n

func test_apportion_always_sums_to_the_total() -> void:
	for total in [0, 1, 2, 7, 100, 599, 1000, 12345]:
		for weights in [[5.0, 2.0, 3.0], [1.0, 1.0, 1.0], [1.0, 0.0, 0.0], [0.3, 0.3, 0.4], [7.0, 1.0, 1.0]]:
			var parts := Formation.apportion(total, weights)
			var s := 0
			for p in parts:
				s += p
			t.eq(s, total, "apportion(%d, %s) conserves troops" % [total, str(weights)])

func test_apportion_splits_by_weight() -> void:
	t.eq(Formation.apportion(100, [5.0, 2.0, 3.0]), [50, 20, 30] as Array[int], "50/20/30")
	t.eq(Formation.apportion(10, [1.0, 1.0, 1.0]), [4, 3, 3] as Array[int], "remainder goes to the lowest index on ties")

func test_apportion_treats_bad_weights_safely() -> void:
	t.eq(Formation.apportion(9, [0.0, 0.0, 0.0]), [3, 3, 3] as Array[int], "all-zero weights split evenly")
	t.eq(Formation.apportion(9, [-5.0, 1.0, 1.0]), [0, 5, 4] as Array[int], "negative weight counts as zero")
	t.eq(Formation.apportion(-4, [1.0, 1.0, 1.0]), [0, 0, 0] as Array[int], "negative total gives nothing")
	t.eq(Formation.apportion(5, []), [] as Array[int], "no weights gives an empty split")

func test_counts_conserve_troops_for_any_capacity() -> void:
	var f := Formation.new()
	for cap in [0, 1, 3, 100, 601, 1000]:
		t.eq(_sum(f.counts(cap)), cap, "capacity %d is fully assigned" % cap)

func test_counts_follow_ratio_and_section_shares() -> void:
	var f := Formation.new()
	f.ratio = [1.0, 0.0, 1.0]
	f.shares = [[1.0, 0.0, 0.0], [1.0, 1.0, 1.0], [0.0, 0.0, 1.0]]
	var c := f.counts(100)
	t.eq(c[0], [50, 0, 0], "left section: all the infantry, no archers")
	t.eq(c[1], [0, 0, 0], "center section is empty")
	t.eq(c[2], [0, 0, 50], "right section: all the archers")

func test_default_formation_is_50_20_30_split_evenly() -> void:
	var c := Formation.new().counts(300)
	for s in 3:
		t.eq(c[s], [50, 20, 30], "section %d" % s)

func test_recommended_leans_toward_the_counters() -> void:
	var base := Formation.new()
	var vs_raiders := Formation.recommended({UnitRole.Kind.INFANTRY: 100})
	t.check(vs_raiders.ratio[UnitRole.Kind.ARCHERS] > base.ratio[UnitRole.Kind.ARCHERS] / 10.0, "infantry-heavy horde -> more archers")
	var sum := 0.0
	for r in vs_raiders.ratio:
		sum += r
	t.check(is_equal_approx(sum, 1.0), "recommended ratio sums to 1")

func test_recommended_ignores_enemies_outside_the_triangle() -> void:
	var f := Formation.recommended({UnitRole.Kind.NONE: 50})
	t.eq(f.ratio, Formation.new().ratio, "nothing to counter keeps the default")
	var empty := Formation.recommended({})
	t.eq(empty.ratio, Formation.new().ratio, "empty mix keeps the default")
```

- [ ] **Step 2: Run them to verify they fail**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_troop_pool test_formation
```

Expected: both suites report `could not load`.

- [ ] **Step 3: Implement**

`scripts/troop_pool.gd`:

```gdscript
class_name TroopPool
extends RefCounted
## Living troops per wall section and kind, plus this phase's losses (for healing at regroup).
## counts[section][kind] and lost[section][kind] are ints; kind is a UnitRole.Kind (0-2).

var counts: Array = []
var lost: Array = []

func _init(initial: Array = []) -> void:
	counts = _copy(initial) if not initial.is_empty() else _zeros()
	lost = _zeros()

func count(section: int, kind: int) -> int:
	return counts[section][kind]

func section_total(section: int) -> int:
	var n := 0
	for k in 3:
		n += counts[section][k]
	return n

func kind_total(kind: int) -> int:
	var n := 0
	for s in 3:
		n += counts[s][kind]
	return n

func total() -> int:
	return section_total(0) + section_total(1) + section_total(2)

## Removes up to n troops; returns how many actually died.
func take_losses(section: int, kind: int, n: int) -> int:
	var dead := clampi(n, 0, counts[section][kind])
	counts[section][kind] -= dead
	lost[section][kind] += dead
	return dead

## Returns `share` of this phase's losses to the living (rounded per cell) and clears the loss log.
## Returns the number of troops healed.
func heal(share: float) -> int:
	var healed := 0
	for s in 3:
		for k in 3:
			var back := roundi(lost[s][k] * share)
			counts[s][k] += back
			healed += back
			lost[s][k] = 0
	return healed

## Replaces the living counts (a new formation). The loss log is cleared.
func reset_to(new_counts: Array) -> void:
	counts = _copy(new_counts)
	lost = _zeros()

static func _zeros() -> Array:
	return [[0, 0, 0], [0, 0, 0], [0, 0, 0]]

static func _copy(src: Array) -> Array:
	var out: Array = []
	for row in src:
		out.append(row.duplicate())
	return out
```

`scripts/formation.gd`:

```gdscript
class_name Formation
extends RefCounted
## What the player sets at a regroup: the ratio of the three troop kinds, and for each kind
## how it is shared across the three wall sections. Both are weights; counts() normalises them.

## ratio[kind]: Infantry, Cavalry, Archers.
var ratio: Array[float] = [5.0, 2.0, 3.0]
## shares[kind][section]: left, center, right.
var shares: Array = [[1.0, 1.0, 1.0], [1.0, 1.0, 1.0], [1.0, 1.0, 1.0]]

## Splits `total` troops into counts[section][kind]. Always sums to exactly `total`.
func counts(total: int) -> Array:
	var per_kind := apportion(total, ratio)
	var out: Array = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
	for k in 3:
		var per_section := apportion(per_kind[k], shares[k])
		for s in 3:
			out[s][k] = per_section[s]
	return out

## The game's suggested formation for an enemy mix ({UnitRole.Kind: count}): half the default
## ratio, half weighted toward the kinds that counter what is coming.
static func recommended(enemy_mix: Dictionary) -> Formation:
	var f := Formation.new()
	var want: Array[float] = [0.0, 0.0, 0.0]
	var total := 0.0
	for role in enemy_mix:
		var counter := Triangle.counter_of(role)
		if counter != UnitRole.Kind.NONE:
			want[counter] += float(enemy_mix[role])
			total += float(enemy_mix[role])
	if total <= 0.0:
		return f
	for k in 3:
		f.ratio[k] = f.ratio[k] / 10.0 * 0.5 + want[k] / total * 0.5
	return f

## Largest-remainder split of `total` by `weights` into ints that sum to `total`.
## Negative weights count as 0; all-zero weights split evenly; ties go to the lower index.
static func apportion(total: int, weights: Array) -> Array[int]:
	var n := weights.size()
	var out: Array[int] = []
	out.resize(n)
	out.fill(0)
	if n == 0 or total <= 0:
		return out
	var w: Array[float] = []
	var sum := 0.0
	for x in weights:
		var v := maxf(float(x), 0.0)
		w.append(v)
		sum += v
	if sum <= 0.0:
		w.fill(1.0)
		sum = float(n)
	var rem: Array[float] = []
	var given := 0
	for i in n:
		var exact := float(total) * w[i] / sum
		out[i] = int(floor(exact))
		rem.append(exact - out[i])
		given += out[i]
	var left := total - given
	while left > 0:
		var best := 0
		for i in n:
			if rem[i] > rem[best]:
				best = i
		out[best] += 1
		rem[best] = -1.0
		left -= 1
	return out
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_troop_pool test_formation
```

Expected: `RESULT: 84 passed, 0 failed` (22 + 62).

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add troop pool and formation with conserving apportionment" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Wave spawner with the four milestone waves

Builds a `WaveData` from a stage and a wave number: spends the budget on the stage's enemies by weight, and shapes waves 5, 10, 15 and 20.

**Files:**
- Create: `scripts/wave_spawner.gd`
- Test: `tests/test_wave_spawner.gd`

**Interfaces:**
- Consumes: `StageData`, `TuningData`, `WaveData`, `EnemyData` (Task 2); `WaveBudget` (Task 3)
- Produces: `WaveSpawner.build(stage: StageData, tuning: TuningData, wave: int) -> WaveData`. Each spawn is `{"enemy": EnemyData, "lane": int, "delay": float, "side": bool}`; `lane` is 0-2 or `WaveData.LANE_AUTO` (-1: the section with the fewest troops when the enemy spawns, used by archer-hunting Riders).

- [ ] **Step 1: Write the failing test**

`tests/test_wave_spawner.gd`:

```gdscript
extends RefCounted

var t

func _tu() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

func _stage() -> StageData:
	return load("res://resources/stages/stage_01.tres") as StageData

func test_ordinary_wave_spends_the_budget_without_overspending() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 3)
	t.check(w.spent() <= w.budget, "spent %d of %.1f" % [w.spent(), w.budget])
	t.check(w.budget - w.spent() < 1.0, "leftover is less than the cheapest enemy (1 point)")

func test_phase_one_ordinary_waves_are_raiders_only() -> void:
	for wave in [1, 2, 3, 4]:
		var w := WaveSpawner.build(_stage(), _tu(), wave)
		t.check(w.spawns.size() > 0, "wave %d has enemies" % wave)
		for s in w.spawns:
			t.eq(s.enemy.id, &"raider", "wave %d only raiders" % wave)

func test_riders_join_in_phase_two_and_bowmen_in_phase_three() -> void:
	t.eq(WaveSpawner.build(_stage(), _tu(), 5).count_of(&"rider"), 0, "no riders before wave 6")
	t.check(WaveSpawner.build(_stage(), _tu(), 7).count_of(&"rider") > 0, "riders in wave 7")
	t.eq(WaveSpawner.build(_stage(), _tu(), 9).count_of(&"bowman"), 0, "no bowmen in phase 2")
	t.check(WaveSpawner.build(_stage(), _tu(), 12).count_of(&"bowman") > 0, "bowmen in wave 12")

func test_mix_follows_spawn_weights() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 12)
	var raiders := w.count_of(&"raider")
	var riders := w.count_of(&"rider")
	t.check(raiders > riders, "raiders (weight 6) outnumber riders (weight 3)")

func test_flank_wave_sends_a_group_down_the_flank_lane_from_the_side() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 5)
	t.eq(w.milestone, WaveData.Milestone.FLANK, "wave 5 is the flank")
	var side := 0
	for s in w.spawns:
		if s.side:
			side += 1
			t.eq(s.lane, _stage().flank_lane, "flankers use the flank lane")
	t.check(side > 0, "some enemies arrive from the side")
	t.check(side < w.spawns.size(), "the rest come the normal way")

func test_keep_strike_wave_has_rams_that_target_the_town_center() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 10)
	t.eq(w.milestone, WaveData.Milestone.KEEP_STRIKE, "wave 10")
	var rams := w.count_of(&"ram")
	t.check(rams >= 2 and rams <= 8, "a handful of rams (%d)" % rams)
	for s in w.spawns:
		if s.enemy.id == &"ram":
			t.eq(s.enemy.target, EnemyData.Target.TOWN_CENTER, "rams go for the Town Center")
	t.eq(WaveSpawner.build(_stage(), _tu(), 9).count_of(&"ram"), 0, "no rams on ordinary waves")

func test_siege_wave_has_siege_units_and_only_wave_15_does() -> void:
	t.check(WaveSpawner.build(_stage(), _tu(), 15).count_of(&"siege") > 0, "siege in wave 15")
	t.eq(WaveSpawner.build(_stage(), _tu(), 14).count_of(&"siege"), 0, "none in wave 14")

func test_boss_wave_has_exactly_one_boss_and_escorts() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 20)
	t.eq(w.milestone, WaveData.Milestone.BOSS, "wave 20")
	t.eq(w.count_of(&"boss"), 1, "one boss")
	t.check(w.spawns.size() > 1, "escorts come with it")
	t.eq(WaveSpawner.build(_stage(), _tu(), 19).count_of(&"boss"), 0, "no boss on wave 19")

func test_lanes_are_valid_and_riders_pick_the_weakest_section() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 12)
	var lanes := {}
	for s in w.spawns:
		t.check(s.lane == WaveData.LANE_AUTO or (s.lane >= 0 and s.lane <= 2), "lane %d is valid" % s.lane)
		if s.enemy.target == EnemyData.Target.ARCHERS:
			t.eq(s.lane, WaveData.LANE_AUTO, "archer hunters are auto-laned")
		else:
			lanes[s.lane] = true
	t.eq(lanes.size(), 3, "everyone else is spread over all three lanes")

func test_delays_are_sorted_and_inside_the_spawn_window() -> void:
	var w := WaveSpawner.build(_stage(), _tu(), 8)
	var last := -1.0
	for s in w.spawns:
		t.check(s.delay >= last, "delays never go backwards")
		t.check(s.delay >= 0.0 and s.delay < _tu().spawn_window, "delay inside the window")
		last = s.delay

func test_bigger_waves_and_stages_buy_more_enemies() -> void:
	t.check(WaveSpawner.build(_stage(), _tu(), 4).spawns.size() > WaveSpawner.build(_stage(), _tu(), 2).spawns.size(), "wave 4 > wave 2")
	var later := _stage().duplicate() as StageData
	later.stage_index = 5
	t.check(WaveSpawner.build(later, _tu(), 3).spawns.size() > WaveSpawner.build(_stage(), _tu(), 3).spawns.size(), "stage 5 > stage 0")

func test_stage_without_a_matching_enemy_builds_an_empty_wave_instead_of_crashing() -> void:
	var empty := StageData.new()
	var w := WaveSpawner.build(empty, _tu(), 5)
	t.eq(w.spawns.size(), 0, "no allowed enemies, no spawns")
	var boss_only := StageData.new()
	boss_only.allowed_enemies = [load("res://resources/enemies/boss.tres")] as Array[EnemyData]
	t.eq(WaveSpawner.build(boss_only, _tu(), 20).count_of(&"boss"), 1, "boss still appears without escorts")
	t.eq(WaveSpawner.build(boss_only, _tu(), 3).spawns.size(), 0, "ordinary wave with only a boss available is empty")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_wave_spawner
```

Expected: `could not load` (identifier `WaveSpawner` not found).

- [ ] **Step 3: Implement**

`scripts/wave_spawner.gd`:

```gdscript
class_name WaveSpawner
extends RefCounted
## Turns a stage and a wave number into a WaveData: spends the wave budget on the stage's
## allowed enemies and shapes the four milestone waves. Pure and deterministic.

const SPREAD := -2

static func build(stage: StageData, tuning: TuningData, wave: int) -> WaveData:
	var data := WaveData.new()
	data.wave = wave
	data.phase = WaveBudget.phase_of(wave, tuning)
	data.milestone = WaveBudget.milestone_of(wave, tuning)
	data.budget = WaveBudget.budget(wave, stage.stage_index, tuning)
	var ordinary := _pool(stage, WaveData.Milestone.NONE, wave)
	var special := _pool(stage, data.milestone, wave)
	var seq: Array = []
	var left := data.budget
	match data.milestone:
		WaveData.Milestone.FLANK:
			var share := data.budget * tuning.flank_share
			_buy(seq, ordinary, share, stage.flank_lane, true)
			left -= share
		WaveData.Milestone.KEEP_STRIKE, WaveData.Milestone.SIEGE:
			var share := data.budget * tuning.special_share
			_buy(seq, special, share, SPREAD, false)
			left -= share
		WaveData.Milestone.BOSS:
			if not special.is_empty():
				seq.append({"enemy": special[0], "lane": 1, "side": false})
			left = data.budget * tuning.escort_share
	_buy(seq, ordinary, left, SPREAD, false)
	_finish(data, seq, tuning)
	return data

## Enemies that may appear: ordinary ones from their first wave on, or those reserved for `milestone`.
static func _pool(stage: StageData, milestone: WaveData.Milestone, wave: int) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	for e in stage.allowed_enemies:
		if e.milestone != milestone:
			continue
		if milestone == WaveData.Milestone.NONE and e.first_wave > wave:
			continue
		out.append(e)
	return out

## Buys enemies from `pool` until `budget` cannot afford the cheapest one. The mix follows
## spawn_weight: each pick is the enemy with the fewest purchases per unit of weight.
static func _buy(out: Array, pool: Array[EnemyData], budget: float, lane: int, side: bool) -> void:
	if pool.is_empty():
		return
	var bought := {}
	var left := budget
	var guard := 0
	while guard < 5000:
		var pick: EnemyData = null
		var best := INF
		for e in pool:
			if maxi(e.cost, 1) > left:
				continue
			var score := float(bought.get(e.id, 0)) / maxf(e.spawn_weight, 0.001)
			if score < best:
				best = score
				pick = e
		if pick == null:
			break
		bought[pick.id] = bought.get(pick.id, 0) + 1
		left -= maxi(pick.cost, 1)
		out.append({"enemy": pick, "lane": lane, "side": side})
		guard += 1

## Resolves SPREAD lanes round-robin, sends archer-hunters to the weakest section, spreads delays.
static func _finish(data: WaveData, seq: Array, tuning: TuningData) -> void:
	var rr := 0
	for i in seq.size():
		var s: Dictionary = seq[i]
		if s.lane == SPREAD:
			if s.enemy.target == EnemyData.Target.ARCHERS:
				s.lane = WaveData.LANE_AUTO
			else:
				s.lane = rr % 3
				rr += 1
		s["delay"] = float(i) / float(seq.size()) * tuning.spawn_window
		data.spawns.append(s)
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_wave_spawner
```

Expected: `RESULT: 1186 passed, 0 failed` (most are per-spawn lane and delay checks).

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the wave spawner and milestone wave shapes" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Battle state (walls, Town Center, troops, towers, hero)

Everything the defenders own, with the small rules around it. Also adds `tests/kit.gd`, the shared builders for the battle tests that follow.

**Files:**
- Create: `scripts/battle_state.gd`, `tests/kit.gd`
- Test: `tests/test_battle_state.gd`

**Interfaces:**
- Consumes: `TuningData`, `TroopData`, `TowerData`, `HeroData` (Task 2); `TroopPool` (Task 4)
- Produces:
  - `BattleState.new(tuning, troop_defs: Dictionary, pool: TroopPool, hero: HeroData = null)`; `SECTIONS = 3`, `TOWER_SLOTS = 2`; fields `tuning, troop_defs (UnitRole.Kind -> TroopData), pool, hero, towers ([section][slot] TowerData or null), wall_hp, wall_max, town_center_hp, town_center_max, sortie_left, sortie_cooldown, hero_cooldown`
  - Methods: `refresh_wall_max(fill = false)`, `wall_broken(section)`, `damage_wall(section, amount)`, `damage_town_center(amount)`, `town_center_dead()`, `repair_walls(share)`, `crack_stage(section) -> int` (0-3), `troop_hp(kind)`, `damage_mult(kind)`, `tower_mult()`, `damage_troops(section, kind, amount) -> bool`, `damage_troops_front(section, amount) -> bool`, `tick_timers(dt)`, `reset_skill_timers()`
  - `tests/kit.gd`: `Kit.tuning()`, `stage()`, `enemy(id)`, `tower(id)`, `troop_defs()`, `state(per_section = [100, 40, 60], hero_id = "")`, `spawn(horde, id, lane, dist)`

- [ ] **Step 1: Write the kit and the failing test**

`tests/kit.gd` (not a suite: the runner only loads `test_*.gd`):

```gdscript
extends RefCounted
## Shared builders for battle tests. Not a suite: the runner only loads tests/test_*.gd.

static func tuning() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

static func stage() -> StageData:
	return load("res://resources/stages/stage_01.tres") as StageData

static func enemy(id: String) -> EnemyData:
	return load("res://resources/enemies/%s.tres" % id) as EnemyData

static func tower(id: String) -> TowerData:
	return load("res://resources/towers/%s.tres" % id) as TowerData

static func troop_defs() -> Dictionary:
	return {
		UnitRole.Kind.INFANTRY: load("res://resources/troops/infantry_t1.tres"),
		UnitRole.Kind.CAVALRY: load("res://resources/troops/cavalry_t1.tres"),
		UnitRole.Kind.ARCHERS: load("res://resources/troops/archers_t1.tres"),
	}

## A state with the same [infantry, cavalry, archers] counts in every section.
static func state(per_section: Array = [100, 40, 60], hero_id: String = "") -> BattleState:
	var hero: HeroData = null
	if hero_id != "":
		hero = load("res://resources/heroes/%s.tres" % hero_id) as HeroData
	var counts := [per_section.duplicate(), per_section.duplicate(), per_section.duplicate()]
	return BattleState.new(tuning(), troop_defs(), TroopPool.new(counts), hero)

## Spawns one enemy at `dist` in `lane` with full stats.
static func spawn(horde: Horde, id: String, lane: int, dist: float) -> void:
	horde.spawn(enemy(id), lane, dist, 1.0)
```

`tests/test_battle_state.gd`:

```gdscript
extends RefCounted

var t
const Kit = preload("res://tests/kit.gd")

func test_walls_start_full_and_infantry_raises_their_max() -> void:
	var none := Kit.state([0, 40, 60])
	t.eq(none.wall_max[0], 3000.0, "no infantry: base wall HP")
	var inf := Kit.state([200, 40, 60])
	t.check(is_equal_approx(inf.wall_max[1], 3300.0), "200 infantry: +10%")
	t.eq(inf.wall_hp[1], inf.wall_max[1], "starts at full HP")
	t.eq(inf.town_center_hp, 5000.0, "Town Center starts full")

func test_damage_wall_clamps_at_zero_and_marks_it_broken() -> void:
	var st := Kit.state()
	st.damage_wall(1, 100.0)
	t.check(is_equal_approx(st.wall_hp[1], st.wall_max[1] - 100.0), "100 damage taken")
	t.check(not st.wall_broken(1), "still standing")
	st.damage_wall(1, 999999.0)
	t.eq(st.wall_hp[1], 0.0, "never negative")
	t.check(st.wall_broken(1), "broken")
	t.check(not st.wall_broken(0), "other sections untouched")

func test_town_center_death() -> void:
	var st := Kit.state()
	t.check(not st.town_center_dead(), "alive at start")
	st.damage_town_center(4999.0)
	t.check(not st.town_center_dead(), "1 HP left")
	st.damage_town_center(10.0)
	t.eq(st.town_center_hp, 0.0, "clamped at zero")
	t.check(st.town_center_dead(), "dead")

func test_crack_stages_follow_hp() -> void:
	var st := Kit.state([0, 0, 0])
	t.eq(st.crack_stage(0), 0, "full HP is fresh")
	st.wall_hp[0] = st.wall_max[0] * 0.66
	t.eq(st.crack_stage(0), 1, "66% is scuffed")
	st.wall_hp[0] = st.wall_max[0] * 0.33
	t.eq(st.crack_stage(0), 2, "33% is cracked")
	st.wall_hp[0] = 0.0
	t.eq(st.crack_stage(0), 3, "0 is broken")

func test_repair_restores_a_share_and_clamps_at_max() -> void:
	var st := Kit.state([0, 0, 0])
	st.damage_wall(0, 2000.0)
	st.repair_walls(0.3)
	t.check(is_equal_approx(st.wall_hp[0], 1900.0), "1000 + 900 repaired")
	st.repair_walls(0.3)
	st.repair_walls(0.3)
	st.repair_walls(0.3)
	t.eq(st.wall_hp[0], st.wall_max[0], "never above max")
	t.eq(st.wall_hp[1], st.wall_max[1], "undamaged sections stay full")

func test_repair_stands_a_broken_wall_back_up() -> void:
	var st := Kit.state([0, 0, 0])
	st.damage_wall(2, 99999.0)
	st.repair_walls(0.3)
	t.check(not st.wall_broken(2), "30% repair reopens the wall")

func test_refresh_wall_max_keeps_the_hp_ratio_and_keeps_broken_walls_broken() -> void:
	var st := Kit.state([0, 0, 0])
	st.damage_wall(0, 1500.0)
	st.damage_wall(1, 99999.0)
	st.pool.reset_to([[400, 0, 0], [400, 0, 0], [0, 0, 0]])
	st.refresh_wall_max()
	t.check(is_equal_approx(st.wall_max[0], 3600.0), "400 infantry: +20%")
	t.check(is_equal_approx(st.wall_hp[0] / st.wall_max[0], 0.5), "half-health stays half-health")
	t.check(st.wall_broken(1), "a broken wall does not revive when infantry moves in")
	t.eq(st.wall_hp[2], 3000.0, "full wall stays full")

func test_damage_troops_carries_fractions_until_a_whole_troop_dies() -> void:
	var st := Kit.state([100, 40, 60])
	t.check(st.damage_troops(0, UnitRole.Kind.INFANTRY, 30.0), "infantry present")
	t.eq(st.pool.count(0, UnitRole.Kind.INFANTRY), 100, "30 of 40 HP: nobody dies yet")
	st.damage_troops(0, UnitRole.Kind.INFANTRY, 30.0)
	t.eq(st.pool.count(0, UnitRole.Kind.INFANTRY), 99, "60 damage kills one 40-HP troop")
	st.damage_troops(0, UnitRole.Kind.INFANTRY, 100.0)
	t.eq(st.pool.count(0, UnitRole.Kind.INFANTRY), 96, "carry (20) + 100 = 120 = three more")

func test_damage_troops_reports_when_nobody_is_there() -> void:
	var st := Kit.state([0, 40, 60])
	t.check(not st.damage_troops(0, UnitRole.Kind.INFANTRY, 50.0), "no infantry in the section")
	t.eq(st.pool.total(), 300, "nothing changed")

func test_damage_troops_front_hits_infantry_then_archers_then_cavalry() -> void:
	var st := Kit.state([1, 1, 1])
	st.damage_troops_front(0, 1000.0)
	t.eq(st.pool.count(0, UnitRole.Kind.INFANTRY), 0, "infantry took it")
	t.eq(st.pool.count(0, UnitRole.Kind.ARCHERS), 1, "archers untouched")
	st.pool.take_losses(0, UnitRole.Kind.INFANTRY, 1)
	st.damage_troops_front(0, 1000.0)
	t.eq(st.pool.count(0, UnitRole.Kind.ARCHERS), 0, "then archers")
	st.damage_troops_front(0, 1000.0)
	t.eq(st.pool.count(0, UnitRole.Kind.CAVALRY), 0, "then cavalry")
	t.check(not st.damage_troops_front(0, 5.0), "an empty section reports false")

func test_hero_hp_buff_makes_infantry_tougher() -> void:
	var st := Kit.state([100, 40, 60], "knight_captain")
	t.check(is_equal_approx(st.troop_hp(UnitRole.Kind.INFANTRY), 46.0), "40 HP x 1.15")
	t.eq(st.troop_hp(UnitRole.Kind.ARCHERS), 20.0, "other kinds unbuffed")
	st.damage_troops(0, UnitRole.Kind.INFANTRY, 45.0)
	t.eq(st.pool.count(0, UnitRole.Kind.INFANTRY), 100, "45 damage no longer kills a 46-HP troop")

func test_hero_damage_and_tower_buffs() -> void:
	var ranger := Kit.state([100, 40, 60], "ranger")
	t.check(is_equal_approx(ranger.damage_mult(UnitRole.Kind.ARCHERS), 1.1), "ranger buffs archer damage")
	t.eq(ranger.damage_mult(UnitRole.Kind.INFANTRY), 1.0, "not infantry")
	t.eq(ranger.tower_mult(), 1.0, "not towers")
	var mage := Kit.state([100, 40, 60], "mage")
	t.check(is_equal_approx(mage.tower_mult(), 1.2), "mage buffs towers")
	var nobody := Kit.state()
	t.eq(nobody.damage_mult(UnitRole.Kind.ARCHERS), 1.0, "no hero, no buff")
	t.eq(nobody.tower_mult(), 1.0, "no hero, no tower buff")

func test_timers_count_down_and_stop_at_zero() -> void:
	var st := Kit.state()
	st.hero_cooldown = 1.0
	st.sortie_cooldown = 0.5
	st.sortie_left[1] = 2.0
	st.tick_timers(0.75)
	t.check(is_equal_approx(st.hero_cooldown, 0.25), "hero cooldown")
	t.eq(st.sortie_cooldown, 0.0, "clamped at zero")
	t.check(is_equal_approx(st.sortie_left[1], 1.25), "sortie time left")
	st.reset_skill_timers()
	t.eq(st.hero_cooldown, 0.0, "reset")
	t.eq(st.sortie_left[1], 0.0, "sortie reset")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_state
```

Expected: `could not load` (identifier `BattleState` not found).

- [ ] **Step 3: Implement**

`scripts/battle_state.gd`:

```gdscript
class_name BattleState
extends RefCounted
## Everything the defenders own: three wall sections, the Town Center, troops, towers, the hero
## and the tap-skill timers. Pure data plus small rules; no nodes.

const SECTIONS := 3
const TOWER_SLOTS := 2

var tuning: TuningData
## UnitRole.Kind -> TroopData
var troop_defs: Dictionary
var pool: TroopPool
var hero: HeroData
## towers[section] is an Array of TOWER_SLOTS entries, each a TowerData or null.
var towers: Array = [[null, null], [null, null], [null, null]]
var wall_hp: Array[float] = [0.0, 0.0, 0.0]
var wall_max: Array[float] = [0.0, 0.0, 0.0]
var town_center_hp: float = 0.0
var town_center_max: float = 0.0
## Seconds of cavalry sortie left per section, and the shared cooldowns.
var sortie_left: Array[float] = [0.0, 0.0, 0.0]
var sortie_cooldown: float = 0.0
var hero_cooldown: float = 0.0
## Fractional troop damage not yet large enough to kill a whole troop: [section][kind].
var _carry: Array = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]

func _init(p_tuning: TuningData, p_defs: Dictionary, p_pool: TroopPool, p_hero: HeroData = null) -> void:
	tuning = p_tuning
	troop_defs = p_defs
	pool = p_pool
	hero = p_hero
	refresh_wall_max(true)
	town_center_max = tuning.town_center_hp
	town_center_hp = town_center_max

# --- walls and Town Center -------------------------------------------------

## Recomputes each section's max HP from its infantry. Keeps the HP ratio unless `fill` is set.
## A broken wall (ratio 0) stays broken.
func refresh_wall_max(fill: bool = false) -> void:
	for s in SECTIONS:
		var new_max := tuning.wall_hp * (1.0 + pool.count(s, UnitRole.Kind.INFANTRY) * tuning.infantry_wall_bonus)
		var ratio := 1.0 if fill or wall_max[s] <= 0.0 else wall_hp[s] / wall_max[s]
		wall_max[s] = new_max
		wall_hp[s] = new_max * ratio

func wall_broken(section: int) -> bool:
	return wall_hp[section] <= 0.0

func damage_wall(section: int, amount: float) -> void:
	wall_hp[section] = maxf(wall_hp[section] - amount, 0.0)

func damage_town_center(amount: float) -> void:
	town_center_hp = maxf(town_center_hp - amount, 0.0)

func town_center_dead() -> bool:
	return town_center_hp <= 0.0

## Restores `share` of each section's max HP (a broken wall stands again if share > 0).
func repair_walls(share: float) -> void:
	for s in SECTIONS:
		wall_hp[s] = minf(wall_hp[s] + wall_max[s] * share, wall_max[s])

## 0 = fresh, 1 = scuffed, 2 = cracked, 3 = broken (the three crack stages from the spec).
func crack_stage(section: int) -> int:
	if wall_hp[section] <= 0.0:
		return 3
	var ratio := wall_hp[section] / wall_max[section]
	if ratio <= 0.33:
		return 2
	if ratio <= 0.66:
		return 1
	return 0

# --- troops ------------------------------------------------------------------

func troop_hp(kind: int) -> float:
	var hp: float = troop_defs[kind].hp
	if hero and hero.buff_kind == kind and hero.buff_stat == HeroData.BuffStat.HP:
		hp *= hero.buff_mult
	return hp

func damage_mult(kind: int) -> float:
	if hero and hero.buff_kind == kind and hero.buff_stat == HeroData.BuffStat.DAMAGE:
		return hero.buff_mult
	return 1.0

func tower_mult() -> float:
	return hero.buff_mult if hero and hero.buff_towers else 1.0

## Applies damage to the troops of one kind in a section. Returns false if there are none,
## so the attacker can pick another target.
func damage_troops(section: int, kind: int, amount: float) -> bool:
	if pool.count(section, kind) <= 0:
		return false
	_carry[section][kind] += amount
	var per := troop_hp(kind)
	var n := int(_carry[section][kind] / per)
	if n > 0:
		_carry[section][kind] -= n * per
		pool.take_losses(section, kind, n)
	return true

## Damage to the front-most living troops of a section: infantry, then archers, then cavalry.
func damage_troops_front(section: int, amount: float) -> bool:
	for kind in [UnitRole.Kind.INFANTRY, UnitRole.Kind.ARCHERS, UnitRole.Kind.CAVALRY]:
		if damage_troops(section, kind, amount):
			return true
	return false

# --- timers ------------------------------------------------------------------

func tick_timers(dt: float) -> void:
	for s in SECTIONS:
		sortie_left[s] = maxf(sortie_left[s] - dt, 0.0)
	sortie_cooldown = maxf(sortie_cooldown - dt, 0.0)
	hero_cooldown = maxf(hero_cooldown - dt, 0.0)

func reset_skill_timers() -> void:
	sortie_left = [0.0, 0.0, 0.0]
	sortie_cooldown = 0.0
	hero_cooldown = 0.0
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_state
```

Expected: `RESULT: 50 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add battle state: walls, Town Center, troops, towers, hero timers" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Horde (enemy data arrays, movement, attacks, strikes)

The enemies as plain parallel arrays, the enemy turn (walk, stop at range, attack the right target) and the strike helpers the defenders use.

**Files:**
- Create: `scripts/horde.gd`
- Test: `tests/test_horde.gd`

**Interfaces:**
- Consumes: `EnemyData`, `TuningData` (Task 2); `Triangle` (Task 3); `BattleState` (Task 6); `tests/kit.gd`
- Produces: `Horde` with arrays `types, lane, dist, hp, power, from_side`; `count()`, `spawn(enemy, spawn_lane, spawn_dist, stat_mult, side = false)`, `count_in_lane(section)`, `busiest_lane() -> int` (-1 if empty), `lane_orders() -> Array` (indices per lane, nearest first), `step(dt, state)`, `strike_front(order, reach, raw, attacker, tuning)` (overkill carries to the next enemy), `strike_many(order, reach, raw, max_targets, strong_vs, strong_mult)`, `blast(section, reach, damage, knockback, lane_length)`, `reap() -> int`

- [ ] **Step 1: Write the failing test**

`tests/test_horde.gd`:

```gdscript
extends RefCounted

var t
const Kit = preload("res://tests/kit.gd")

func test_spawn_keeps_all_arrays_in_step() -> void:
	var h := Horde.new()
	h.spawn(Kit.enemy("raider"), 1, 24.0, 2.0, true)
	t.eq(h.count(), 1, "one enemy")
	t.eq(h.lane[0], 1, "lane")
	t.eq(h.dist[0], 24.0, "distance")
	t.eq(h.hp[0], 160.0, "HP scaled by the stat multiplier (80 x 2)")
	t.eq(h.power[0], 2.0, "damage multiplier stored")
	t.eq(h.from_side[0], 1, "side flag")

func test_enemies_walk_at_their_speed_and_stop_at_their_range() -> void:
	var st := Kit.state()
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 24.0)
	Kit.spawn(h, "siege", 1, 24.0)
	h.step(1.0, st)
	t.check(is_equal_approx(h.dist[0], 21.0), "raider walks 3 m in 1 s")
	t.check(is_equal_approx(h.dist[1], 22.8), "siege walks 1.2 m in 1 s")
	h.step(100.0, st)
	t.eq(h.dist[0], 0.0, "raider stops at the wall")
	t.eq(h.dist[1], 18.0, "siege stops at its 18 m range")

func test_a_raider_at_the_wall_damages_the_wall_not_the_town_center() -> void:
	var st := Kit.state([0, 0, 0])
	var h := Horde.new()
	Kit.spawn(h, "raider", 2, 0.0)
	h.step(1.0, st)
	t.check(is_equal_approx(st.wall_hp[2], st.wall_max[2] - 8.0), "8 dps for 1 s")
	t.eq(st.town_center_hp, 5000.0, "Town Center untouched while the wall stands")

func test_stat_multiplier_scales_enemy_damage() -> void:
	var st := Kit.state([0, 0, 0])
	var h := Horde.new()
	h.spawn(Kit.enemy("raider"), 0, 0.0, 2.0)
	h.step(1.0, st)
	t.check(is_equal_approx(st.wall_hp[0], st.wall_max[0] - 16.0), "double stats, double damage")

func test_enemies_at_a_broken_wall_hit_the_town_center() -> void:
	var st := Kit.state([0, 0, 0])
	st.damage_wall(0, 99999.0)
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 0.0)
	h.step(1.0, st)
	t.check(is_equal_approx(st.town_center_hp, 4992.0), "raider walks through the gap")

func test_rams_ignore_the_wall() -> void:
	var st := Kit.state([0, 0, 0])
	var h := Horde.new()
	Kit.spawn(h, "ram", 1, 0.0)
	h.step(1.0, st)
	t.check(is_equal_approx(st.town_center_hp, 4940.0), "60 dps straight to the Town Center")
	t.eq(st.wall_hp[1], st.wall_max[1], "wall untouched")

func test_riders_kill_archers_and_fall_back_to_the_wall_when_none_remain() -> void:
	var st := Kit.state([100, 40, 60])
	var h := Horde.new()
	Kit.spawn(h, "rider", 0, 0.0)
	for _i in 10:
		h.step(1.0, st)
	t.check(st.pool.count(0, UnitRole.Kind.ARCHERS) < 60, "archers are dying")
	t.eq(st.pool.count(0, UnitRole.Kind.INFANTRY), 100, "infantry spared")
	st.pool.take_losses(0, UnitRole.Kind.ARCHERS, 60)
	var wall_before := st.wall_hp[0]
	h.step(1.0, st)
	t.check(st.wall_hp[0] < wall_before, "no archers left: the rider hits the wall")

func test_bowmen_split_their_fire_between_troops_and_wall() -> void:
	var st := Kit.state([100, 40, 60])
	var h := Horde.new()
	Kit.spawn(h, "bowman", 0, 8.0)
	h.step(10.0, st)
	t.check(st.wall_hp[0] < st.wall_max[0], "wall takes half")
	t.check(st.pool.count(0, UnitRole.Kind.INFANTRY) < 100, "front troops take the other half")

func test_strike_front_carries_overkill_to_the_next_enemy() -> void:
	var h := Horde.new()
	for d in [0.2, 0.4, 0.6]:
		Kit.spawn(h, "raider", 0, d)
	var order: Array = h.lane_orders()[0]
	h.strike_front(order, 1.0, 170.0, UnitRole.Kind.NONE, Kit.tuning())
	t.eq(h.hp[order[0]], 0.0, "first raider dead (80 HP)")
	t.eq(h.hp[order[1]], 0.0, "second raider dead (80 HP)")
	t.check(is_equal_approx(h.hp[order[2]], 70.0), "10 left over hits the third")

func test_strike_front_respects_reach_and_the_triangle() -> void:
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 0.5)
	Kit.spawn(h, "raider", 0, 10.0)
	var order: Array = h.lane_orders()[0]
	h.strike_front(order, 1.0, 40.0, UnitRole.Kind.ARCHERS, Kit.tuning())
	t.check(is_equal_approx(h.hp[order[0]], 20.0), "archers vs infantry-type: 40 x 1.5 = 60 of 80")
	t.eq(h.hp[order[1]], 80.0, "the far raider is out of reach")
	h.strike_front(order, 1.0, 40.0, UnitRole.Kind.CAVALRY, Kit.tuning())
	t.eq(h.hp[order[0]], 0.0, "cavalry vs infantry-type: 40 x 0.75 = 30 still kills the 20 HP left")

func test_strike_many_hits_up_to_max_targets_with_a_bonus_for_strong_roles() -> void:
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 0.1)
	Kit.spawn(h, "rider", 0, 0.2)
	Kit.spawn(h, "raider", 0, 0.3)
	var order: Array = h.lane_orders()[0]
	var strong := PackedInt32Array([UnitRole.Kind.CAVALRY])
	h.strike_many(order, 5.0, 10.0, 2, strong, 1.5)
	t.eq(h.hp[order[0]], 70.0, "first raider takes 10")
	t.check(is_equal_approx(h.hp[order[1]], 60.0 - 15.0), "the rider takes 10 x 1.5")
	t.eq(h.hp[order[2]], 80.0, "third target is past max_targets")

func test_reap_removes_the_dead_and_keeps_survivors_intact() -> void:
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 5.0)
	Kit.spawn(h, "rider", 1, 6.0)
	Kit.spawn(h, "bowman", 2, 7.0)
	Kit.spawn(h, "ram", 0, 8.0)
	h.hp[0] = 0.0
	h.hp[2] = -3.0
	t.eq(h.reap(), 2, "two kills")
	t.eq(h.count(), 2, "two left")
	var ids: Array = []
	for i in h.count():
		ids.append(String(h.types[i].id))
		t.eq(h.hp.size(), 2, "hp array resized")
		t.eq(h.lane.size(), 2, "lane array resized")
	ids.sort()
	t.eq(ids, ["ram", "rider"], "the right two survive")
	for i in h.count():
		if h.types[i].id == &"rider":
			t.eq(h.lane[i], 1, "rider keeps its lane")
			t.eq(h.dist[i], 6.0, "rider keeps its distance")
		else:
			t.eq(h.lane[i], 0, "ram keeps its lane")
			t.eq(h.dist[i], 8.0, "ram keeps its distance")

func test_reap_on_an_empty_or_healthy_horde_does_nothing() -> void:
	var h := Horde.new()
	t.eq(h.reap(), 0, "empty")
	Kit.spawn(h, "raider", 0, 5.0)
	t.eq(h.reap(), 0, "healthy")
	t.eq(h.count(), 1, "still there")

func test_lane_orders_put_the_nearest_first() -> void:
	var h := Horde.new()
	Kit.spawn(h, "raider", 1, 9.0)
	Kit.spawn(h, "raider", 1, 3.0)
	Kit.spawn(h, "raider", 0, 5.0)
	var o := h.lane_orders()
	t.eq(o[1], [1, 0], "lane 1: the 3 m enemy before the 9 m one")
	t.eq(o[0], [2], "lane 0")
	t.eq(o[2], [], "lane 2 empty")

func test_blast_damages_and_pushes_back_only_inside_reach_and_lane() -> void:
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 5.0)
	Kit.spawn(h, "raider", 0, 23.0)
	Kit.spawn(h, "raider", 1, 5.0)
	h.blast(0, 10.0, 30.0, 3.0, 24.0)
	t.eq(h.hp[0], 50.0, "in reach: damaged")
	t.eq(h.dist[0], 8.0, "in reach: pushed back")
	t.eq(h.hp[1], 80.0, "outside reach: untouched")
	t.eq(h.hp[2], 80.0, "other lane: untouched")
	h.blast(0, 30.0, 1.0, 50.0, 24.0)
	t.eq(h.dist[1], 24.0, "knockback never goes past the spawn edge")

func test_busiest_lane() -> void:
	var h := Horde.new()
	t.eq(h.busiest_lane(), -1, "empty horde")
	Kit.spawn(h, "raider", 2, 5.0)
	Kit.spawn(h, "raider", 2, 6.0)
	Kit.spawn(h, "raider", 0, 5.0)
	t.eq(h.busiest_lane(), 2, "lane 2 has two")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_horde
```

Expected: `could not load` (identifier `Horde` not found).

- [ ] **Step 3: Implement**

`scripts/horde.gd`:

```gdscript
class_name Horde
extends RefCounted
## The enemies of one battle as plain data arrays (design spec, section 13): no nodes, no physics.
## Index i across all arrays is one enemy. Lanes are 1D: `dist` is metres from the wall.

var types: Array[EnemyData] = []
var lane := PackedInt32Array()
var dist := PackedFloat32Array()
var hp := PackedFloat32Array()
## Stage stat multiplier, applied to the enemy's damage (its HP is scaled at spawn).
var power := PackedFloat32Array()
## 1 if the enemy arrived from the side (flank), for the view only.
var from_side := PackedByteArray()

func count() -> int:
	return types.size()

func spawn(enemy: EnemyData, spawn_lane: int, spawn_dist: float, stat_mult: float, side: bool = false) -> void:
	types.append(enemy)
	lane.append(spawn_lane)
	dist.append(spawn_dist)
	hp.append(enemy.hp * stat_mult)
	power.append(stat_mult)
	from_side.append(1 if side else 0)

func count_in_lane(section: int) -> int:
	var n := 0
	for i in count():
		if lane[i] == section:
			n += 1
	return n

## The lane with the most enemies (lowest index on ties), or -1 if the horde is empty.
func busiest_lane() -> int:
	var best := -1
	var best_n := 0
	for s in BattleState.SECTIONS:
		var n := count_in_lane(s)
		if n > best_n:
			best_n = n
			best = s
	return best

## Enemy indices per lane, nearest the wall first.
func lane_orders() -> Array:
	var orders: Array = [[], [], []]
	for i in count():
		orders[lane[i]].append(i)
	for o in orders:
		o.sort_custom(func(a, b): return dist[a] < dist[b])
	return orders

# --- enemy turn -------------------------------------------------------------

## Moves every enemy toward the wall and lets the ones in range attack.
func step(dt: float, state: BattleState) -> void:
	for i in count():
		var e := types[i]
		if dist[i] > e.attack_range:
			dist[i] = maxf(dist[i] - e.speed * dt, e.attack_range)
			continue
		_attack(i, e, e.dps * power[i] * dt, state)

func _attack(i: int, e: EnemyData, dmg: float, state: BattleState) -> void:
	var s := lane[i]
	if e.target == EnemyData.Target.TOWN_CENTER:
		state.damage_town_center(dmg)
		return
	if e.target == EnemyData.Target.ARCHERS and state.damage_troops(s, UnitRole.Kind.ARCHERS, dmg):
		return
	var rest := dmg
	var to_troops := dmg * e.troop_share
	if to_troops > 0.0 and state.damage_troops_front(s, to_troops):
		rest -= to_troops
	if state.wall_broken(s):
		state.damage_town_center(rest)
	else:
		state.damage_wall(s, rest)

# --- defender turn ----------------------------------------------------------

## Spends `raw` damage on the enemies in `order` that are within `reach`, nearest first. Damage is
## scaled by the triangle against each victim; leftover damage after a kill carries to the next one.
func strike_front(order: Array, reach: float, raw: float, attacker: UnitRole.Kind, tuning: TuningData) -> void:
	var remaining := raw
	for i in order:
		if remaining <= 0.0:
			return
		if hp[i] <= 0.0:
			continue
		if dist[i] > reach:
			return
		var mult := Triangle.multiplier(attacker, types[i].role, tuning)
		var dealt := remaining * mult
		if dealt >= hp[i]:
			remaining -= hp[i] / mult
			hp[i] = 0.0
		else:
			hp[i] -= dealt
			return

## Gives each of the first `max_targets` living enemies within `reach` the full `raw` damage
## (towers: splash or pierce), times `strong_mult` for roles in `strong_vs`.
func strike_many(order: Array, reach: float, raw: float, max_targets: int, strong_vs: PackedInt32Array, strong_mult: float) -> void:
	var hit := 0
	for i in order:
		if hit >= max_targets:
			return
		if hp[i] <= 0.0:
			continue
		if dist[i] > reach:
			return
		hp[i] -= raw * (strong_mult if types[i].role in strong_vs else 1.0)
		hit += 1

## Damages every enemy within `reach` in one lane and pushes the survivors back (hero skill).
func blast(section: int, reach: float, damage: float, knockback: float, lane_length: float) -> void:
	for i in count():
		if lane[i] == section and dist[i] <= reach and hp[i] > 0.0:
			hp[i] -= damage
			dist[i] = minf(dist[i] + knockback, lane_length)

## Removes dead enemies; returns how many were removed.
func reap() -> int:
	var kills := 0
	for i in range(count() - 1, -1, -1):
		if hp[i] <= 0.0:
			_remove(i)
			kills += 1
	return kills

func _remove(i: int) -> void:
	var last := count() - 1
	if i != last:
		types[i] = types[last]
		lane[i] = lane[last]
		dist[i] = dist[last]
		hp[i] = hp[last]
		power[i] = power[last]
		from_side[i] = from_side[last]
	types.pop_back()
	lane.resize(last)
	dist.resize(last)
	hp.resize(last)
	power.resize(last)
	from_side.resize(last)
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_horde
```

Expected: `RESULT: 54 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the horde: enemy arrays, movement, attacks and defender strikes" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Combat resolver (troops and towers shoot their lane)

**Files:**
- Create: `scripts/combat_resolver.gd`
- Test: `tests/test_combat.gd`

**Interfaces:**
- Consumes: `BattleState` (Task 6), `Horde` (Task 7), `UnitRole`, `TroopData`, `TowerData`
- Produces: `CombatResolver.step(dt: float, state: BattleState, horde: Horde)`. Archers reach their `attack_range`; infantry and idle cavalry reach `melee_reach`; a sortie (`state.sortie_left[section] > 0`) gives cavalry `sortie_reach` and `sortie_mult` damage; idle cavalry deal `cavalry_reserve_mult`; hero buffs and tower buffs apply; empty hordes and empty lanes are no-ops.

- [ ] **Step 1: Write the failing test**

`tests/test_combat.gd`:

```gdscript
extends RefCounted

var t
const Kit = preload("res://tests/kit.gd")

func _hp_after(st: BattleState, id: String, dist: float, seconds: float = 1.0) -> float:
	var h := Horde.new()
	Kit.spawn(h, id, 0, dist)
	CombatResolver.step(seconds, st, h)
	return h.hp[0]

func test_archers_shoot_from_range_but_melee_troops_wait_for_the_wall() -> void:
	var archers_only := Kit.state([0, 0, 100])
	t.check(_hp_after(archers_only, "raider", 10.0) < 80.0, "archers (range 12) hit a raider 10 m out")
	var infantry_only := Kit.state([100, 0, 0])
	t.eq(_hp_after(infantry_only, "raider", 10.0), 80.0, "infantry (melee) cannot reach 10 m")
	t.check(_hp_after(infantry_only, "raider", 0.5) < 80.0, "infantry hit what touches the wall")

func test_archers_beyond_their_range_do_nothing() -> void:
	var st := Kit.state([0, 0, 100])
	t.eq(_hp_after(st, "raider", 20.0), 80.0, "20 m is outside the 12 m range")

func test_the_triangle_changes_damage_dealt() -> void:
	var archers := Kit.state([0, 0, 10])
	var vs_raider := 80.0 - _hp_after(archers, "raider", 5.0)
	var vs_rider := 60.0 - _hp_after(archers, "rider", 5.0)
	t.check(is_equal_approx(vs_raider, 10 * 5.0 * 1.5), "archers x1.5 vs infantry-type raiders")
	t.check(is_equal_approx(vs_rider, 10 * 5.0 * 0.75), "archers x0.75 vs cavalry-type riders")

func test_cavalry_wait_in_reserve_until_a_sortie() -> void:
	var st := Kit.state([0, 4, 0])
	var reserve := 60.0 - _hp_after(st, "rider", 0.5)
	t.check(is_equal_approx(reserve, 4 * 4.0 * 0.5), "reserve: half damage, wall reach only")
	t.eq(_hp_after(st, "rider", 15.0), 60.0, "reserve cavalry cannot reach 15 m")
	st.sortie_left[0] = 3.0
	var charge := 60.0 - _hp_after(st, "rider", 15.0)
	t.check(is_equal_approx(charge, 4 * 4.0 * 3.0), "sortie: triple damage out to 22 m")
	t.eq(_hp_after(st, "rider", 23.0), 60.0, "but not past 22 m")

func test_a_sortie_only_helps_the_section_it_was_sent_to() -> void:
	var st := Kit.state([0, 4, 0])
	st.sortie_left[1] = 3.0
	t.eq(_hp_after(st, "rider", 15.0), 60.0, "the enemy is in lane 0; the sortie is on section 1")

func test_towers_hit_several_targets_and_hit_strong_roles_harder() -> void:
	var st := Kit.state([0, 0, 0])
	st.towers[0][0] = Kit.tower("arrow_tower")
	t.check(is_equal_approx(80.0 - _hp_after(st, "raider", 5.0), 25.0), "arrow tower: 25 dps vs a raider")
	t.check(is_equal_approx(60.0 - _hp_after(st, "rider", 5.0), 37.5), "arrow tower: x1.5 vs a rider")
	st.towers[0][0] = null
	st.towers[0][1] = Kit.tower("cannon_tower")
	var h := Horde.new()
	for i in 8:
		Kit.spawn(h, "raider", 0, 1.0 + i * 0.1)
	CombatResolver.step(1.0, st, h)
	var hit := 0
	for i in 8:
		if h.hp[i] < 80.0:
			hit += 1
	t.eq(hit, 6, "cannon splash hits six enemies")

func test_towers_out_of_range_do_nothing_and_empty_slots_are_skipped() -> void:
	var st := Kit.state([0, 0, 0])
	st.towers[0][0] = Kit.tower("cannon_tower")
	t.eq(_hp_after(st, "raider", 11.0), 80.0, "cannon range is 10 m")
	var bare := Kit.state([0, 0, 0])
	t.eq(_hp_after(bare, "raider", 1.0), 80.0, "no towers and no troops: nobody shoots")

func test_hero_buffs_apply_to_damage() -> void:
	var plain := Kit.state([0, 0, 6])
	var buffed := Kit.state([0, 0, 6], "ranger")
	var a := 80.0 - _hp_after(plain, "raider", 5.0)
	var b := 80.0 - _hp_after(buffed, "raider", 5.0)
	t.check(is_equal_approx(b, a * 1.1), "ranger: archers +10% damage")
	var mage := Kit.state([0, 0, 0], "mage")
	mage.towers[0][0] = Kit.tower("arrow_tower")
	t.check(is_equal_approx(80.0 - _hp_after(mage, "raider", 5.0), 25.0 * 1.2), "mage: towers +20%")

func test_one_lane_cannot_shoot_another_lanes_enemies() -> void:
	var st := Kit.state([0, 0, 100])
	var h := Horde.new()
	Kit.spawn(h, "raider", 0, 5.0)
	st.pool.reset_to([[0, 0, 0], [0, 0, 100], [0, 0, 0]])
	CombatResolver.step(1.0, st, h)
	t.eq(h.hp[0], 80.0, "archers in section 1 ignore a raider in lane 0")

func test_an_empty_horde_is_a_no_op() -> void:
	var st := Kit.state()
	CombatResolver.step(1.0, st, Horde.new())
	t.eq(st.pool.total(), 600, "nothing happened")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_combat
```

Expected: `could not load` (identifier `CombatResolver` not found).

- [ ] **Step 3: Implement**

`scripts/combat_resolver.gd`:

```gdscript
class_name CombatResolver
extends RefCounted
## The defenders' turn: troops and towers of each wall section shoot the enemies in that lane.

static func step(dt: float, state: BattleState, horde: Horde) -> void:
	if horde.count() == 0:
		return
	var tu := state.tuning
	var orders := horde.lane_orders()
	for s in BattleState.SECTIONS:
		var order: Array = orders[s]
		if order.is_empty():
			continue
		for k in UnitRole.TROOP_KINDS:
			var n := state.pool.count(s, k)
			if n <= 0:
				continue
			var def: TroopData = state.troop_defs[k]
			var dps := n * def.dps * state.damage_mult(k) * dt
			var reach := tu.melee_reach
			if k == UnitRole.Kind.ARCHERS:
				reach = def.attack_range
			elif k == UnitRole.Kind.CAVALRY:
				if state.sortie_left[s] > 0.0:
					reach = tu.sortie_reach
					dps *= tu.sortie_mult
				else:
					dps *= tu.cavalry_reserve_mult
			horde.strike_front(order, reach, dps, k, tu)
		for tw in state.towers[s]:
			if tw != null:
				horde.strike_many(order, tw.attack_range, tw.dps * state.tower_mult() * dt, tw.max_targets, tw.strong_vs, tw.strong_mult)
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_combat
```

Expected: `RESULT: 20 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the combat resolver for troops and towers" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Phase machine

The shape of a battle: regroup, assault, breather, milestone regroup, win or lose.

**Files:**
- Create: `scripts/phase_machine.gd`
- Test: `tests/test_phase_machine.gd`

**Interfaces:**
- Consumes: `TuningData` (Task 2), `WaveBudget` (Task 3), `tests/kit.gd`
- Produces: `PhaseMachine.new(tuning)`; `enum State { REGROUP, ASSAULT, BREATHER, WON, LOST }`; signals `regroup_started(phase)`, `wave_started(wave)`, `wave_cleared(wave)`, `phase_cleared(phase)`, `battle_ended(victory)`; fields `state, wave, highest_wave, timer`; `is_over()`, `current_phase()`, `start()`, `ready()`, `tick(dt, wave_done: bool)`, `lose()`, `jump_to_wave(n)`, `skip_phase()`

- [ ] **Step 1: Write the failing test**

`tests/test_phase_machine.gd`:

```gdscript
extends RefCounted

var t
const Kit = preload("res://tests/kit.gd")

var _log: Array = []

func _machine() -> PhaseMachine:
	var m := PhaseMachine.new(Kit.tuning())
	_log.clear()
	m.regroup_started.connect(func(p): _log.append("regroup%d" % p))
	m.wave_started.connect(func(w): _log.append("start%d" % w))
	m.wave_cleared.connect(func(w): _log.append("clear%d" % w))
	m.phase_cleared.connect(func(p): _log.append("phase%d" % p))
	m.battle_ended.connect(func(v): _log.append("won" if v else "lost"))
	return m

## Starts the next wave and clears it at once.
func _play_wave(m: PhaseMachine) -> void:
	if m.state == PhaseMachine.State.REGROUP:
		m.ready()
	else:
		m.tick(999.0, false)
	m.tick(0.1, true)

func test_battle_opens_with_a_regroup() -> void:
	var m := _machine()
	m.start()
	t.eq(m.state, PhaseMachine.State.REGROUP, "regroup first")
	t.eq(m.timer, 15.0, "15 second countdown")
	t.eq(m.wave, 0, "no wave yet")
	t.eq(_log, ["regroup1"], "regroup for phase 1 announced")
	t.eq(m.current_phase(), 1, "phase 1")

func test_ready_starts_wave_one() -> void:
	var m := _machine()
	m.start()
	m.ready()
	t.eq(m.state, PhaseMachine.State.ASSAULT, "assault")
	t.eq(m.wave, 1, "wave 1")
	t.eq(_log, ["regroup1", "start1"], "wave announced")

func test_the_regroup_countdown_starts_the_wave_by_itself() -> void:
	var m := _machine()
	m.start()
	m.tick(14.0, false)
	t.eq(m.state, PhaseMachine.State.REGROUP, "still counting")
	m.tick(1.5, false)
	t.eq(m.state, PhaseMachine.State.ASSAULT, "countdown ended")

func test_ready_does_nothing_outside_a_regroup() -> void:
	var m := _machine()
	m.start()
	m.ready()
	m.ready()
	t.eq(m.wave, 1, "second ready ignored")

func test_a_cleared_ordinary_wave_leads_to_a_breather_then_the_next_wave() -> void:
	var m := _machine()
	m.start()
	m.ready()
	m.tick(0.1, false)
	t.eq(m.state, PhaseMachine.State.ASSAULT, "enemies still alive")
	m.tick(0.1, true)
	t.eq(m.state, PhaseMachine.State.BREATHER, "breather")
	t.eq(m.timer, 4.0, "4 seconds")
	m.tick(3.0, false)
	t.eq(m.state, PhaseMachine.State.BREATHER, "still breathing")
	m.tick(1.5, false)
	t.eq(m.state, PhaseMachine.State.ASSAULT, "next wave")
	t.eq(m.wave, 2, "wave 2")

func test_milestone_wave_ends_the_phase_with_a_regroup() -> void:
	var m := _machine()
	m.start()
	for w in 5:
		_play_wave(m)
	t.eq(m.state, PhaseMachine.State.REGROUP, "regroup after wave 5")
	t.eq(m.wave, 5, "wave 5 done")
	t.eq(_log.slice(-3), ["clear5", "phase1", "regroup2"], "phase 1 cleared, regroup for phase 2")
	t.eq(m.current_phase(), 2, "now looking at phase 2")
	m.ready()
	t.eq(m.wave, 6, "wave 6 follows")

func test_ordinary_waves_never_trigger_a_phase_clear() -> void:
	var m := _machine()
	m.start()
	for w in 4:
		_play_wave(m)
	t.check(not ("phase1" in _log), "no phase clear before wave 5")

func test_twenty_cleared_waves_win_the_battle() -> void:
	var m := _machine()
	m.start()
	for w in 20:
		_play_wave(m)
	t.eq(m.state, PhaseMachine.State.WON, "won")
	t.eq(m.highest_wave, 20, "reached wave 20")
	t.eq(_log.slice(-3), ["clear20", "phase4", "won"], "final order")
	t.eq(_log.count("regroup1") + _log.count("regroup2") + _log.count("regroup3") + _log.count("regroup4"), 4, "regroups: start + after waves 5, 10, 15")
	t.check(not ("regroup5" in _log), "no regroup after the last wave")
	m.tick(100.0, true)
	t.eq(m.state, PhaseMachine.State.WON, "stays won")

func test_losing_ends_the_battle_once() -> void:
	var m := _machine()
	m.start()
	m.ready()
	m.lose()
	t.eq(m.state, PhaseMachine.State.LOST, "lost")
	m.lose()
	t.eq(_log.count("lost"), 1, "announced once")
	m.tick(100.0, true)
	t.eq(m.state, PhaseMachine.State.LOST, "stays lost")
	t.check(m.is_over(), "over")

func test_a_loss_after_a_win_changes_nothing() -> void:
	var m := _machine()
	m.start()
	for w in 20:
		_play_wave(m)
	m.lose()
	t.eq(m.state, PhaseMachine.State.WON, "still won")

func test_jump_to_wave_starts_that_wave_and_clamps() -> void:
	var m := _machine()
	m.start()
	m.jump_to_wave(12)
	t.eq(m.wave, 12, "wave 12")
	t.eq(m.state, PhaseMachine.State.ASSAULT, "assault")
	t.eq(m.current_phase(), 3, "phase 3")
	m.jump_to_wave(99)
	t.eq(m.wave, 20, "clamped to the last wave")
	m.jump_to_wave(-4)
	t.eq(m.wave, 1, "clamped to the first wave")

func test_skip_phase_jumps_to_the_first_wave_of_the_next_phase() -> void:
	var m := _machine()
	m.start()
	m.skip_phase()
	t.eq(m.wave, 6, "from the opening regroup to wave 6")
	m.skip_phase()
	t.eq(m.wave, 11, "wave 11")
	m.skip_phase()
	m.skip_phase()
	t.eq(m.wave, 20, "capped at the final wave")

func test_current_phase_during_an_assault_is_the_waves_phase() -> void:
	var m := _machine()
	m.start()
	m.jump_to_wave(5)
	t.eq(m.current_phase(), 1, "wave 5 is still phase 1")
	m.jump_to_wave(6)
	t.eq(m.current_phase(), 2, "wave 6")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_phase_machine
```

Expected: `could not load` (identifier `PhaseMachine` not found).

- [ ] **Step 3: Implement**

`scripts/phase_machine.gd`:

```gdscript
class_name PhaseMachine
extends RefCounted
## The shape of a battle: REGROUP -> (ASSAULT -> BREATHER)* -> ASSAULT -> REGROUP ... -> WON / LOST.
## A regroup opens the battle and follows each milestone wave (5, 10, 15). Pure state, no nodes.

enum State { REGROUP, ASSAULT, BREATHER, WON, LOST }

signal regroup_started(phase: int)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal phase_cleared(phase: int)
signal battle_ended(victory: bool)

var tuning: TuningData
var state: State = State.REGROUP
## The wave in progress, or the last one cleared; 0 before the first wave.
var wave: int = 0
var highest_wave: int = 0
## Seconds left in the current REGROUP or BREATHER.
var timer: float = 0.0

func _init(p_tuning: TuningData) -> void:
	tuning = p_tuning

func is_over() -> bool:
	return state == State.WON or state == State.LOST

## The phase the player is in, or about to enter during a regroup.
func current_phase() -> int:
	return WaveBudget.phase_of(maxi(wave, 1) if state == State.ASSAULT or state == State.BREATHER else wave + 1, tuning)

## Opens the battle with its first regroup.
func start() -> void:
	state = State.REGROUP
	timer = tuning.regroup_seconds
	regroup_started.emit(1)

## The player pressed Ready (or the countdown ended).
func ready() -> void:
	if state == State.REGROUP:
		_begin_wave()

## Advances timers. `wave_done` is true once every enemy of the wave has spawned and died.
func tick(dt: float, wave_done: bool) -> void:
	match state:
		State.REGROUP, State.BREATHER:
			timer -= dt
			if timer <= 0.0:
				_begin_wave()
		State.ASSAULT:
			if wave_done:
				_finish_wave()

func lose() -> void:
	if is_over():
		return
	state = State.LOST
	battle_ended.emit(false)

## Debug: start wave `n` right now.
func jump_to_wave(n: int) -> void:
	if is_over():
		return
	wave = clampi(n, 1, tuning.waves_per_battle) - 1
	_begin_wave()

## Debug: jump to the first wave of the next phase (or the last wave if already in phase 4).
func skip_phase() -> void:
	var next_first := WaveBudget.phase_of(maxi(wave, 1), tuning) * tuning.phase_length + 1
	jump_to_wave(mini(next_first, tuning.waves_per_battle))

func _begin_wave() -> void:
	wave += 1
	highest_wave = maxi(highest_wave, wave)
	state = State.ASSAULT
	wave_started.emit(wave)

func _finish_wave() -> void:
	wave_cleared.emit(wave)
	var milestone := WaveBudget.is_milestone(wave, tuning)
	if milestone:
		phase_cleared.emit(WaveBudget.phase_of(wave, tuning))
	if wave >= tuning.waves_per_battle:
		state = State.WON
		battle_ended.emit(true)
	elif milestone:
		state = State.REGROUP
		timer = tuning.regroup_seconds
		regroup_started.emit(WaveBudget.phase_of(wave + 1, tuning))
	else:
		state = State.BREATHER
		timer = tuning.breather_seconds
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_phase_machine
```

Expected: `RESULT: 44 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the phase machine: regroups, breathers, milestones, win and lose" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Battle, factory, headless sim and the balance probe

Ties spawner, horde, resolver, state and phase machine into one tick loop, adds the player actions and full simulated battles, and a balance probe tool.

**Files:**
- Create: `scripts/battle.gd`, `scripts/battle_factory.gd`, `scripts/battle_sim.gd`, `tools/sim_battle.gd`
- Test: `tests/test_battle.gd`

**Interfaces:**
- Consumes: everything from Tasks 2-9
- Produces:
  - `Battle.new(stage, tuning, state)`; signals `enemy_killed`, `wall_damaged(section, amount)`; fields `tuning, stage, state, horde, phase, kills, started`; `start()` (once), `is_running()`, `tick(dt)`, `in_regroup()`, `apply_formation(f: Formation) -> bool`, `set_tower(section, slot, tower) -> bool`, `ready()`, `preview_next_phase() -> Dictionary` (`{phase, waves: [{wave, milestone, flank_lane}], mix: {enemy_id: count}, roles: {UnitRole.Kind: count}}`), `use_hero_skill(section) -> bool`, `use_sortie(section) -> bool`, `debug_jump_to_wave(n)`, `debug_skip_phase()`
  - `BattleFactory.create(capacity: int, formation: Formation = null, hero_id: String = "knight_captain", tower_id: String = "") -> Battle`
  - `BattleSim.run(battle, tactics = true, dt = 0.1, max_seconds = 3600.0) -> Dictionary` with `victory, timed_out, highest_wave, seconds, kills, town_center, troops_left`

- [ ] **Step 1: Write the failing test**

`tests/test_battle.gd`:

```gdscript
extends RefCounted

var t
const Kit = preload("res://tests/kit.gd")

var _kills: int = 0
var _walls: int = 0

## Ticks until `done` returns true; returns false if it never did within `max_ticks`.
func _tick_until(b: Battle, done: Callable, max_ticks: int = 20000, dt: float = 0.1) -> bool:
	for _i in max_ticks:
		if done.call():
			return true
		b.tick(dt)
	return done.call()

func _started(capacity: int = 1500, formation: Formation = null, hero: String = "knight_captain") -> Battle:
	var b := BattleFactory.create(capacity, formation, hero)
	b.start()
	return b

func test_start_opens_the_first_regroup_once() -> void:
	var b := BattleFactory.create(600)
	t.check(not b.is_running(), "not running before start")
	b.tick(5.0)
	t.eq(b.phase.timer, 0.0, "ticks before start do nothing")
	b.start()
	b.start()
	t.check(b.is_running(), "running")
	t.check(b.in_regroup(), "in the opening regroup")
	t.eq(b.phase.timer, 15.0, "countdown set once")

func test_apply_formation_redeals_the_living_troops_during_a_regroup() -> void:
	var b := _started(600)
	var f := Formation.new()
	f.ratio = [1.0, 0.0, 0.0]
	f.shares = [[1.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
	t.check(b.apply_formation(f), "accepted in a regroup")
	t.eq(b.state.pool.total(), 600, "no troops created or lost")
	t.eq(b.state.pool.count(0, UnitRole.Kind.INFANTRY), 600, "all infantry on the left")
	t.check(is_equal_approx(b.state.wall_max[0], 3000.0 * (1.0 + 600 * 0.0005)), "left wall max grows with its infantry")

func test_apply_formation_is_refused_during_an_assault() -> void:
	var b := _started(600)
	b.ready()
	var before := b.state.pool.counts.duplicate(true)
	t.check(not b.apply_formation(Formation.new()), "refused")
	t.eq(b.state.pool.counts, before, "troops untouched")

func test_apply_formation_after_losses_redeals_only_the_survivors() -> void:
	var b := _started(600)
	b.state.pool.take_losses(0, UnitRole.Kind.INFANTRY, 50)
	b.apply_formation(Formation.new())
	t.eq(b.state.pool.total(), 550, "survivors only")

func test_set_tower_validates_phase_section_and_slot() -> void:
	var b := _started(600)
	var arrow := Kit.tower("arrow_tower")
	t.check(b.set_tower(1, 0, arrow), "valid placement")
	t.eq(b.state.towers[1][0], arrow, "placed")
	t.check(b.set_tower(1, 0, null), "clearing is allowed")
	t.eq(b.state.towers[1][0], null, "cleared")
	t.check(not b.set_tower(3, 0, arrow), "section 3 does not exist")
	t.check(not b.set_tower(-1, 0, arrow), "negative section")
	t.check(not b.set_tower(0, 2, arrow), "slot 2 does not exist")
	b.ready()
	t.check(not b.set_tower(0, 0, arrow), "towers are fixed during a phase")

func test_hero_skill_only_works_in_an_assault_and_respects_its_cooldown() -> void:
	var b := _started(0)
	t.check(not b.use_hero_skill(0), "not in a regroup")
	b.ready()
	b.tick(2.0)
	t.check(b.horde.count() > 0, "enemies have spawned")
	var lane := b.horde.busiest_lane()
	var hp_before := b.horde.hp.duplicate()
	t.check(b.use_hero_skill(lane), "skill fires")
	t.check(b.state.hero_cooldown > 0.0, "cooldown started")
	t.check(not b.use_hero_skill(lane), "second tap is on cooldown")
	var damaged := 0
	for i in b.horde.count():
		if b.horde.hp[i] < hp_before[i]:
			damaged += 1
	t.check(damaged > 0, "the skill hurt someone")
	t.check(not b.use_hero_skill(7), "bad section refused")

func test_hero_skill_needs_a_hero() -> void:
	var b := BattleFactory.create(0, null, "")
	b.start()
	b.ready()
	b.tick(2.0)
	t.check(not b.use_hero_skill(0), "no hero, no skill")

func test_sortie_needs_cavalry_in_that_section_and_respects_its_cooldown() -> void:
	var f := Formation.new()
	f.shares = [[1.0, 1.0, 1.0], [1.0, 0.0, 1.0], [1.0, 1.0, 1.0]]
	var b := _started(600, f)
	t.check(not b.use_sortie(0), "not during a regroup")
	b.ready()
	t.check(not b.use_sortie(1), "section 1 has no cavalry")
	t.check(b.use_sortie(0), "section 0 has cavalry")
	t.eq(b.state.sortie_left[0], 4.0, "sortie lasts 4 s")
	t.check(not b.use_sortie(2), "shared cooldown")
	b.state.tick_timers(10.5)
	t.check(b.use_sortie(2), "cooldown over")

func test_regroup_heals_sixty_percent_and_repairs_walls() -> void:
	var b := _started(1500)
	b.ready()
	t.check(_tick_until(b, func(): return b.phase.wave == 5), "reach wave 5")
	b.state.pool.take_losses(0, UnitRole.Kind.INFANTRY, 10)
	var infantry_after_losses := b.state.pool.count(0, UnitRole.Kind.INFANTRY)
	b.state.damage_wall(1, 2000.0)
	var wall_max := b.state.wall_max[1]
	t.check(_tick_until(b, func(): return b.in_regroup()), "wave 5 clears into a regroup")
	t.eq(b.state.pool.count(0, UnitRole.Kind.INFANTRY), infantry_after_losses + 6, "6 of 10 return")
	t.check(is_equal_approx(b.state.wall_hp[1], wall_max - 2000.0 + 0.3 * wall_max), "wall repaired by 30% of its max")
	t.eq(b.state.pool.lost[0][UnitRole.Kind.INFANTRY], 0, "loss log cleared")

func test_regroup_resets_skill_cooldowns() -> void:
	var b := _started(1500)
	b.ready()
	b.tick(2.0)
	b.use_hero_skill(b.horde.busiest_lane())
	t.check(_tick_until(b, func(): return b.in_regroup()), "reach the first milestone regroup")
	t.eq(b.state.hero_cooldown, 0.0, "hero ready again")
	t.eq(b.state.sortie_cooldown, 0.0, "sortie ready again")

func test_preview_describes_the_next_phase() -> void:
	var b := _started(600)
	var p := b.preview_next_phase()
	t.eq(p.phase, 1, "phase 1 first")
	t.eq(p.waves.size(), 5, "five waves")
	t.eq(p.waves[4].wave, 5, "ends at wave 5")
	t.eq(p.waves[4].milestone, WaveData.Milestone.FLANK, "with the flank")
	t.eq(p.waves[4].flank_lane, 0, "and says which lane")
	t.eq(p.mix.keys(), [&"raider"], "phase 1 is raiders only")
	t.check(p.roles.get(UnitRole.Kind.INFANTRY, 0) > 0, "roles are counted for the formation hint")

func test_preview_after_the_first_milestone_describes_phase_two() -> void:
	var b := _started(1500)
	b.ready()
	_tick_until(b, func(): return b.in_regroup())
	var p := b.preview_next_phase()
	t.eq(p.phase, 2, "phase 2")
	t.eq(p.waves[0].wave, 6, "starts at wave 6")
	t.eq(p.waves[4].milestone, WaveData.Milestone.KEEP_STRIKE, "ends with the keep strike")
	t.check(p.mix.has(&"rider"), "riders have joined")
	t.check(p.mix.has(&"ram"), "the rams are listed")

func test_preview_for_the_last_phase_stops_at_wave_20() -> void:
	var b := _started(600)
	b.debug_jump_to_wave(15)
	b.phase.state = PhaseMachine.State.REGROUP
	var p := b.preview_next_phase()
	t.eq(p.waves.size(), 5, "waves 16-20")
	t.eq(p.waves[4].wave, 20, "ends at 20")
	t.check(p.mix.has(&"boss"), "the boss is listed")

func test_riders_spawn_in_the_least_defended_section() -> void:
	var f := Formation.new()
	f.shares = [[1.0, 1.0, 0.0], [1.0, 1.0, 0.0], [1.0, 1.0, 0.0]]
	var b := _started(600, f)
	b.debug_jump_to_wave(7)
	b.tick(7.0)
	var riders := 0
	for i in b.horde.count():
		if b.horde.types[i].id == &"rider":
			riders += 1
			t.eq(b.horde.lane[i], 2, "rider heads for the empty right section")
	t.check(riders > 0, "riders spawned")

func test_debug_jump_replaces_the_horde_and_sets_the_wave() -> void:
	var b := _started(600)
	b.ready()
	b.tick(3.0)
	t.check(b.horde.count() > 0, "wave 1 under way")
	b.debug_jump_to_wave(12)
	t.eq(b.horde.count(), 0, "old enemies gone")
	t.eq(b.phase.wave, 12, "wave 12")
	b.debug_skip_phase()
	t.eq(b.phase.wave, 16, "phase 4 starts at wave 16")

func test_signals_report_kills_and_wall_damage() -> void:
	_kills = 0
	_walls = 0
	var b := _started(100)
	b.enemy_killed.connect(func(): _kills += 1)
	b.wall_damaged.connect(func(_s, _a): _walls += 1)
	b.ready()
	_tick_until(b, func(): return b.phase.wave >= 3)
	t.check(_kills > 0, "kills reported")
	t.eq(_kills, b.kills, "every kill reported exactly once")
	t.check(_walls > 0, "wall damage reported")

func test_a_strong_defense_wins_stage_one() -> void:
	var r := BattleSim.run(BattleFactory.create(2500), true)
	t.check(r.victory, "2500 troops win")
	t.eq(r.highest_wave, 20, "all 20 waves")
	t.check(not r.timed_out, "finished on its own")
	t.check(r.seconds >= 150.0 and r.seconds <= 900.0, "a battle takes minutes, not seconds or hours (%.0f s)" % r.seconds)
	t.check(r.kills > 1000, "a real horde (%d kills)" % r.kills)

func test_no_defense_loses_early() -> void:
	var r := BattleSim.run(BattleFactory.create(0, null, ""), true)
	t.check(not r.victory, "an undefended town falls")
	t.check(r.highest_wave <= 3, "within the first waves (wave %d)" % r.highest_wave)
	t.eq(r.town_center, 0.0, "the Town Center is what fell")

func test_more_troops_never_do_worse() -> void:
	var last := 0
	for cap in [0, 300, 600, 1000, 2500]:
		var r := BattleSim.run(BattleFactory.create(cap), true)
		t.check(r.highest_wave >= last, "capacity %d reaches wave %d, at least the previous %d" % [cap, r.highest_wave, last])
		last = r.highest_wave

func test_the_same_setup_always_plays_out_the_same_way() -> void:
	var a := BattleSim.run(BattleFactory.create(600), true)
	var b := BattleSim.run(BattleFactory.create(600), true)
	t.eq(a, b, "deterministic")

func test_a_finished_battle_ignores_further_ticks() -> void:
	var b := BattleFactory.create(0, null, "")
	BattleSim.run(b, false)
	var wave := b.phase.wave
	var kills := b.kills
	b.tick(100.0)
	t.eq(b.phase.wave, wave, "wave unchanged")
	t.eq(b.kills, kills, "kills unchanged")
	t.check(not b.is_running(), "not running")
	t.check(not b.apply_formation(Formation.new()), "no formation changes after the end")

func test_an_army_that_cannot_reach_the_siege_is_beaten_in_finite_time() -> void:
	var no_cavalry := Formation.new()
	no_cavalry.ratio = [5.0, 0.0, 5.0]
	var r := BattleSim.run(BattleFactory.create(1500, no_cavalry, ""), false)
	t.check(not r.timed_out, "the battle ends on its own (wave %d, %.0f s)" % [r.highest_wave, r.seconds])
	t.check(not r.victory, "archers (12 m), towers (14 m) and melee cannot touch siege units firing from 18 m")
	t.eq(r.highest_wave, 15, "the siege wave is where it ends")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle
```

Expected: `could not load` (identifier `BattleFactory` / `Battle` not found).

- [ ] **Step 3: Implement**

`scripts/battle.gd`:

```gdscript
class_name Battle
extends RefCounted
## One 20-wave defense. Owns the horde, the phase machine and the defenders' state, and runs
## them in order each tick. No nodes: the view calls tick(delta) and reads the state.
## Phase signals live on `phase`; the scene layer forwards everything to EventBus (class scripts
## cannot name autoloads when the headless runner compiles them).

signal enemy_killed
signal wall_damaged(section: int, amount: float)

var tuning: TuningData
var stage: StageData
var state: BattleState
var horde := Horde.new()
var phase: PhaseMachine
var kills: int = 0
var started: bool = false
var _wave: WaveData
var _clock: float = 0.0
var _next_spawn: int = 0

func _init(p_stage: StageData, p_tuning: TuningData, p_state: BattleState) -> void:
	stage = p_stage
	tuning = p_tuning
	state = p_state
	phase = PhaseMachine.new(tuning)
	# Connected first, so the state is ready before any later listener (the HUD) reacts.
	phase.wave_started.connect(_on_wave_started)
	phase.regroup_started.connect(_on_regroup_started)

## Opens the first regroup. Call once, after the view has connected its listeners.
func start() -> void:
	if started:
		return
	started = true
	phase.start()

func is_running() -> bool:
	return started and not phase.is_over()

func tick(dt: float) -> void:
	if not is_running():
		return
	state.tick_timers(dt)
	if phase.state == PhaseMachine.State.ASSAULT:
		var walls_before := state.wall_hp.duplicate()
		_release_spawns(dt)
		horde.step(dt, state)
		CombatResolver.step(dt, state, horde)
		var dead := horde.reap()
		kills += dead
		for _i in dead:
			enemy_killed.emit()
		for s in BattleState.SECTIONS:
			if state.wall_hp[s] < walls_before[s]:
				wall_damaged.emit(s, walls_before[s] - state.wall_hp[s])
		if state.town_center_dead():
			phase.lose()
			return
	phase.tick(dt, _wave_done())

# --- regroup actions (only while the phase machine is in REGROUP) -----------------------

func in_regroup() -> bool:
	return is_running() and phase.state == PhaseMachine.State.REGROUP

## Re-deals the living troops by the formation. Returns false outside a regroup.
func apply_formation(f: Formation) -> bool:
	if not in_regroup():
		return false
	state.pool.reset_to(f.counts(state.pool.total()))
	state.refresh_wall_max()
	return true

## Puts a tower (or null to clear) in a slot. Returns false outside a regroup or for a bad slot.
func set_tower(section: int, slot: int, tower: TowerData) -> bool:
	if not in_regroup() or section < 0 or section >= BattleState.SECTIONS or slot < 0 or slot >= BattleState.TOWER_SLOTS:
		return false
	state.towers[section][slot] = tower
	return true

func ready() -> void:
	if in_regroup():
		phase.ready()

## What the next phase brings: waves with their milestones, the enemy mix by id and by triangle role.
func preview_next_phase() -> Dictionary:
	var first := phase.wave + 1
	var last := mini(phase.wave + tuning.phase_length, tuning.waves_per_battle)
	var out := {"phase": WaveBudget.phase_of(first, tuning), "waves": [], "mix": {}, "roles": {}}
	for w in range(first, last + 1):
		var data := WaveSpawner.build(stage, tuning, w)
		out.waves.append({"wave": w, "milestone": data.milestone, "flank_lane": stage.flank_lane})
		for s in data.spawns:
			var e: EnemyData = s.enemy
			out.mix[e.id] = out.mix.get(e.id, 0) + 1
			out.roles[e.role] = out.roles.get(e.role, 0) + 1
	return out

# --- live tactics (only during an assault) ----------------------------------------------

func use_hero_skill(section: int) -> bool:
	if phase.state != PhaseMachine.State.ASSAULT or state.hero == null or state.hero_cooldown > 0.0:
		return false
	if section < 0 or section >= BattleState.SECTIONS:
		return false
	var h := state.hero
	horde.blast(section, h.skill_reach, h.skill_damage, h.skill_knockback, tuning.lane_length)
	state.hero_cooldown = h.skill_cooldown
	return true

func use_sortie(section: int) -> bool:
	if phase.state != PhaseMachine.State.ASSAULT or state.sortie_cooldown > 0.0:
		return false
	if section < 0 or section >= BattleState.SECTIONS or state.pool.count(section, UnitRole.Kind.CAVALRY) <= 0:
		return false
	state.sortie_left[section] = tuning.sortie_duration
	state.sortie_cooldown = tuning.sortie_cooldown
	return true

# --- debug ---------------------------------------------------------------------------------

func debug_jump_to_wave(n: int) -> void:
	if not is_running():
		return
	horde = Horde.new()
	phase.jump_to_wave(n)

func debug_skip_phase() -> void:
	if not is_running():
		return
	horde = Horde.new()
	phase.skip_phase()

# --- internals -----------------------------------------------------------------------------

func _on_wave_started(w: int) -> void:
	_wave = WaveSpawner.build(stage, tuning, w)
	_clock = 0.0
	_next_spawn = 0

func _on_regroup_started(_phase: int) -> void:
	state.pool.heal(tuning.heal_share)
	state.repair_walls(tuning.wall_repair_share)
	state.reset_skill_timers()

func _wave_done() -> bool:
	return _wave != null and _next_spawn >= _wave.spawns.size() and horde.count() == 0

func _release_spawns(dt: float) -> void:
	_clock += dt
	var mult := WaveBudget.stat_mult(stage.stage_index, tuning)
	while _next_spawn < _wave.spawns.size() and _wave.spawns[_next_spawn].delay <= _clock:
		var s: Dictionary = _wave.spawns[_next_spawn]
		horde.spawn(s.enemy, _resolve_lane(s.lane), tuning.lane_length, mult, s.side)
		_next_spawn += 1

## LANE_AUTO means the section with the fewest troops (lowest index on ties).
func _resolve_lane(lane: int) -> int:
	if lane != WaveData.LANE_AUTO:
		return lane
	var best := 0
	for s in range(1, BattleState.SECTIONS):
		if state.pool.section_total(s) < state.pool.section_total(best):
			best = s
	return best
```

`scripts/battle_factory.gd`:

```gdscript
class_name BattleFactory
extends RefCounted
## Builds a Battle from the stock resources: stage 1, default tuning and tier-1 troops.

## `capacity` troops dealt by `formation` (default 50/20/30, even), an optional hero id
## ("knight_captain", "ranger", "mage") and optionally one tower type in every slot.
static func create(capacity: int, formation: Formation = null, hero_id: String = "knight_captain", tower_id: String = "") -> Battle:
	var tuning := load("res://resources/tuning/default.tres") as TuningData
	var stage := load("res://resources/stages/stage_01.tres") as StageData
	var defs := {
		UnitRole.Kind.INFANTRY: load("res://resources/troops/infantry_t1.tres"),
		UnitRole.Kind.CAVALRY: load("res://resources/troops/cavalry_t1.tres"),
		UnitRole.Kind.ARCHERS: load("res://resources/troops/archers_t1.tres"),
	}
	var f := formation if formation != null else Formation.new()
	var hero: HeroData = null
	if hero_id != "":
		hero = load("res://resources/heroes/%s.tres" % hero_id) as HeroData
	var st := BattleState.new(tuning, defs, TroopPool.new(f.counts(capacity)), hero)
	if tower_id != "":
		var tower := load("res://resources/towers/%s.tres" % tower_id) as TowerData
		for s in BattleState.SECTIONS:
			for slot in BattleState.TOWER_SLOTS:
				st.towers[s][slot] = tower
	return Battle.new(stage, tuning, st)
```

`scripts/battle_sim.gd`:

```gdscript
class_name BattleSim
extends RefCounted
## Runs a Battle to its end with no view: skips regroup countdowns and optionally plays the
## light tactics (hero skill and cavalry sortie on the busiest lane). Used by tests and tools/sim_battle.gd.

static func run(battle: Battle, tactics: bool = true, dt: float = 0.1, max_seconds: float = 3600.0) -> Dictionary:
	battle.start()
	var elapsed := 0.0
	while battle.is_running() and elapsed < max_seconds:
		if battle.in_regroup():
			battle.ready()
		elif tactics and battle.phase.state == PhaseMachine.State.ASSAULT:
			var lane := battle.horde.busiest_lane()
			if lane >= 0:
				battle.use_hero_skill(lane)
				battle.use_sortie(lane)
		battle.tick(dt)
		elapsed += dt
	return {
		"victory": battle.phase.state == PhaseMachine.State.WON,
		"timed_out": battle.is_running(),
		"highest_wave": battle.phase.highest_wave,
		"seconds": elapsed,
		"kills": battle.kills,
		"town_center": battle.state.town_center_hp,
		"troops_left": battle.state.pool.total(),
	}
```

`tools/sim_battle.gd` (balance probe, not part of the test suite):

```gdscript
extends SceneTree
## Balance probe: godot --headless --path . -s res://tools/sim_battle.gd
## Prints how stage 1 plays out for a few capacities, hero and tower setups.

func _initialize() -> void:
	for cap in [0, 300, 600, 1000, 1500, 2500]:
		_report("cap %d, default, no towers" % cap, BattleFactory.create(cap, null, "knight_captain", ""))
	for tower in ["arrow_tower", "crossbow_tower", "cannon_tower"]:
		_report("cap 600, default, %s" % tower, BattleFactory.create(600, null, "knight_captain", tower))
	var archers := Formation.new()
	archers.ratio = [3.0, 1.0, 6.0]
	_report("cap 600, archer-heavy", BattleFactory.create(600, archers, "ranger", "arrow_tower"))
	var all_inf := Formation.new()
	all_inf.ratio = [1.0, 0.0, 0.0]
	_report("cap 600, all infantry", BattleFactory.create(600, all_inf, "knight_captain", ""))
	quit()

func _report(label: String, battle: Battle) -> void:
	var r := BattleSim.run(battle, true)
	print("%-34s -> %s wave %2d  tc %5.0f  troops %4d  kills %5d  %4.0fs%s" % [label, "WIN " if r.victory else "LOSE", r.highest_wave, r.town_center, r.troops_left, r.kills, r.seconds, " TIMEOUT" if r.timed_out else ""])
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle
```

Expected: `RESULT: 134 passed, 0 failed`.

- [ ] **Step 5: Run the balance probe and compare**

```bash
godot --headless --path . -s res://tools/sim_battle.gd
```

Expected (a battle takes about 5 minutes of simulated time; the exact numbers may differ a little if you tuned something):

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
```

If the shape is different (a win at 300 troops, a loss at 2500), something in Tasks 6-9 diverged from the code above.

- [ ] **Step 6: Commit**

```bash
git add -A scripts tests tools
git commit -m "Add the battle loop, factory, headless sim and balance probe" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Battle view (3D grey-box battlefield)

Three lanes running away from the camera, the wall at z=0, the Town Center behind it, enemies as one `MultiMesh`, troops as small stand-in models plus a count label per section.

**Files:**
- Create: `scripts/battle_view.gd`
- Test: `tests/test_battle_view.gd`

**Interfaces:**
- Consumes: `Battle` (Task 10), `BattleFactory`, `UnitRole`
- Produces: `BattleView` (`Node3D`) with `battle: Battle`; constants `LANE_X`, `MAX_ENEMIES = 500`, `TROOPS_PER_MODEL = 100`, `MAX_TROOP_MODELS = 12`, `WALL_COLORS`, `ROLE_COLORS`; `refresh()`, `visible_enemy_count()`, `wall_color(section)`, `troop_model_count(section)`, `troop_label(section)`, `tower_visible(section, slot)`. It reads the battle every frame and never changes it.

- [ ] **Step 1: Write the failing test**

`tests/test_battle_view.gd`:

```gdscript
extends RefCounted

var t

func _view(b: Battle) -> BattleView:
	var v := BattleView.new()
	v.battle = b
	t.root.add_child(v)
	return v

func test_view_without_a_battle_does_not_crash() -> void:
	var v := BattleView.new()
	t.root.add_child(v)
	await t.process_frame
	v.refresh()
	t.eq(v.visible_enemy_count(), 0, "nothing to draw")
	v.queue_free()

func test_enemy_instances_follow_the_horde() -> void:
	var b := BattleFactory.create(1500)
	b.start()
	b.ready()
	var v := _view(b)
	for _i in 30:
		b.tick(0.1)
	v.refresh()
	t.check(b.horde.count() > 0, "enemies exist")
	t.eq(v.visible_enemy_count(), mini(b.horde.count(), BattleView.MAX_ENEMIES), "one instance per enemy")
	v.queue_free()

func test_enemy_instances_are_capped() -> void:
	var b := BattleFactory.create(100)
	var v := _view(b)
	for i in 700:
		b.horde.spawn(load("res://resources/enemies/raider.tres"), i % 3, 20.0, 1.0)
	v.refresh()
	t.eq(v.visible_enemy_count(), 500, "no more than 500 drawn")
	t.eq(b.horde.count(), 700, "but all 700 still exist")
	v.queue_free()

func test_wall_color_tracks_the_crack_stage() -> void:
	var b := BattleFactory.create(0, null, "")
	var v := _view(b)
	v.refresh()
	var fresh := v.wall_color(1)
	t.eq(fresh, BattleView.WALL_COLORS[0], "fresh wall")
	b.state.damage_wall(1, b.state.wall_max[1] * 0.5)
	v.refresh()
	t.eq(v.wall_color(1), BattleView.WALL_COLORS[1], "scuffed at half health")
	b.state.damage_wall(1, 99999.0)
	v.refresh()
	t.eq(v.wall_color(1), BattleView.WALL_COLORS[3], "broken")
	t.eq(v.wall_color(0), fresh, "other walls unaffected")
	v.queue_free()

func test_troop_models_and_label_follow_the_pool() -> void:
	var b := BattleFactory.create(1500)
	var v := _view(b)
	v.refresh()
	t.eq(v.troop_label(0), "I 250  C 100  A 150", "label shows the real numbers")
	t.eq(v.troop_model_count(0), 5, "500 troops = 5 stand-in models at 100 each")
	b.state.pool.take_losses(0, UnitRole.Kind.INFANTRY, 250)
	v.refresh()
	t.eq(v.troop_label(0), "I 0  C 100  A 150", "losses show up")
	t.eq(v.troop_model_count(0), 3, "250 troops = 3 models")
	v.queue_free()

func test_empty_section_draws_no_models() -> void:
	var b := BattleFactory.create(0, null, "")
	var v := _view(b)
	v.refresh()
	t.eq(v.troop_model_count(2), 0, "nobody there")
	v.queue_free()

func test_huge_armies_cap_their_models() -> void:
	var b := BattleFactory.create(30000)
	var v := _view(b)
	v.refresh()
	t.eq(v.troop_model_count(1), BattleView.MAX_TROOP_MODELS, "model count capped")
	v.queue_free()

func test_tower_markers_show_only_occupied_slots() -> void:
	var b := BattleFactory.create(100)
	b.start()
	var v := _view(b)
	v.refresh()
	t.check(not v.tower_visible(1, 0), "empty slot hidden")
	b.set_tower(1, 0, load("res://resources/towers/arrow_tower.tres"))
	v.refresh()
	t.check(v.tower_visible(1, 0), "occupied slot shown")
	t.check(not v.tower_visible(1, 1), "its neighbour still hidden")
	v.queue_free()
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_view
```

Expected: `could not load` (identifier `BattleView` not found).

- [ ] **Step 3: Implement**

`scripts/battle_view.gd`. The camera is fixed to the *width* (`KEEP_WIDTH`) because a portrait screen is narrow: with the default height-fixed field of view the outer lanes and most of the horde fall off the screen.

```gdscript
class_name BattleView
extends Node3D
## Grey-box 3D battlefield: three lanes running away from the camera, the wall at z=0, the Town
## Center behind it. Enemies are one MultiMesh; troops are one small MultiMesh per section.
## Reads the Battle every frame and never changes it.

const LANE_X := [-6.0, 0.0, 6.0]
const MAX_ENEMIES := 500
const TROOPS_PER_MODEL := 100
const MAX_TROOP_MODELS := 12
const WALL_COLORS := [Color(0.62, 0.52, 0.4), Color(0.58, 0.42, 0.3), Color(0.45, 0.3, 0.22), Color(0.2, 0.15, 0.12)]
const ROLE_COLORS := {
	UnitRole.Kind.INFANTRY: Color(0.85, 0.25, 0.25),
	UnitRole.Kind.CAVALRY: Color(0.9, 0.55, 0.15),
	UnitRole.Kind.ARCHERS: Color(0.7, 0.3, 0.8),
	UnitRole.Kind.NONE: Color(0.25, 0.1, 0.1),
}

var battle: Battle

var _enemies: MultiMeshInstance3D
var _walls: Array[MeshInstance3D] = []
var _wall_materials: Array[StandardMaterial3D] = []
var _troop_meshes: Array[MultiMeshInstance3D] = []
var _troop_labels: Array[Label3D] = []
var _tower_boxes: Array = [[], [], []]
var _town_center: MeshInstance3D

func _ready() -> void:
	_build_world()
	refresh()

func _process(_delta: float) -> void:
	refresh()

## Number of enemy instances currently drawn (capped at MAX_ENEMIES).
func visible_enemy_count() -> int:
	return _enemies.multimesh.visible_instance_count

func wall_color(section: int) -> Color:
	return _wall_materials[section].albedo_color

func troop_model_count(section: int) -> int:
	return _troop_meshes[section].multimesh.visible_instance_count

func troop_label(section: int) -> String:
	return _troop_labels[section].text

func tower_visible(section: int, slot: int) -> bool:
	return _tower_boxes[section][slot].visible

func refresh() -> void:
	if battle == null:
		return
	_refresh_enemies()
	_refresh_walls()
	_refresh_troops()
	_refresh_towers()

# --- building ---------------------------------------------------------------

func _build_world() -> void:
	var cam := Camera3D.new()
	# Portrait is narrow, so the field of view is fixed to the width: all three lanes and both
	# flank edges stay on screen, with the spawn edge at the top and the Town Center at the bottom.
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 50.0
	cam.position = Vector3(0, 28, 5)
	cam.rotation_degrees = Vector3(-65, 0, 0)
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 70)
	ground.mesh = plane
	ground.position = Vector3(0, 0, -14)
	ground.material_override = _flat(Color(0.35, 0.5, 0.3))
	add_child(ground)
	_town_center = _box(Vector3(5, 3, 3), Color(0.25, 0.4, 0.8), Vector3(0, 1.5, 6.5))
	for s in 3:
		var wall := _box(Vector3(5.2, 2.4, 1.0), Color.WHITE, Vector3(LANE_X[s], 1.2, 0))
		_walls.append(wall)
		_wall_materials.append(wall.material_override)
		_troop_meshes.append(_troop_multimesh(s))
		var label := Label3D.new()
		label.position = Vector3(LANE_X[s], 3.6, 1.5)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.012
		label.font_size = 48
		label.outline_size = 12
		add_child(label)
		_troop_labels.append(label)
		for slot in 2:
			var tower := _box(Vector3(0.9, 1.4, 0.9), Color(0.9, 0.85, 0.3), Vector3(LANE_X[s] - 1.5 + slot * 3.0, 3.0, 0))
			tower.visible = false
			_tower_boxes[s].append(tower)
	_enemies = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var body := BoxMesh.new()
	body.size = Vector3(0.8, 1.2, 0.8)
	mm.mesh = body
	mm.instance_count = MAX_ENEMIES
	mm.visible_instance_count = 0
	_enemies.multimesh = mm
	_enemies.material_override = _flat(Color.WHITE, true)
	add_child(_enemies)

func _troop_multimesh(section: int) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var body := CapsuleMesh.new()
	body.radius = 0.35
	body.height = 1.2
	mm.mesh = body
	mm.instance_count = MAX_TROOP_MODELS
	mm.visible_instance_count = 0
	node.multimesh = mm
	node.material_override = _flat(Color.WHITE, true)
	add_child(node)
	return node

func _box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _flat(color)
	node.position = pos
	add_child(node)
	return node

func _flat(color: Color, vertex_colors: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.vertex_color_use_as_albedo = vertex_colors
	return m

# --- per-frame updates --------------------------------------------------------

func _refresh_enemies() -> void:
	var h := battle.horde
	var n := mini(h.count(), MAX_ENEMIES)
	var mm := _enemies.multimesh
	for i in n:
		var e := h.types[i]
		# Spread each lane's enemies sideways so a horde reads as a mass, not a queue.
		var x: float = LANE_X[h.lane[i]] + (fposmod(i * 0.618034, 1.0) - 0.5) * 4.0
		if h.from_side[i] == 1:
			x += 8.0 * (h.dist[i] / battle.tuning.lane_length) * (-1.0 if h.lane[i] == 0 else 1.0)
		var basis := Basis().scaled(Vector3.ONE * e.model_scale)
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, 0.6 * e.model_scale, -h.dist[i])))
		mm.set_instance_color(i, ROLE_COLORS[e.role])
	mm.visible_instance_count = n

func _refresh_walls() -> void:
	for s in 3:
		_wall_materials[s].albedo_color = WALL_COLORS[battle.state.crack_stage(s)]

func _refresh_troops() -> void:
	var pool := battle.state.pool
	for s in 3:
		var total := pool.section_total(s)
		var models := mini(ceili(float(total) / TROOPS_PER_MODEL), MAX_TROOP_MODELS)
		var mm := _troop_meshes[s].multimesh
		for i in models:
			var kind := _kind_for_model(s, i, models)
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(LANE_X[s] - 2.0 + (i % 6) * 0.8, 0.6, 1.8 + (i / 6) * 1.0)))
			mm.set_instance_color(i, battle.state.troop_defs[kind].color)
		mm.visible_instance_count = models
		_troop_labels[s].text = "I %d  C %d  A %d" % [pool.count(s, UnitRole.Kind.INFANTRY), pool.count(s, UnitRole.Kind.CAVALRY), pool.count(s, UnitRole.Kind.ARCHERS)]

## Model i of n in a section stands in for whichever kind owns that share of the section's troops.
func _kind_for_model(section: int, i: int, n: int) -> int:
	var total := battle.state.pool.section_total(section)
	if total <= 0:
		return UnitRole.Kind.INFANTRY
	var at := (float(i) + 0.5) / float(n) * total
	var running := 0.0
	for k in UnitRole.TROOP_KINDS:
		running += battle.state.pool.count(section, k)
		if at <= running:
			return k
	return UnitRole.Kind.ARCHERS

func _refresh_towers() -> void:
	for s in 3:
		for slot in 2:
			_tower_boxes[s][slot].visible = battle.state.towers[s][slot] != null
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_view
```

Expected: `RESULT: 18 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the 3D grey-box battle view" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Battle HUD

Wave counter, a phase bar with the milestone waves marked, troop counts, wall and Town Center bars, the hero skill button and one Sortie button per section.

**Files:**
- Create: `scripts/battle_hud.gd`
- Test: `tests/test_battle_hud.gd`

**Interfaces:**
- Consumes: `Battle` (Task 10), `BattleFactory`, `PhaseMachine`
- Produces: `BattleHud` (`CanvasLayer`) with `battle: Battle`; `wave_text()`, `phase_text()`, `hero_text()`, `active_phase_index()`, `refresh()`, `press_hero() -> bool` (aims the skill at the busiest lane), `press_sortie(section) -> bool`

- [ ] **Step 1: Write the failing test**

`tests/test_battle_hud.gd`:

```gdscript
extends RefCounted

var t

func _hud(b: Battle) -> BattleHud:
	var h := BattleHud.new()
	h.battle = b
	t.root.add_child(h)
	return h

func test_texts_during_the_opening_regroup() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var h := _hud(b)
	t.eq(h.wave_text(), "Wave 1/20", "wave counter shows the upcoming wave")
	t.eq(h.phase_text(), "Regroup", "regroup label")
	t.eq(h.active_phase_index(), 0, "phase 1 highlighted")
	h.queue_free()

func test_texts_during_an_assault() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	var h := _hud(b)
	t.eq(h.phase_text(), "Phase 1/4", "phase label")
	b.debug_jump_to_wave(17)
	t.eq(h.wave_text(), "Wave 17/20", "wave counter")
	t.eq(h.phase_text(), "Phase 4/4", "phase 4")
	t.eq(h.active_phase_index(), 3, "fourth panel highlighted")
	h.queue_free()

func test_hero_button_is_off_in_a_regroup_and_on_in_an_assault() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var h := _hud(b)
	h.refresh()
	t.check(h._hero_button.disabled, "disabled during the regroup")
	b.ready()
	h.refresh()
	t.check(not h._hero_button.disabled, "enabled in an assault")
	t.eq(h.hero_text(), "Shield Bash", "shows the skill name")
	h.queue_free()

func test_pressing_the_hero_button_needs_enemies_then_starts_the_cooldown() -> void:
	var b := BattleFactory.create(0, null, "knight_captain")
	b.start()
	b.ready()
	var h := _hud(b)
	t.check(not h.press_hero(), "no enemies yet: nothing to aim at")
	b.tick(2.0)
	t.check(h.press_hero(), "skill fires at the busiest lane")
	h.refresh()
	t.check(h._hero_button.disabled, "on cooldown")
	t.check(h.hero_text().begins_with("Shield Bash "), "cooldown seconds shown")
	h.queue_free()

func test_no_hero_means_a_disabled_button() -> void:
	var b := BattleFactory.create(100, null, "")
	b.start()
	b.ready()
	var h := _hud(b)
	h.refresh()
	t.eq(h.hero_text(), "No hero", "label")
	t.check(h._hero_button.disabled, "disabled")
	h.queue_free()

func test_sortie_buttons_need_cavalry_in_their_section() -> void:
	var f := Formation.new()
	f.shares = [[1.0, 1.0, 1.0], [1.0, 0.0, 1.0], [1.0, 1.0, 1.0]]
	var b := BattleFactory.create(600, f)
	b.start()
	b.ready()
	var h := _hud(b)
	h.refresh()
	t.check(not h._sortie_buttons[0].disabled, "section 0 has cavalry")
	t.check(h._sortie_buttons[1].disabled, "section 1 has none")
	t.check(h.press_sortie(0), "sortie sent")
	h.refresh()
	t.eq(h._sortie_buttons[0].text, "Charging!", "shows the charge")
	t.check(h._sortie_buttons[2].disabled, "shared cooldown disables the others")
	h.queue_free()

func test_bars_and_troop_labels_follow_the_state() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var h := _hud(b)
	h.refresh()
	t.eq(h._troop_labels[0].text, "Left  200", "troops per section")
	b.state.damage_town_center(2500.0)
	b.state.damage_wall(2, 1000.0)
	h.refresh()
	t.eq(h._tc_bar.value, 2500.0, "Town Center bar")
	t.eq(h._tc_bar.max_value, 5000.0, "Town Center max")
	t.eq(h._wall_bars[2].value, b.state.wall_hp[2], "right wall bar")
	h.queue_free()

func test_horde_counter() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	var h := _hud(b)
	b.tick(2.0)
	h.refresh()
	t.eq(h._horde_label.text, "Horde: %d" % b.horde.count(), "live enemy count")
	h.queue_free()
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_hud
```

Expected: `could not load` (identifier `BattleHud` not found).

- [ ] **Step 3: Implement**

`scripts/battle_hud.gd`:

```gdscript
class_name BattleHud
extends CanvasLayer
## Battle HUD (design spec section 11): wave counter, a phase bar with the milestone waves marked,
## troop counts, Town Center HP, the hero skill button and one cavalry sortie button per section.
## Reads the Battle every frame; the buttons call Battle.use_* and nothing else.

const SECTION_NAMES := ["Left", "Center", "Right"]
const PHASE_COLORS := [Color(0.35, 0.55, 0.35), Color(0.55, 0.5, 0.3), Color(0.6, 0.4, 0.3), Color(0.6, 0.25, 0.25)]

var battle: Battle

var _wave_label: Label
var _horde_label: Label
var _phase_panels: Array[PanelContainer] = []
var _tc_bar: ProgressBar
var _hero_button: Button
var _sortie_buttons: Array[Button] = []
var _wall_bars: Array[ProgressBar] = []
var _troop_labels: Array[Label] = []

func _ready() -> void:
	layer = 10
	_build()
	refresh()

func _process(_delta: float) -> void:
	refresh()

func wave_text() -> String:
	var p := battle.phase
	return "Wave %d/%d" % [maxi(p.wave, 1), battle.tuning.waves_per_battle]

## "Phase 2/4" while fighting; "Regroup" between phases.
func phase_text() -> String:
	if battle.phase.state == PhaseMachine.State.REGROUP:
		return "Regroup"
	return "Phase %d/4" % battle.phase.current_phase()

func hero_text() -> String:
	var st := battle.state
	if st.hero == null:
		return "No hero"
	if st.hero_cooldown > 0.0:
		return "%s %.0f" % [st.hero.skill_name, ceilf(st.hero_cooldown)]
	return st.hero.skill_name

## Index (0-3) of the phase panel highlighted right now.
func active_phase_index() -> int:
	return battle.phase.current_phase() - 1

func refresh() -> void:
	if battle == null:
		return
	var st := battle.state
	_wave_label.text = "%s   %s" % [wave_text(), phase_text()]
	_horde_label.text = "Horde: %d" % battle.horde.count()
	for i in _phase_panels.size():
		_phase_panels[i].modulate = Color.WHITE if i == active_phase_index() else Color(1, 1, 1, 0.45)
	_tc_bar.max_value = st.town_center_max
	_tc_bar.value = st.town_center_hp
	var assault := battle.phase.state == PhaseMachine.State.ASSAULT
	_hero_button.text = hero_text()
	_hero_button.disabled = not assault or st.hero == null or st.hero_cooldown > 0.0
	for s in 3:
		_wall_bars[s].max_value = st.wall_max[s]
		_wall_bars[s].value = st.wall_hp[s]
		_troop_labels[s].text = "%s  %d" % [SECTION_NAMES[s], st.pool.section_total(s)]
		_sortie_buttons[s].disabled = not assault or st.sortie_cooldown > 0.0 or st.pool.count(s, UnitRole.Kind.CAVALRY) <= 0
		_sortie_buttons[s].text = "Sortie" if st.sortie_left[s] <= 0.0 else "Charging!"

func press_hero() -> bool:
	var lane := battle.horde.busiest_lane()
	return lane >= 0 and battle.use_hero_skill(lane)

func press_sortie(section: int) -> bool:
	return battle.use_sortie(section)

# --- building ---------------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	_wave_label = _label(54)
	top.add_child(_wave_label)
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar)
	for i in 4:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = PHASE_COLORS[i]
		panel.add_theme_stylebox_override("panel", style)
		var mark := _label(28)
		mark.text = "%d: %s" % [(i + 1) * 5, ["Flank", "Keep strike", "Siege", "Boss"][i]]
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(mark)
		bar.add_child(panel)
		_phase_panels.append(panel)
	_horde_label = _label(40)
	top.add_child(_horde_label)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	_hero_button = _button("Hero", press_hero, 56)
	bottom.add_child(_hero_button)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(row)
	for s in 3:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var troops := _label(36)
		col.add_child(troops)
		_troop_labels.append(troops)
		var wall := ProgressBar.new()
		wall.custom_minimum_size = Vector2(0, 28)
		wall.show_percentage = false
		col.add_child(wall)
		_wall_bars.append(wall)
		var sortie := _button("Sortie", press_sortie.bind(s), 40)
		col.add_child(sortie)
		_sortie_buttons.append(sortie)
		row.add_child(col)
	_tc_bar = ProgressBar.new()
	_tc_bar.custom_minimum_size = Vector2(0, 40)
	_tc_bar.show_percentage = false
	bottom.add_child(_tc_bar)

func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _button(text: String, cb: Callable, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(0, 100)
	b.pressed.connect(cb)
	return b
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_hud
```

Expected: `RESULT: 26 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the battle HUD" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Regroup screen

The main decision UI: troop ratio, where each kind stands, six tower slots, the scout report and Ready. Plain Controls; art comes later.

**Files:**
- Create: `scripts/regroup_screen.gd`
- Test: `tests/test_regroup_screen.gd`

**Interfaces:**
- Consumes: `Battle` (Task 10: `preview_next_phase`, `apply_formation`, `set_tower`, `ready`), `Formation` (Task 4), `TowerData` resources
- Produces: `RegroupScreen` (`CanvasLayer`) with `battle: Battle`, `tower_options` (index 0 = no tower, then arrow, crossbow, cannon); signal `ready_pressed`; `open()`, `close()`, `build_formation() -> Formation`, `set_ratio(kind, value)`, `set_share(section, kind, value)`, `set_tower_choice(section, slot, option_index)`, `recommend()`, `press_ready()`, `preview_text(p: Dictionary) -> String`. The first `open()` loads `Formation.recommended` into the sliders; later opens keep the player's values.

- [ ] **Step 1: Write the failing test**

`tests/test_regroup_screen.gd`:

```gdscript
extends RefCounted

var t
var _pressed: int = 0

func _screen(b: Battle) -> RegroupScreen:
	var r := RegroupScreen.new()
	r.battle = b
	t.root.add_child(r)
	return r

func test_opening_shows_the_title_and_the_scout_report() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	t.check(r.visible, "visible")
	t.eq(r._title.text, "Regroup - Phase 1", "title")
	t.check(r._preview.text.contains("Raider"), "lists raiders")
	t.check(r._preview.text.contains("Wave 5: Flank (from the left)"), "names the milestone and its side")
	r.queue_free()

func test_preview_for_phase_two_names_the_keep_strike() -> void:
	var b := BattleFactory.create(1500)
	b.start()
	b.ready()
	for _i in 20000:
		if b.in_regroup():
			break
		b.tick(0.1)
	var r := _screen(b)
	r.open()
	t.eq(r._title.text, "Regroup - Phase 2", "title")
	t.check(r._preview.text.contains("Wave 10: Keep strike"), "keep strike listed")
	t.check(r._preview.text.contains("Ram"), "rams listed")
	r.queue_free()

func test_first_open_applies_the_recommended_formation() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	var f := r.build_formation()
	t.check(f.ratio[UnitRole.Kind.ARCHERS] > 3.0, "phase 1 is all infantry-type raiders, so archers are favoured")
	r.queue_free()

func test_reopening_keeps_the_players_choices() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	r.set_ratio(UnitRole.Kind.CAVALRY, 9.0)
	r.close()
	r.open()
	t.eq(r.build_formation().ratio[UnitRole.Kind.CAVALRY], 9.0, "slider kept its value")
	r.recommend()
	t.check(r.build_formation().ratio[UnitRole.Kind.CAVALRY] != 9.0, "the Recommended button resets it")
	r.queue_free()

func test_build_formation_reads_every_slider() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	r.set_ratio(0, 4.0)
	r.set_ratio(1, 1.0)
	r.set_ratio(2, 5.0)
	r.set_share(0, 2, 4.0)
	r.set_share(1, 2, 0.0)
	var f := r.build_formation()
	t.eq(f.ratio, [4.0, 1.0, 5.0] as Array[float], "ratio")
	t.eq(f.shares[2][0], 4.0, "archers' share of the left section")
	t.eq(f.shares[2][1], 0.0, "archers' share of the center section")
	r.queue_free()

func test_ready_applies_the_formation_and_towers_and_starts_the_wave() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	_pressed = 0
	r.ready_pressed.connect(func(): _pressed += 1)
	r.open()
	r.set_ratio(0, 10.0)
	r.set_ratio(1, 0.0)
	r.set_ratio(2, 0.0)
	r.set_share(0, 0, 0.0)
	r.set_share(1, 0, 0.0)
	r.set_share(2, 0, 4.0)
	r.set_tower_choice(1, 0, 3)
	r.press_ready()
	t.eq(b.state.pool.count(2, UnitRole.Kind.INFANTRY), 600, "all infantry on the right")
	t.eq(b.state.pool.total(), 600, "troops conserved")
	t.eq(b.state.towers[1][0].id, &"cannon_tower", "cannon in section 1 slot 0")
	t.eq(b.state.towers[1][1], null, "other slot empty")
	t.eq(b.phase.state, PhaseMachine.State.ASSAULT, "wave 1 under way")
	t.eq(_pressed, 1, "signal emitted once")
	r.queue_free()

func test_ready_outside_a_regroup_changes_nothing() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	var before := b.state.pool.counts.duplicate(true)
	var r := _screen(b)
	r.open()
	r.set_ratio(0, 10.0)
	r.set_ratio(2, 0.0)
	r.press_ready()
	t.eq(b.state.pool.counts, before, "formation refused during an assault")
	t.eq(b.phase.wave, 1, "still wave 1")
	r.queue_free()

func test_zero_sliders_everywhere_still_deal_every_troop() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	for k in 3:
		r.set_ratio(k, 0.0)
		for s in 3:
			r.set_share(s, k, 0.0)
	r.press_ready()
	t.eq(b.state.pool.total(), 600, "no troops lost to a bad formation")

func test_the_summary_shows_the_resulting_counts() -> void:
	var b := BattleFactory.create(300)
	b.start()
	var r := _screen(b)
	r.open()
	r.set_ratio(0, 5.0)
	r.set_ratio(1, 2.0)
	r.set_ratio(2, 3.0)
	r._process(0.0)
	t.check(r._summary.text.contains("Left: I 50 C 20 A 30"), "even 50/20/30 over 300 troops")
	r.queue_free()
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_regroup_screen
```

Expected: `could not load` (identifier `RegroupScreen` not found).

- [ ] **Step 3: Implement**

`scripts/regroup_screen.gd`:

```gdscript
class_name RegroupScreen
extends CanvasLayer
## The pre-set-formation screen (design spec sections 3, 4 and 7). Shown at the start of a battle
## and after each milestone wave: troop ratio, how each kind is shared across the wall sections,
## the six tower slots, a scout preview of the next phase and a Ready button.
## Plain Controls only; art comes later.

signal ready_pressed

const SECTION_NAMES := ["Left", "Center", "Right"]
const KIND_NAMES := ["Infantry", "Cavalry", "Archers"]
const MILESTONE_NAMES := {
	WaveData.Milestone.FLANK: "Flank",
	WaveData.Milestone.KEEP_STRIKE: "Keep strike",
	WaveData.Milestone.SIEGE: "Siege",
	WaveData.Milestone.BOSS: "Boss",
}

var battle: Battle
## Tower choices: index 0 is "no tower".
var tower_options: Array = [null]

var _root: Control
var _title: Label
var _countdown: Label
var _preview: Label
var _summary: Label
var _ratio_sliders: Array[HSlider] = []
## _share_sliders[section][kind]
var _share_sliders: Array = [[], [], []]
## _tower_pickers[section][slot]
var _tower_pickers: Array = [[], [], []]
var _first_open := true

func _ready() -> void:
	layer = 20
	for id in ["arrow_tower", "crossbow_tower", "cannon_tower"]:
		tower_options.append(load("res://resources/towers/%s.tres" % id))
	_build()
	visible = false

func _process(_delta: float) -> void:
	if visible and battle != null:
		_countdown.text = "Starting in %d s" % ceili(battle.phase.timer)
		_summary.text = _summary_text()

func open() -> void:
	var p := battle.preview_next_phase()
	if _first_open:
		_first_open = false
		_load_sliders(Formation.recommended(p.roles))
	_title.text = "Regroup - Phase %d" % p.phase
	_preview.text = preview_text(p)
	visible = true

func close() -> void:
	visible = false

## The formation the sliders currently describe.
func build_formation() -> Formation:
	var f := Formation.new()
	for k in 3:
		f.ratio[k] = _ratio_sliders[k].value
		for s in 3:
			f.shares[k][s] = _share_sliders[s][k].value
	return f

func set_ratio(kind: int, value: float) -> void:
	_ratio_sliders[kind].value = value

func set_share(section: int, kind: int, value: float) -> void:
	_share_sliders[section][kind].value = value

func set_tower_choice(section: int, slot: int, option_index: int) -> void:
	_tower_pickers[section][slot].select(option_index)

func recommend() -> void:
	_load_sliders(Formation.recommended(battle.preview_next_phase().roles))

## Applies the formation and towers to the battle and starts the next wave.
func press_ready() -> void:
	battle.apply_formation(build_formation())
	for s in 3:
		for slot in 2:
			battle.set_tower(s, slot, tower_options[_tower_pickers[s][slot].selected])
	battle.ready()
	ready_pressed.emit()

func preview_text(p: Dictionary) -> String:
	var lines: Array[String] = ["Scouts report (phase %d):" % p.phase]
	var mix: Array[String] = []
	for id in p.mix:
		mix.append("%s x%d" % [String(id).capitalize(), p.mix[id]])
	lines.append(", ".join(mix) if not mix.is_empty() else "Nothing")
	for w in p.waves:
		if w.milestone != WaveData.Milestone.NONE:
			var extra := " (from the %s)" % SECTION_NAMES[w.flank_lane].to_lower() if w.milestone == WaveData.Milestone.FLANK else ""
			lines.append("Wave %d: %s%s" % [w.wave, MILESTONE_NAMES[w.milestone], extra])
	return "\n".join(lines)

# --- internals ----------------------------------------------------------------

func _summary_text() -> String:
	var counts := build_formation().counts(battle.state.pool.total())
	var parts: Array[String] = []
	for s in 3:
		parts.append("%s: I %d C %d A %d" % [SECTION_NAMES[s], counts[s][0], counts[s][1], counts[s][2]])
	return "\n".join(parts)

func _load_sliders(f: Formation) -> void:
	for k in 3:
		_ratio_sliders[k].value = snappedf(f.ratio[k] * 10.0, 0.5)
		for s in 3:
			_share_sliders[s][k].value = f.shares[k][s]

func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	_root.add_theme_stylebox_override("panel", bg)
	add_child(_root)
	var box := VBoxContainer.new()
	_root.add_child(box)
	_title = _label("Regroup", 56)
	box.add_child(_title)
	_countdown = _label("", 40)
	box.add_child(_countdown)
	_preview = _label("", 34)
	box.add_child(_preview)
	box.add_child(_label("Troop ratio", 40))
	for k in 3:
		_ratio_sliders.append(_slider_row(box, KIND_NAMES[k], 5.0 if k == 0 else (2.0 if k == 1 else 3.0), 10.0, 0.5))
	box.add_child(_label("Where each kind stands", 40))
	for s in 3:
		var row := HBoxContainer.new()
		box.add_child(row)
		row.add_child(_label(SECTION_NAMES[s], 34))
		for k in 3:
			var slider := _make_slider(1.0, 4.0, 1.0)
			slider.custom_minimum_size = Vector2(200, 60)
			row.add_child(slider)
			_share_sliders[s].append(slider)
		var towers := HBoxContainer.new()
		for slot in 2:
			var picker := OptionButton.new()
			picker.add_theme_font_size_override("font_size", 30)
			for opt in ["No tower", "Arrow", "Crossbow", "Cannon"]:
				picker.add_item(opt)
			towers.add_child(picker)
			_tower_pickers[s].append(picker)
		row.add_child(towers)
	_summary = _label("", 32)
	box.add_child(_summary)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var rec := Button.new()
	rec.text = "Recommended"
	rec.add_theme_font_size_override("font_size", 44)
	rec.custom_minimum_size = Vector2(0, 110)
	rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rec.pressed.connect(recommend)
	buttons.add_child(rec)
	var go := Button.new()
	go.text = "Ready"
	go.add_theme_font_size_override("font_size", 56)
	go.custom_minimum_size = Vector2(0, 110)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(press_ready)
	buttons.add_child(go)

func _slider_row(parent: Control, text: String, value: float, max_value: float, step: float) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := _label(text, 36)
	name_label.custom_minimum_size = Vector2(240, 0)
	row.add_child(name_label)
	var slider := _make_slider(value, max_value, step)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return slider

func _make_slider(value: float, max_value: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = max_value
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 60)
	return s

func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_regroup_screen
```

Expected: `RESULT: 23 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add -A scripts tests
git commit -m "Add the regroup screen" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Battle scene, entry wiring, README and a visual check

Assembles the battle screen, forwards battle signals to `EventBus`, pays rewards, and makes `Main` open the battle.

**Files:**
- Create: `scripts/battle_scene.gd`, `scenes/Battle.tscn`, `tools/screenshot.gd`
- Modify: `scripts/main.gd`, `README.md`
- Test: `tests/test_battle_scene.gd`

**Interfaces:**
- Consumes: Tasks 10-13; `EventBus`, `GameState`, `SceneSwapper`, `DebugPanel` autoloads
- Produces: `res://scenes/Battle.tscn` whose script exposes `battle`, `view`, `hud`, `regroup`, `result_panel`, `result_label`, `reward_gold`, `play_again()`. The scene starts the battle, ticks it every frame, forwards every battle and phase signal to `EventBus`, connects `EventBus.debug_spawn_wave` and `debug_skip_phase` to the battle (and disconnects them on exit), opens the regroup screen on `regroup_started`, closes it on `wave_started`, and on `battle_ended` calls `GameState.record_battle` and shows the result.

- [ ] **Step 1: Write the failing test**

`tests/test_battle_scene.gd`:

```gdscript
extends RefCounted

var t
var _waves: Array = []
var _ended: Array = []

func _scene() -> Node:
	var s := (load("res://scenes/Battle.tscn") as PackedScene).instantiate()
	t.root.add_child(s)
	return s

func test_scene_opens_on_the_regroup_screen() -> void:
	var s := _scene()
	await t.process_frame
	t.check(s.regroup.visible, "regroup screen is up")
	t.check(s.battle.in_regroup(), "battle waits for Ready")
	t.eq(s.battle.state.pool.total(), 600, "default march capacity")
	s.queue_free()
	await t.process_frame

func test_ready_hides_the_regroup_screen_and_forwards_wave_start_to_event_bus() -> void:
	_waves.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(w): _waves.append(w)
	bus.wave_started.connect(cb)
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	bus.wave_started.disconnect(cb)
	t.eq(_waves, [1], "EventBus heard wave 1")
	t.check(not s.regroup.visible, "regroup closed")
	s.queue_free()
	await t.process_frame

func test_the_scene_ticks_the_battle_each_frame() -> void:
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	for _i in 40:
		await t.process_frame
	t.check(s.battle.horde.count() > 0 or s.battle.kills > 0, "enemies spawned and fought")
	s.queue_free()
	await t.process_frame

func test_debug_panel_requests_reach_the_active_battle() -> void:
	var s := _scene()
	await t.process_frame
	t.root.get_node("DebugPanel").spawn_wave(12)
	t.eq(s.battle.phase.wave, 12, "jumped to wave 12")
	t.root.get_node("DebugPanel").skip_phase()
	t.eq(s.battle.phase.wave, 16, "skipped to phase 4")
	s.queue_free()
	await t.process_frame
	t.root.get_node("DebugPanel").spawn_wave(3)

func test_defeat_shows_the_result_and_pays_gold_for_the_waves_reached() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	_ended.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(v): _ended.append(v)
	bus.battle_ended.connect(cb)
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	s.battle.debug_jump_to_wave(7)
	s.battle.state.damage_town_center(1.0e9)
	s.battle.tick(0.1)
	bus.battle_ended.disconnect(cb)
	t.eq(_ended, [false], "EventBus heard the defeat")
	t.check(s.result_panel.visible, "result panel shown")
	t.check(s.result_label.text.begins_with("DEFEAT"), "says defeat")
	t.eq(gs.gold, 70, "7 waves x 10 gold")
	t.eq(s.reward_gold, 70, "reward recorded on the scene")
	s.queue_free()
	await t.process_frame
	gs.reset()

func test_victory_pays_the_bonus() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	s.battle.phase.jump_to_wave(20)
	s.battle.phase.tick(0.1, true)
	t.check(s.result_label.text.begins_with("VICTORY"), "says victory")
	t.eq(gs.gold, 300, "20 waves x 10 + 100")
	s.queue_free()
	await t.process_frame
	gs.reset()

func test_leaving_the_scene_disconnects_the_debug_hooks() -> void:
	var bus = t.root.get_node("EventBus")
	var before: int = bus.debug_spawn_wave.get_connections().size()
	var s := _scene()
	await t.process_frame
	t.eq(bus.debug_spawn_wave.get_connections().size(), before + 1, "scene connected")
	s.queue_free()
	await t.process_frame
	t.eq(bus.debug_spawn_wave.get_connections().size(), before, "and disconnected on exit")
```

- [ ] **Step 2: Run it to verify it fails**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_scene
```

Expected: failures: `res://scenes/Battle.tscn` does not exist, so `load()` returns null and the first test errors.

- [ ] **Step 3: Implement**

`scripts/battle_scene.gd` (a scene script, so it may name autoloads):

```gdscript
extends Node
## The battle screen: builds the Battle, the 3D view, the HUD and the regroup screen, ticks the
## battle every frame, forwards its signals to EventBus and shows the result. This is the only
## battle script that names autoloads (class scripts cannot, see Battle).

var battle: Battle
var view: BattleView
var hud: BattleHud
var regroup: RegroupScreen
var result_label: Label
var result_panel: PanelContainer
var reward_gold: int = 0

func _ready() -> void:
	battle = BattleFactory.create(GameState.march_capacity)
	view = BattleView.new()
	view.battle = battle
	add_child(view)
	hud = BattleHud.new()
	hud.battle = battle
	add_child(hud)
	regroup = RegroupScreen.new()
	regroup.battle = battle
	add_child(regroup)
	_build_result_panel()
	_forward_signals()
	battle.phase.regroup_started.connect(func(_p): regroup.open())
	battle.phase.wave_started.connect(func(_w): regroup.close())
	battle.phase.battle_ended.connect(_on_battle_ended)
	EventBus.debug_spawn_wave.connect(battle.debug_jump_to_wave)
	EventBus.debug_skip_phase.connect(battle.debug_skip_phase)
	battle.start()

func _process(delta: float) -> void:
	battle.tick(delta)

func _exit_tree() -> void:
	EventBus.debug_spawn_wave.disconnect(battle.debug_jump_to_wave)
	EventBus.debug_skip_phase.disconnect(battle.debug_skip_phase)

func _forward_signals() -> void:
	battle.enemy_killed.connect(EventBus.enemy_killed.emit)
	battle.wall_damaged.connect(EventBus.wall_damaged.emit)
	battle.phase.wave_started.connect(EventBus.wave_started.emit)
	battle.phase.wave_cleared.connect(EventBus.wave_cleared.emit)
	battle.phase.phase_cleared.connect(EventBus.phase_cleared.emit)
	battle.phase.regroup_started.connect(EventBus.regroup_started.emit)
	battle.phase.battle_ended.connect(EventBus.battle_ended.emit)

func _on_battle_ended(victory: bool) -> void:
	var before := GameState.gold
	GameState.record_battle(victory, battle.phase.highest_wave)
	reward_gold = GameState.gold - before
	result_label.text = "%s\nReached wave %d\n+%d gold" % ["VICTORY" if victory else "DEFEAT", battle.phase.highest_wave, reward_gold]
	result_panel.visible = true

func play_again() -> void:
	SceneSwapper.swap_to("res://scenes/Battle.tscn")

func _build_result_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.visible = false
	layer.add_child(result_panel)
	var box := VBoxContainer.new()
	result_panel.add_child(box)
	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 64)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	var again := Button.new()
	again.text = "Defend again"
	again.add_theme_font_size_override("font_size", 56)
	again.custom_minimum_size = Vector2(500, 120)
	again.pressed.connect(play_again)
	box.add_child(again)
```

`scenes/Battle.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle_scene.gd" id="1"]

[node name="Battle" type="Node"]
script = ExtResource("1")
```

Replace `scripts/main.gd`:

```gdscript
extends Node
## Entry scene: hands over to the battle screen.

func _ready() -> void:
	SceneSwapper.swap_to("res://scenes/Battle.tscn", 0.0)
```

`tools/screenshot.gd` (needs a window, so it cannot run with `--headless`):

```gdscript
extends SceneTree
## Saves two screenshots of the battle screen: godot --path . -s res://tools/screenshot.gd -- <out_dir>
## (needs a window, so it cannot run with --headless).

func _initialize() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "."
	var scene := (load("res://scenes/Battle.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	_save(out + "/regroup.png")
	scene.regroup.set_tower_choice(0, 0, 1)
	scene.regroup.set_tower_choice(2, 1, 3)
	scene.regroup.press_ready()
	scene.battle.debug_jump_to_wave(12)
	await create_timer(4.0).timeout
	_save(out + "/wave12.png")
	quit()

func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
```

Replace `README.md`:

```markdown
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

Debug panel (debug builds): F1 or a 3-finger tap. It jumps to wave N, skips to the next phase, sets the stage, adds gold and toggles 4x speed.

## Test

```
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/run_tests.gd -- test_formation
```

The second form runs one suite. Run `godot --headless --path . --import` once after adding a new `class_name` script or asset.

## Balance

Every number is in `resources/tuning/default.tres` and the enemy, troop, tower and hero `.tres` files. To see how a setup plays out without opening the game:

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
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd -- test_battle_scene
```

Expected: `RESULT: 17 passed, 0 failed`.

- [ ] **Step 5: Run the whole suite**

```bash
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd
```

Expected: `RESULT: 1846 passed, 0 failed` (about 10-15 seconds).

- [ ] **Step 6: Look at it**

Tests cannot tell you the camera frames the field, so render it:

```bash
mkdir -p build
godot --path . -s res://tools/screenshot.gd -- build
```

Open `build/regroup.png` and `build/wave12.png`. Expect: in `wave12.png` all three lanes with enemies coloured by role, the three wall sections, a troop label under each, the Town Center at the bottom, the phase bar at the top with phase 3 highlighted; in `regroup.png` a dark panel with sliders, six tower pickers, a scout report mentioning raiders and "Wave 5: Flank (from the left)", and Recommended / Ready buttons. Then press F5 in the editor and play one battle by hand.

- [ ] **Step 7: Commit**

```bash
git add -A scripts scenes tests tools README.md
git commit -m "Add the battle scene, wire Main to it, rewrite the README" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 15: The Fun Gate

The spec's rule: build the battle with grey boxes and move on only when a battle is fun to replay without any progression attached. This task is a structured playtest and tuning pass, and its output is a decision, not code.

**Files:**
- Create: `docs/superpowers/notes/fun-gate.md`
- Modify: `resources/tuning/default.tres` and the enemy, troop, tower, hero `.tres` files as the playtest demands; `docs/superpowers/specs/2026-10-07-kingshot-horde-phases-design.md` (tick the prototype checklist)

**Interfaces:**
- Consumes: the whole of Tasks 1-14
- Produces: a written Fun Gate result and, if it passes, the go-ahead to plan M4 (horde performance) and M5 (vertical slice).

- [ ] **Step 1: Run the balance probe and record it**

```bash
godot --headless --path . -s res://tools/sim_battle.gd
```

Paste the table into `docs/superpowers/notes/fun-gate.md` under a "Simulated balance" heading with today's date.

- [ ] **Step 2: Check the simulated criteria**

All must hold; if one does not, tune the resource files (not code) and re-run the probe:

- An undefended town loses in the first three waves.
- The default 600 troops, with no towers and the default formation, lose or barely win. 1000 troops win with the Town Center hurt. 2500 troops win without trouble.
- Towers matter: at least one tower type turns the 600-troop loss into a win.
- Formation matters: an army with no cavalry and no hero cannot get past wave 15 (the siege).
- A battle takes 4-6 minutes of simulated time.

Known tuning note: with the starting numbers troops rarely die (they heal 60% of losses and most enemies die before reaching the wall), so the troop-loss tension the spec wants in phase 4 is weak. Raising Rider and Bowman damage against troops, or lowering troop HP, is the first lever to try. Do not change the milestone structure.

- [ ] **Step 3: Playtest by hand**

Play at least five battles in the editor (F5), at 1x speed, varying the formation and towers. After each, note in `fun-gate.md` one line: what you chose, how it went, what felt dull or unfair. Check each of these observations is true and write yes or no:

- Wave 5 is visibly different (enemies come in from the left side).
- Wave 10 rams walk straight past the wall and threaten the Town Center.
- Wave 15 siege units sit far back and cannot be hurt without a sortie or the hero skill.
- Wave 20 has one big boss with escorts.
- Changing the formation at a regroup changed how the next phase went.
- You wanted to play again after losing.

- [ ] **Step 4: Decide**

Write one of these at the top of `fun-gate.md`:

- **PASS**: the battle is fun to replay. List what to carry into M4/M5 and any tuning deferred.
- **FAIL**: list the specific problems and which spec section each points at. Do not start M4. Bring the list back for a spec revision.

- [ ] **Step 5: Update the spec checklist and commit**

Tick the boxes in the spec's "Prototype checklist (M1-M3)" that are now true. The 200-enemies-at-60-fps item stays unticked: that is M4.

```bash
git add -A docs resources
git commit -m "Record the Fun Gate result and tuning" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

## Self-review notes

- **Spec coverage:** section 3 (phases, milestones, regroup, win/lose) is Tasks 5, 9, 10, 13; section 4 (triangle, formation, sortie, losses) is Tasks 3, 4, 8, 10, 13; section 5 (heroes) is Tasks 2, 6, 10, 12; section 6 (enemies) is Tasks 2, 5, 7; section 7 (towers) is Tasks 2, 8, 13; section 8 (budget, rubber band excluded) is Tasks 2, 3, 5; section 11 (HUD, regroup screen) is Tasks 12, 13. Deliberately not here: sections 9 and 10 (village, stages beyond stage 1, Endless), art and audio (M5), horde performance work (M4), the rubber band, save/load. The 500-instance cap in Task 11 is the only performance measure; real profiling is M4.
- **Spec deviations made explicit:** Bowman first appears in phase 3 (the spec's section 3 and 6 disagreed; the spec was corrected). `WaveData` is a runtime object, not a `.tres`. The spec's Rider "least-defended section" is implemented as `WaveData.LANE_AUTO`.
- **Type consistency checked:** `UnitRole.Kind` is used for troop kinds, enemy roles and hero buff targets everywhere; `WaveData.Milestone` for milestones everywhere; sections are `0..2` and kinds `0..2` in every `[section][kind]` array.
