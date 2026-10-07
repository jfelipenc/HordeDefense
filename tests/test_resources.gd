extends RefCounted

var t

func test_gate_tres_files_cover_all_five_types() -> void:
	var seen := {}
	var dir := DirAccess.open("res://resources/gates")
	t.check(dir != null, "gates dir exists")
	if dir == null:
		return
	for f in dir.get_files():
		if f.ends_with(".tres"):
			var g := load("res://resources/gates/" + f) as GateData
			t.check(g != null, f + " loads as GateData")
			if g:
				seen[g.type] = true
	for type in GateData.Type.values():
		t.check(seen.has(type), "gate .tres exists for type %d" % type)

func test_pair_picks_left_or_right_by_x() -> void:
	var p := GatePairData.new()
	p.left = GateData.make(GateData.Type.ADDITIVE, 5)
	p.right = GateData.make(GateData.Type.MULTIPLIER, 2)
	t.check(p.pick(-0.1) == p.left, "negative x -> left")
	t.check(p.pick(0.1) == p.right, "positive x -> right")

func test_section_resource_has_ordered_gate_pairs_and_blocker() -> void:
	var s := load("res://resources/sections/section_test.tres") as SectionData
	t.check(s != null, "section loads")
	if s == null:
		return
	t.check(s.gate_pairs.size() >= 4, "at least 4 gate pairs")
	var last := -1.0
	for p in s.gate_pairs:
		t.check(p.distance > last, "pairs ordered by distance")
		t.check(p.left != null and p.right != null, "pair has both gates")
		last = p.distance
	t.check(s.blockers.size() >= 1, "has a blocker")
	t.check(s.road_length > last, "road longer than last gate")
