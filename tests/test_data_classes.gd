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
