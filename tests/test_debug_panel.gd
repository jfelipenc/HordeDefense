extends RefCounted

var t
var _waves: Array = []

func _panel():
	return t.root.get_node("DebugPanel")

func test_spawn_wave_emits_on_event_bus() -> void:
	_waves.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(w): _waves.append(w)
	bus.debug_spawn_wave.connect(cb)
	_panel().spawn_wave(3)
	bus.debug_spawn_wave.disconnect(cb)
	t.eq(_waves, [3], "wave 3 requested")

func test_set_section_updates_game_state() -> void:
	var gs = t.root.get_node("GameState")
	_panel().set_section(7)
	t.eq(gs.current_section, 7, "section set")
	gs.reset()

func test_add_gold_updates_game_state() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	_panel().add_gold(500)
	t.eq(gs.gold, 500, "gold added")
	gs.reset()

func test_speed_toggle_switches_time_scale_4x() -> void:
	var p = _panel()
	p.toggle_speed()
	t.eq(Engine.time_scale, 4.0, "4x on")
	p.toggle_speed()
	t.eq(Engine.time_scale, 1.0, "back to 1x")

func test_panel_toggles_visibility() -> void:
	var p = _panel()
	t.eq(p.is_open(), false, "starts closed")
	p.toggle()
	t.eq(p.is_open(), true, "opens")
	p.toggle()
	t.eq(p.is_open(), false, "closes")

func test_three_finger_tap_toggles_panel() -> void:
	var p = _panel()
	p.track_touch(0, true)
	p.track_touch(1, true)
	t.eq(p.is_open(), false, "two fingers do nothing")
	p.track_touch(2, true)
	t.eq(p.is_open(), true, "third finger opens")
	p.track_touch(0, false)
	p.track_touch(1, false)
	p.track_touch(2, false)
	p.toggle()
