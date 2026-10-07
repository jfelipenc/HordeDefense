extends RefCounted

var t

func test_slots_returns_one_slot_per_unit() -> void:
	t.eq(Formation.slots(20, 0.8).size(), 20, "20 slots")
	t.eq(Formation.slots(0, 0.8).size(), 0, "0 slots")

func test_slots_do_not_stack() -> void:
	var s := Formation.slots(20, 0.8)
	var min_d := INF
	for i in s.size():
		for j in range(i + 1, s.size()):
			min_d = minf(min_d, s[i].distance_to(s[j]))
	t.check(min_d >= 0.8 * 0.7, "min spacing %f >= 0.56" % min_d)

func test_slots_are_compact_and_centered() -> void:
	var s := Formation.slots(20, 0.8)
	var c := Vector2.ZERO
	var max_r := 0.0
	for p in s:
		c += p
		max_r = maxf(max_r, p.length())
	c /= s.size()
	t.check(c.length() < 0.4, "centroid near origin: %f" % c.length())
	t.check(max_r < 0.8 * 4.0, "radius bounded for 20 units: %f" % max_r)

func test_slots_prefix_stable_when_count_grows() -> void:
	var a := Formation.slots(10, 0.8)
	var b := Formation.slots(11, 0.8)
	t.eq(a[3], b[3], "existing slots do not move when a unit is added")
