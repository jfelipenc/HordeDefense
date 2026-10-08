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
