extends RefCounted

var t

func _squad(counts: Dictionary) -> Squad:
	var sq := Squad.new()
	t.root.add_child(sq)
	sq.setup(SquadState.new(counts))
	return sq

func _gate(type: int, value: float, unit: StringName = &"") -> GateData:
	return GateData.make(type, value, unit)

func test_setup_spawns_one_follower_per_unit_and_label_matches() -> void:
	var sq := _squad({"soldier": 20})
	t.eq(sq.unit_count(), 20, "followers")
	t.eq(sq.label_count(), 20, "label")
	sq.queue_free()

func test_gate_updates_followers_and_label_together() -> void:
	var sq := _squad({"soldier": 20})
	var overflow := sq.apply_gate(_gate(GateData.Type.MULTIPLIER, 2), 100)
	t.eq(overflow, 0, "no overflow")
	t.eq(sq.unit_count(), 40, "followers after x2")
	t.eq(sq.label_count(), 40, "label after x2")
	sq.apply_gate(_gate(GateData.Type.NEGATIVE, 15), 100)
	t.eq(sq.unit_count(), 25, "followers after -15")
	t.eq(sq.label_count(), 25, "label after -15")
	t.check(sq.dying_count() > 0, "lost units are still falling away visually")
	sq.queue_free()

func test_cap_clamps_followers_and_returns_overflow() -> void:
	var sq := _squad({"soldier": 20})
	var overflow := sq.apply_gate(_gate(GateData.Type.MULTIPLIER, 4), 50)
	t.eq(overflow, 30, "overflow")
	t.eq(sq.unit_count(), 50, "followers clamped")
	t.eq(sq.label_count(), 50, "label clamped")
	sq.queue_free()

func test_type_gate_spawns_archer_followers() -> void:
	var sq := _squad({"soldier": 20})
	sq.apply_gate(_gate(GateData.Type.TYPE, 5, &"archer"), 100)
	t.eq(sq.unit_count_of("archer"), 5, "archers")
	t.eq(sq.unit_count_of("soldier"), 20, "soldiers")
	sq.queue_free()

func test_followers_settle_into_distinct_slots() -> void:
	var sq := _squad({"soldier": 20})
	sq.step(2.0)
	var pos := sq.follower_positions()
	var min_d := INF
	for i in pos.size():
		for j in range(i + 1, pos.size()):
			min_d = minf(min_d, pos[i].distance_to(pos[j]))
	t.check(min_d > Squad.SPACING * 0.5, "group not a stack: min dist %f" % min_d)
	sq.queue_free()

func test_new_units_spawn_in_small_then_grow() -> void:
	var sq := _squad({"soldier": 5})
	sq.step(2.0)
	sq.apply_gate(_gate(GateData.Type.ADDITIVE, 5), 100)
	t.check(sq.min_follower_scale() < 0.5, "fresh units start small")
	sq.step(2.0)
	t.check(is_equal_approx(sq.min_follower_scale(), 1.0), "and reach full size")
	sq.queue_free()

func test_dying_followers_are_freed_after_animation() -> void:
	var sq := _squad({"soldier": 20})
	sq.apply_gate(_gate(GateData.Type.NEGATIVE, 10), 100)
	sq.step(2.0)
	t.eq(sq.dying_count(), 0, "dying followers cleaned up")
	sq.queue_free()
