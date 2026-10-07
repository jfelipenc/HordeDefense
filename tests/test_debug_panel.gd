extends TestCase

const PANEL := "res://ui/DebugPanel.tscn"


func _bus() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("EventBus")


func _gs() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")


func _spawn() -> Node:
	var p: Node = (load(PANEL) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(p)
	return p


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


func _touch(index: int, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	return e


func test_panel_starts_hidden_and_f1_toggles() -> void:
	var p := _spawn()
	assert_eq(p.is_open(), false, "initially closed")
	p.handle_input(_key(KEY_F1))
	assert_eq(p.is_open(), true, "open after F1")
	p.handle_input(_key(KEY_F1))
	assert_eq(p.is_open(), false, "closed after second F1")
	p.queue_free()


func test_three_finger_tap_toggles() -> void:
	var p := _spawn()
	p.handle_input(_touch(0, true))
	p.handle_input(_touch(1, true))
	assert_eq(p.is_open(), false, "two fingers do nothing")
	p.handle_input(_touch(2, true))
	assert_eq(p.is_open(), true, "three fingers open")
	for i in 3:
		p.handle_input(_touch(i, false))
	p.queue_free()


func test_add_gold_and_set_section_reach_game_state() -> void:
	var p := _spawn()
	var gold_before: int = _gs().gold
	p.add_gold(100)
	assert_eq(_gs().gold, gold_before + 100, "gold")
	p.set_section(7)
	assert_eq(_gs().section_index, 7, "section")
	_gs().gold = gold_before
	_gs().section_index = 0
	p.queue_free()


func test_speed_toggle_switches_between_1x_and_4x() -> void:
	var p := _spawn()
	p.toggle_speed()
	assert_eq(Engine.time_scale, 4.0, "4x on")
	p.toggle_speed()
	assert_eq(Engine.time_scale, 1.0, "back to 1x")
	p.queue_free()


func test_spawn_wave_emits_request() -> void:
	var p := _spawn()
	var got := []
	p.wave_spawn_requested.connect(func(n: int): got.append(n))
	p.spawn_wave(3)
	assert_eq(got, [3], "requested wave")
	p.queue_free()


func test_emit_test_signals_fires_all_five_bus_signals() -> void:
	var p := _spawn()
	var seen := {}
	for s in ["enemy_killed", "wall_damaged", "wave_cleared", "battle_ended", "gate_passed"]:
		_bus().connect(s, func(_a = null, _b = null, _c = null): seen[s] = true)
	p.emit_test_signals()
	assert_eq(seen.size(), 5, "signals seen: " + str(seen.keys()))
	p.queue_free()


func test_main_scene_contains_debug_panel() -> void:
	var main: Node = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	assert_true(main.get_node_or_null("DebugPanel") != null, "Main has DebugPanel")
	main.free()
