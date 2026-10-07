extends RefCounted

var t

func test_main_hands_run_result_to_wall_placeholder() -> void:
	var gs = t.root.get_node("GameState")
	gs.barracks_cap = 100
	gs.base_squad_size = 20
	var main = load("res://scenes/Main.tscn").instantiate()
	t.root.add_child(main)
	t.check(main.current_run != null, "main starts a gate run")
	var run: GateRun = main.current_run
	run.snap_steer(-2.0)
	var guard := 0
	while not run.is_finished() and guard < 10000:
		run.step(0.1)
		guard += 1
	t.check(main.wall != null, "wall placeholder shown after run")
	if main.wall:
		t.eq(main.wall.received_count, 36, "wall received final count")
		t.eq(main.wall.received_composition.get("soldier", 0), 36, "wall received composition")
	main.queue_free()
