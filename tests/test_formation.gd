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
