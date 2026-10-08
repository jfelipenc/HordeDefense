extends RefCounted

var t
var _pressed: int = 0

func _screen(b: Battle) -> RegroupScreen:
	var r := RegroupScreen.new()
	r.battle = b
	t.root.add_child(r)
	return r

func test_opening_shows_the_title_and_the_scout_report() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	t.check(r.visible, "visible")
	t.eq(r._title.text, "Regroup - Phase 1", "title")
	t.check(r._preview.text.contains("Raider"), "lists raiders")
	t.check(r._preview.text.contains("Wave 5: Flank (from the left)"), "names the milestone and its side")
	r.queue_free()

func test_preview_for_phase_two_names_the_keep_strike() -> void:
	var b := BattleFactory.create(1500)
	b.start()
	b.ready()
	for _i in 20000:
		if b.in_regroup():
			break
		b.tick(0.1)
	var r := _screen(b)
	r.open()
	t.eq(r._title.text, "Regroup - Phase 2", "title")
	t.check(r._preview.text.contains("Wave 10: Keep strike"), "keep strike listed")
	t.check(r._preview.text.contains("Ram"), "rams listed")
	r.queue_free()

func test_first_open_applies_the_recommended_formation() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	var f := r.build_formation()
	t.check(f.ratio[UnitRole.Kind.ARCHERS] > 3.0, "phase 1 is all infantry-type raiders, so archers are favoured")
	r.queue_free()

func test_reopening_keeps_the_players_choices() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	r.set_ratio(UnitRole.Kind.CAVALRY, 9.0)
	r.close()
	r.open()
	t.eq(r.build_formation().ratio[UnitRole.Kind.CAVALRY], 9.0, "slider kept its value")
	r.recommend()
	t.check(r.build_formation().ratio[UnitRole.Kind.CAVALRY] != 9.0, "the Recommended button resets it")
	r.queue_free()

func test_build_formation_reads_every_slider() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	r.set_ratio(0, 4.0)
	r.set_ratio(1, 1.0)
	r.set_ratio(2, 5.0)
	r.set_share(0, 2, 4.0)
	r.set_share(1, 2, 0.0)
	var f := r.build_formation()
	t.eq(f.ratio, [4.0, 1.0, 5.0] as Array[float], "ratio")
	t.eq(f.shares[2][0], 4.0, "archers' share of the left section")
	t.eq(f.shares[2][1], 0.0, "archers' share of the center section")
	r.queue_free()

func test_ready_applies_the_formation_and_towers_and_starts_the_wave() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	_pressed = 0
	r.ready_pressed.connect(func(): _pressed += 1)
	r.open()
	r.set_ratio(0, 10.0)
	r.set_ratio(1, 0.0)
	r.set_ratio(2, 0.0)
	r.set_share(0, 0, 0.0)
	r.set_share(1, 0, 0.0)
	r.set_share(2, 0, 4.0)
	r.set_tower_choice(1, 0, 3)
	r.press_ready()
	t.eq(b.state.pool.count(2, UnitRole.Kind.INFANTRY), 600, "all infantry on the right")
	t.eq(b.state.pool.total(), 600, "troops conserved")
	t.eq(b.state.towers[1][0].id, &"cannon_tower", "cannon in section 1 slot 0")
	t.eq(b.state.towers[1][1], null, "other slot empty")
	t.eq(b.phase.state, PhaseMachine.State.ASSAULT, "wave 1 under way")
	t.eq(_pressed, 1, "signal emitted once")
	r.queue_free()

func test_ready_outside_a_regroup_changes_nothing() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	var before := b.state.pool.counts.duplicate(true)
	var r := _screen(b)
	r.open()
	r.set_ratio(0, 10.0)
	r.set_ratio(2, 0.0)
	r.press_ready()
	t.eq(b.state.pool.counts, before, "formation refused during an assault")
	t.eq(b.phase.wave, 1, "still wave 1")
	r.queue_free()

func test_zero_sliders_everywhere_still_deal_every_troop() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var r := _screen(b)
	r.open()
	for k in 3:
		r.set_ratio(k, 0.0)
		for s in 3:
			r.set_share(s, k, 0.0)
	r.press_ready()
	t.eq(b.state.pool.total(), 600, "no troops lost to a bad formation")

func test_the_summary_shows_the_resulting_counts() -> void:
	var b := BattleFactory.create(300)
	b.start()
	var r := _screen(b)
	r.open()
	r.set_ratio(0, 5.0)
	r.set_ratio(1, 2.0)
	r.set_ratio(2, 3.0)
	r._process(0.0)
	t.check(r._summary.text.contains("Left: I 50 C 20 A 30"), "even 50/20/30 over 300 troops")
	r.queue_free()
