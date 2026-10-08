extends RefCounted

var t
var _waves: Array = []
var _ended: Array = []

func _scene() -> Node:
	var s := (load("res://scenes/Battle.tscn") as PackedScene).instantiate()
	t.root.add_child(s)
	return s

func test_scene_opens_on_the_regroup_screen() -> void:
	var s := _scene()
	await t.process_frame
	t.check(s.regroup.visible, "regroup screen is up")
	t.check(s.battle.in_regroup(), "battle waits for Ready")
	t.eq(s.battle.state.pool.total(), 600, "default march capacity")
	s.queue_free()
	await t.process_frame

func test_ready_hides_the_regroup_screen_and_forwards_wave_start_to_event_bus() -> void:
	_waves.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(w): _waves.append(w)
	bus.wave_started.connect(cb)
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	bus.wave_started.disconnect(cb)
	t.eq(_waves, [1], "EventBus heard wave 1")
	t.check(not s.regroup.visible, "regroup closed")
	s.queue_free()
	await t.process_frame

func test_the_scene_ticks_the_battle_each_frame() -> void:
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	for _i in 40:
		await t.process_frame
	t.check(s.battle.horde.count() > 0 or s.battle.kills > 0, "enemies spawned and fought")
	s.queue_free()
	await t.process_frame

func test_debug_panel_requests_reach_the_active_battle() -> void:
	var s := _scene()
	await t.process_frame
	t.root.get_node("DebugPanel").spawn_wave(12)
	t.eq(s.battle.phase.wave, 12, "jumped to wave 12")
	t.root.get_node("DebugPanel").skip_phase()
	t.eq(s.battle.phase.wave, 16, "skipped to phase 4")
	s.queue_free()
	await t.process_frame
	t.root.get_node("DebugPanel").spawn_wave(3)

func test_defeat_shows_the_result_and_pays_gold_for_the_waves_reached() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	_ended.clear()
	var bus = t.root.get_node("EventBus")
	var cb := func(v): _ended.append(v)
	bus.battle_ended.connect(cb)
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	s.battle.debug_jump_to_wave(7)
	s.battle.state.damage_town_center(1.0e9)
	s.battle.tick(0.1)
	bus.battle_ended.disconnect(cb)
	t.eq(_ended, [false], "EventBus heard the defeat")
	t.check(s.result_panel.visible, "result panel shown")
	t.check(s.result_label.text.begins_with("DEFEAT"), "says defeat")
	t.eq(gs.gold, 70, "7 waves x 10 gold")
	t.eq(s.reward_gold, 70, "reward recorded on the scene")
	s.queue_free()
	await t.process_frame
	gs.reset()

func test_victory_pays_the_bonus() -> void:
	var gs = t.root.get_node("GameState")
	gs.reset()
	var s := _scene()
	await t.process_frame
	s.regroup.press_ready()
	s.battle.phase.jump_to_wave(20)
	s.battle.phase.tick(0.1, true)
	t.check(s.result_label.text.begins_with("VICTORY"), "says victory")
	t.eq(gs.gold, 300, "20 waves x 10 + 100")
	s.queue_free()
	await t.process_frame
	gs.reset()

func test_leaving_the_scene_disconnects_the_debug_hooks() -> void:
	var bus = t.root.get_node("EventBus")
	var before: int = bus.debug_spawn_wave.get_connections().size()
	var s := _scene()
	await t.process_frame
	t.eq(bus.debug_spawn_wave.get_connections().size(), before + 1, "scene connected")
	s.queue_free()
	await t.process_frame
	t.eq(bus.debug_spawn_wave.get_connections().size(), before, "and disconnected on exit")

func test_regroup_timeout_applies_the_players_choices_first() -> void:
	var s := _scene()
	await t.process_frame
	s.regroup.set_ratio(UnitRole.Kind.INFANTRY, 10.0)
	s.regroup.set_ratio(UnitRole.Kind.CAVALRY, 0.0)
	s.regroup.set_ratio(UnitRole.Kind.ARCHERS, 0.0)
	s.regroup.set_tower_choice(1, 0, 3)
	s.battle.phase.timer = 0.0
	await t.process_frame
	await t.process_frame
	t.eq(s.battle.phase.wave, 1, "the timeout started the wave")
	var infantry: int = s.battle.state.pool.count(0, UnitRole.Kind.INFANTRY) + s.battle.state.pool.count(1, UnitRole.Kind.INFANTRY) + s.battle.state.pool.count(2, UnitRole.Kind.INFANTRY)
	t.eq(infantry, 600, "all infantry")
	t.check(s.battle.state.towers[1][0] != null and s.battle.state.towers[1][0].id == &"cannon_tower", "tower choice applied")
	s.queue_free()
	await t.process_frame
