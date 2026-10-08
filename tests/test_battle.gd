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
