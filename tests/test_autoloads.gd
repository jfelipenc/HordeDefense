extends RefCounted

var t
var _hits: Array = []

func test_all_autoloads_present() -> void:
	for n in ["EventBus", "GameState", "SaveManager", "SceneSwapper", "DebugPanel"]:
		t.check(t.root.has_node(n), "autoload %s" % n)

func test_event_bus_signals_emit() -> void:
	var bus = t.root.get_node("EventBus")
	for sig in ["enemy_killed", "wall_damaged", "wave_cleared", "battle_ended", "gate_passed"]:
		t.check(bus.has_signal(sig), "signal " + sig)
	_hits.clear()
	var cb := func(v): _hits.append(v)
	bus.battle_ended.connect(cb)
	bus.battle_ended.emit(false)
	bus.battle_ended.disconnect(cb)
	t.eq(_hits, [false], "battle_ended emitted with payload")

func test_game_state_holds_currencies_and_resets() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	t.eq(gs.gold, 0, "gold reset")
	t.eq(gs.shards, 0, "shards reset")
	t.eq(gs.relics, 0, "relics reset")
	t.eq(gs.current_section, 1, "section is 1-based")
	gs.add_gold(25)
	t.eq(gs.gold, 25, "add_gold")
	gs.reset()

func test_save_manager_stub_is_callable() -> void:
	var sm = t.root.get_node("SaveManager")
	t.eq(sm.save_game(), true, "save stub")
	t.eq(sm.load_game(), true, "load stub")
