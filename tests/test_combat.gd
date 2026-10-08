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
