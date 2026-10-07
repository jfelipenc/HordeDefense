extends RefCounted

var t

func _g(type: int, value: float, unit: StringName = &"", buff: StringName = &"") -> GateData:
	return GateData.make(type, value, unit, buff)

func test_additive_gate_adds_soldiers() -> void:
	var s := SquadState.new({"soldier": 20})
	s.apply_gate(_g(GateData.Type.ADDITIVE, 8))
	t.eq(s.total(), 28, "additive +8 on 20")

func test_multiplier_gate_multiplies_every_type() -> void:
	var s := SquadState.new({"soldier": 20, "archer": 5})
	s.apply_gate(_g(GateData.Type.MULTIPLIER, 2))
	t.eq(s.counts["soldier"], 40, "soldiers x2")
	t.eq(s.counts["archer"], 10, "archers x2")
	t.eq(s.total(), 50, "total x2")

func test_negative_gate_removes_soldiers_first() -> void:
	var s := SquadState.new({"soldier": 20, "archer": 5})
	s.apply_gate(_g(GateData.Type.NEGATIVE, 10))
	t.eq(s.counts["soldier"], 10, "soldiers lose 10")
	t.eq(s.counts["archer"], 5, "archers untouched")

func test_negative_gate_spills_into_other_types() -> void:
	var s := SquadState.new({"soldier": 3, "archer": 5})
	s.apply_gate(_g(GateData.Type.NEGATIVE, 6))
	t.eq(s.total(), 2, "total after spill")
	t.eq(s.counts.get("soldier", 0), 0, "no soldiers left")

func test_count_never_drops_below_one() -> void:
	var s := SquadState.new({"soldier": 4})
	s.apply_gate(_g(GateData.Type.NEGATIVE, 50))
	t.eq(s.total(), 1, "floored at 1")

func test_type_gate_adds_named_unit() -> void:
	var s := SquadState.new({"soldier": 20})
	s.apply_gate(_g(GateData.Type.TYPE, 5, &"archer"))
	t.eq(s.counts["archer"], 5, "5 archers")
	t.eq(s.total(), 25, "total")

func test_buff_gate_records_buff_without_changing_count() -> void:
	var s := SquadState.new({"soldier": 20})
	s.apply_gate(_g(GateData.Type.BUFF, 20, &"", &"fire_damage"))
	s.apply_gate(_g(GateData.Type.BUFF, 10, &"", &"fire_damage"))
	t.eq(s.total(), 20, "count unchanged")
	t.eq(s.buffs["fire_damage"], 30.0, "buffs stack additively")

func test_cap_clamps_and_reports_overflow() -> void:
	var s := SquadState.new({"soldier": 20})
	s.apply_gate(_g(GateData.Type.MULTIPLIER, 4))
	var overflow := s.clamp_to_cap(50)
	t.eq(s.total(), 50, "clamped to cap")
	t.eq(overflow, 30, "overflow = 80 - 50")

func test_cap_trims_archers_before_soldiers_keeps_proportion() -> void:
	var s := SquadState.new({"soldier": 40, "archer": 20})
	var overflow := s.clamp_to_cap(30)
	t.eq(overflow, 30, "overflow")
	t.eq(s.total(), 30, "total")
	t.eq(s.counts["soldier"], 20, "soldiers keep proportion")
	t.eq(s.counts["archer"], 10, "archers keep proportion")

func test_cap_no_overflow_when_under() -> void:
	var s := SquadState.new({"soldier": 20})
	t.eq(s.clamp_to_cap(50), 0, "no overflow")
	t.eq(s.total(), 20, "unchanged")

func test_lose_casualties_reduces_total_but_floors_at_one() -> void:
	var s := SquadState.new({"soldier": 10})
	s.lose(4)
	t.eq(s.total(), 6, "lost 4")
	s.lose(100)
	t.eq(s.total(), 1, "floor 1")

func test_gate_labels() -> void:
	t.eq(_g(GateData.Type.ADDITIVE, 8).label(), "+8", "additive label")
	t.eq(_g(GateData.Type.MULTIPLIER, 2).label(), "x2", "multiplier label")
	t.eq(_g(GateData.Type.NEGATIVE, 10).label(), "-10", "negative label")
	t.eq(_g(GateData.Type.TYPE, 5, &"archer").label(), "+5 Archer", "type label")
	t.eq(_g(GateData.Type.BUFF, 20, &"", &"fire_damage").label(), "+20% Fire Damage", "buff label")
