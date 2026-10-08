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
