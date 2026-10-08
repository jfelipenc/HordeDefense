extends RefCounted

var t

func _hud(b: Battle) -> BattleHud:
	var h := BattleHud.new()
	h.battle = b
	t.root.add_child(h)
	return h

func test_texts_during_the_opening_regroup() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var h := _hud(b)
	t.eq(h.wave_text(), "Wave 1/20", "wave counter shows the upcoming wave")
	t.eq(h.phase_text(), "Regroup", "regroup label")
	t.eq(h.active_phase_index(), 0, "phase 1 highlighted")
	h.queue_free()

func test_texts_during_an_assault() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	var h := _hud(b)
	t.eq(h.phase_text(), "Phase 1/4", "phase label")
	b.debug_jump_to_wave(17)
	t.eq(h.wave_text(), "Wave 17/20", "wave counter")
	t.eq(h.phase_text(), "Phase 4/4", "phase 4")
	t.eq(h.active_phase_index(), 3, "fourth panel highlighted")
	h.queue_free()

func test_a_defeat_keeps_the_phase_of_the_wave_it_happened_in() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	b.debug_jump_to_wave(5)
	b.state.damage_town_center(1.0e9)
	b.tick(0.1)
	var h := _hud(b)
	t.eq(b.phase.state, PhaseMachine.State.LOST, "battle lost")
	t.eq(h.wave_text(), "Wave 5/20", "wave counter")
	t.eq(h.phase_text(), "Phase 1/4", "defeat screen still says phase 1")
	t.eq(h.active_phase_index(), 0, "first panel highlighted")
	h.queue_free()

func test_hero_button_is_off_in_a_regroup_and_on_in_an_assault() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var h := _hud(b)
	h.refresh()
	t.check(h._hero_button.disabled, "disabled during the regroup")
	b.ready()
	h.refresh()
	t.check(not h._hero_button.disabled, "enabled in an assault")
	t.eq(h.hero_text(), "Shield Bash", "shows the skill name")
	h.queue_free()

func test_pressing_the_hero_button_needs_enemies_then_starts_the_cooldown() -> void:
	var b := BattleFactory.create(0, null, "knight_captain")
	b.start()
	b.ready()
	var h := _hud(b)
	t.check(not h.press_hero(), "no enemies yet: nothing to aim at")
	b.tick(2.0)
	t.check(h.press_hero(), "skill fires at the busiest lane")
	h.refresh()
	t.check(h._hero_button.disabled, "on cooldown")
	t.check(h.hero_text().begins_with("Shield Bash "), "cooldown seconds shown")
	h.queue_free()

func test_no_hero_means_a_disabled_button() -> void:
	var b := BattleFactory.create(100, null, "")
	b.start()
	b.ready()
	var h := _hud(b)
	h.refresh()
	t.eq(h.hero_text(), "No hero", "label")
	t.check(h._hero_button.disabled, "disabled")
	h.queue_free()

func test_sortie_buttons_need_cavalry_in_their_section() -> void:
	var f := Formation.new()
	f.shares = [[1.0, 1.0, 1.0], [1.0, 0.0, 1.0], [1.0, 1.0, 1.0]]
	var b := BattleFactory.create(600, f)
	b.start()
	b.ready()
	var h := _hud(b)
	h.refresh()
	t.check(not h._sortie_buttons[0].disabled, "section 0 has cavalry")
	t.check(h._sortie_buttons[1].disabled, "section 1 has none")
	t.check(h.press_sortie(0), "sortie sent")
	h.refresh()
	t.eq(h._sortie_buttons[0].text, "Charging!", "shows the charge")
	t.check(h._sortie_buttons[2].disabled, "shared cooldown disables the others")
	h.queue_free()

func test_bars_and_troop_labels_follow_the_state() -> void:
	var b := BattleFactory.create(600)
	b.start()
	var h := _hud(b)
	h.refresh()
	t.eq(h._troop_labels[0].text, "Left  200", "troops per section")
	b.state.damage_town_center(2500.0)
	b.state.damage_wall(2, 1000.0)
	h.refresh()
	t.eq(h._tc_bar.value, 2500.0, "Town Center bar")
	t.eq(h._tc_bar.max_value, 5000.0, "Town Center max")
	t.eq(h._wall_bars[2].value, b.state.wall_hp[2], "right wall bar")
	h.queue_free()

func test_horde_counter() -> void:
	var b := BattleFactory.create(600)
	b.start()
	b.ready()
	var h := _hud(b)
	b.tick(2.0)
	h.refresh()
	t.eq(h._horde_label.text, "Horde: %d" % b.horde.count(), "live enemy count")
	h.queue_free()
