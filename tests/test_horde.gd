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
	t.eq(h.jitter.size(), 1, "jitter stored")

func test_jitter_follows_each_enemy_through_a_reap() -> void:
	var h := Horde.new()
	for d in [10.0, 20.0, 30.0, 40.0]:
		Kit.spawn(h, "raider", 0, d)
	t.eq(h.jitter.size(), h.count(), "jitter size after spawn")
	t.check(h.jitter[0] != h.jitter[1] and h.jitter[1] != h.jitter[2] and h.jitter[2] != h.jitter[3], "consecutive spawns differ")
	var before := {}
	for i in h.count():
		before[h.dist[i]] = h.jitter[i]
	h.hp[1] = 0.0  # the enemy at 20 m dies; the last one (40 m) takes its slot
	t.eq(h.reap(), 1, "one reaped")
	t.eq(h.jitter.size(), h.count(), "jitter size after reap")
	t.eq(h.count(), 3, "three left")
	for i in h.count():
		t.eq(h.jitter[i], before[h.dist[i]], "enemy at %s m keeps its jitter" % h.dist[i])

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
