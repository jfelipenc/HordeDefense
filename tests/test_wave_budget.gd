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
