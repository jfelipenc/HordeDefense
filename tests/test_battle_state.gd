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
