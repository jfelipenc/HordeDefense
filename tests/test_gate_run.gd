extends RefCounted

var t
var _passed_gates: Array = []
var _finished: Array = []

func _on_gate_passed(g: GateData) -> void:
	_passed_gates.append(g)

func _on_finished(count: int, buffs: Dictionary, comp: Dictionary) -> void:
	_finished.append({"count": count, "buffs": buffs, "comp": comp})

func _run(steer_x: float, cap: int = 100) -> GateRun:
	_passed_gates.clear()
	_finished.clear()
	var bus = t.root.get_node("EventBus")
	for c in bus.gate_passed.get_connections():
		bus.gate_passed.disconnect(c.callable)
	for c in bus.gate_run_finished.get_connections():
		bus.gate_run_finished.disconnect(c.callable)
	bus.gate_passed.connect(_on_gate_passed)
	bus.gate_run_finished.connect(_on_finished)
	var gs = t.root.get_node("GameState")
	gs.barracks_cap = cap
	gs.base_squad_size = 20
	var run := GateRun.new()
	run.section = load("res://resources/sections/section_test.tres")
	t.root.add_child(run)
	run.snap_steer(steer_x)
	return run

func _finish(run: GateRun) -> void:
	var guard := 0
	while not run.is_finished() and guard < 10000:
		run.step(0.1)
		guard += 1
	t.check(guard < 10000, "run terminates")

func test_always_left_route_gives_expected_count() -> void:
	var run := _run(-2.0)
	_finish(run)
	# 20 +8 -10 (blocker -4) x2 +8 = 36
	t.eq(_finished.size(), 1, "finished emitted once")
	t.eq(_finished[0].count, 36, "final count, left route")
	run.queue_free()

func test_always_right_route_gives_expected_count_and_buff() -> void:
	var run := _run(2.0)
	_finish(run)
	# 20 x2=40, +5 archers=45, blocker -4=41, buff, -10=31
	t.eq(_finished[0].count, 31, "final count, right route")
	t.eq(_finished[0].buffs["fire_damage"], 20.0, "buff handed off")
	t.eq(_finished[0].comp.get("archer", 0), 5, "archers survive blocker (soldiers die first)")
	run.queue_free()

func test_exactly_one_gate_per_pair() -> void:
	var run := _run(-2.0)
	_finish(run)
	t.eq(_passed_gates.size(), run.section.gate_pairs.size(), "one gate_passed per pair")
	run.queue_free()

func test_steering_mid_run_chooses_per_pair() -> void:
	var run := _run(-2.0)
	while run.distance < 30.0:
		run.step(0.1)
	run.snap_steer(2.0)  # passed pair 1 on the left, now go right
	_finish(run)
	# 20 +8=28, pair2 right +5 archers=33, blocker -4=29, pair3 right buff, pair4 right -10=19
	t.eq(_finished[0].count, 19, "mixed route")
	run.queue_free()

func test_cannot_skip_the_blocker() -> void:
	var run := _run(-2.0)
	var hit_blocker := false
	var guard := 0
	while not run.is_finished() and guard < 10000:
		run.step(0.1)
		if run.is_fighting():
			hit_blocker = true
			t.check(run.distance <= run.section.blockers[0].distance + 0.001, "halts at blocker")
		guard += 1
	t.check(hit_blocker, "fight occurred before finish")
	run.queue_free()

func test_huge_delta_still_resolves_every_event() -> void:
	var run := _run(-2.0)
	var guard := 0
	while not run.is_finished() and guard < 100:
		run.step(5.0)
		guard += 1
	t.eq(_passed_gates.size(), 4, "all gate pairs passed even with huge steps")
	t.eq(_finished[0].count, 36, "same result as small steps")
	run.queue_free()

func test_cap_clamps_run_and_overflow_becomes_gold() -> void:
	var gs = t.root.get_node("GameState")
	var run := _run(-2.0, 30)
	var gold_before: int = gs.gold
	_finish(run)
	# left route: ... x2 -> 28, +8 -> 36 clamped to 30, overflow 6
	t.eq(_finished[0].count, 30, "clamped to cap")
	t.eq(gs.gold - gold_before, 6, "overflow gold")
	run.queue_free()

func test_x4_gate_clamped_by_debug_cap_50() -> void:
	var gs = t.root.get_node("GameState")
	var run := _run(-2.0, 50)
	run.squad.apply_gate(GateData.make(GateData.Type.MULTIPLIER, 4), 50)
	t.eq(run.squad.unit_count(), 50, "x4 on 20 clamped to 50")
	run.queue_free()

func test_squad_label_matches_units_throughout_run() -> void:
	var run := _run(2.0)
	var guard := 0
	while not run.is_finished() and guard < 10000:
		run.step(0.1)
		t.check(run.squad.label_count() == run.squad.unit_count(), "label == units at distance %.1f" % run.distance)
		guard += 1
	run.queue_free()

func test_run_scene_builds_visuals_for_every_gate_and_blocker() -> void:
	var run := _run(0.0)
	t.eq(run.gate_view_count(), run.section.gate_pairs.size() * 2, "two gate views per pair")
	t.eq(run.blocker_enemy_count(), run.section.blockers[0].enemy_count, "blocker enemies")
	run.queue_free()

func test_drag_steers_squad_and_clamps_to_road() -> void:
	var run := _run(0.0)
	var ev := InputEventScreenDrag.new()
	ev.relative = Vector2(100, 0)
	run._unhandled_input(ev)
	t.check(run.steer_target() > 0.5, "drag right steers right")
	ev.relative = Vector2(-100000, 0)
	run._unhandled_input(ev)
	t.eq(run.steer_target(), -run.max_x(), "clamped to road edge")
	run.queue_free()
