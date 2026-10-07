extends TestCase

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func test_autoloads_registered() -> void:
	for n in ["EventBus", "GameState", "SaveManager"]:
		assert_true(_root().has_node(n), "autoload %s missing" % n)

func test_eventbus_declares_required_signals() -> void:
	var bus := _root().get_node_or_null("EventBus")
	assert_true(bus != null, "EventBus missing")
	if bus == null:
		return
	for s in ["enemy_killed", "wall_damaged", "wave_cleared", "battle_ended", "gate_passed"]:
		assert_true(bus.has_signal(s), "EventBus lacks signal %s" % s)

func test_eventbus_signal_reaches_listener() -> void:
	var bus := _root().get_node_or_null("EventBus")
	assert_true(bus != null, "EventBus missing")
	if bus == null:
		return
	var got := []
	bus.battle_ended.connect(func(victory: bool): got.append(victory))
	bus.battle_ended.emit(false)
	assert_eq(got, [false], "battle_ended payload")

func test_gamestate_stub_tracks_gold() -> void:
	var gs := _root().get_node_or_null("GameState")
	assert_true(gs != null, "GameState missing")
	if gs == null:
		return
	var before: int = gs.gold
	gs.add_gold(25)
	assert_eq(gs.gold, before + 25, "gold after add")
	gs.gold = before

func test_savemanager_stub_is_callable() -> void:
	var sm := _root().get_node_or_null("SaveManager")
	assert_true(sm != null, "SaveManager missing")
	if sm == null:
		return
	assert_eq(sm.save_game(), false, "stub save returns false")
	assert_eq(sm.load_game(), false, "stub load returns false")
