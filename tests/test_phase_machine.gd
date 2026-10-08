extends RefCounted

var t
const Kit = preload("res://tests/kit.gd")

var _log: Array = []

func _machine() -> PhaseMachine:
	var m := PhaseMachine.new(Kit.tuning())
	_log.clear()
	m.regroup_started.connect(func(p): _log.append("regroup%d" % p))
	m.wave_started.connect(func(w): _log.append("start%d" % w))
	m.wave_cleared.connect(func(w): _log.append("clear%d" % w))
	m.phase_cleared.connect(func(p): _log.append("phase%d" % p))
	m.battle_ended.connect(func(v): _log.append("won" if v else "lost"))
	return m

## Starts the next wave and clears it at once.
func _play_wave(m: PhaseMachine) -> void:
	if m.state == PhaseMachine.State.REGROUP:
		m.ready()
	else:
		m.tick(999.0, false)
	m.tick(0.1, true)

func test_battle_opens_with_a_regroup() -> void:
	var m := _machine()
	m.start()
	t.eq(m.state, PhaseMachine.State.REGROUP, "regroup first")
	t.eq(m.timer, 15.0, "15 second countdown")
	t.eq(m.wave, 0, "no wave yet")
	t.eq(_log, ["regroup1"], "regroup for phase 1 announced")
	t.eq(m.current_phase(), 1, "phase 1")

func test_ready_starts_wave_one() -> void:
	var m := _machine()
	m.start()
	m.ready()
	t.eq(m.state, PhaseMachine.State.ASSAULT, "assault")
	t.eq(m.wave, 1, "wave 1")
	t.eq(_log, ["regroup1", "start1"], "wave announced")

func test_the_regroup_countdown_starts_the_wave_by_itself() -> void:
	var m := _machine()
	m.start()
	m.tick(14.0, false)
	t.eq(m.state, PhaseMachine.State.REGROUP, "still counting")
	m.tick(1.5, false)
	t.eq(m.state, PhaseMachine.State.ASSAULT, "countdown ended")

func test_ready_does_nothing_outside_a_regroup() -> void:
	var m := _machine()
	m.start()
	m.ready()
	m.ready()
	t.eq(m.wave, 1, "second ready ignored")

func test_a_cleared_ordinary_wave_leads_to_a_breather_then_the_next_wave() -> void:
	var m := _machine()
	m.start()
	m.ready()
	m.tick(0.1, false)
	t.eq(m.state, PhaseMachine.State.ASSAULT, "enemies still alive")
	m.tick(0.1, true)
	t.eq(m.state, PhaseMachine.State.BREATHER, "breather")
	t.eq(m.timer, 4.0, "4 seconds")
	m.tick(3.0, false)
	t.eq(m.state, PhaseMachine.State.BREATHER, "still breathing")
	m.tick(1.5, false)
	t.eq(m.state, PhaseMachine.State.ASSAULT, "next wave")
	t.eq(m.wave, 2, "wave 2")

func test_milestone_wave_ends_the_phase_with_a_regroup() -> void:
	var m := _machine()
	m.start()
	for w in 5:
		_play_wave(m)
	t.eq(m.state, PhaseMachine.State.REGROUP, "regroup after wave 5")
	t.eq(m.wave, 5, "wave 5 done")
	t.eq(_log.slice(-3), ["clear5", "phase1", "regroup2"], "phase 1 cleared, regroup for phase 2")
	t.eq(m.current_phase(), 2, "now looking at phase 2")
	m.ready()
	t.eq(m.wave, 6, "wave 6 follows")

func test_ordinary_waves_never_trigger_a_phase_clear() -> void:
	var m := _machine()
	m.start()
	for w in 4:
		_play_wave(m)
	t.check(not ("phase1" in _log), "no phase clear before wave 5")

func test_twenty_cleared_waves_win_the_battle() -> void:
	var m := _machine()
	m.start()
	for w in 20:
		_play_wave(m)
	t.eq(m.state, PhaseMachine.State.WON, "won")
	t.eq(m.highest_wave, 20, "reached wave 20")
	t.eq(_log.slice(-3), ["clear20", "phase4", "won"], "final order")
	t.eq(_log.count("regroup1") + _log.count("regroup2") + _log.count("regroup3") + _log.count("regroup4"), 4, "regroups: start + after waves 5, 10, 15")
	t.check(not ("regroup5" in _log), "no regroup after the last wave")
	m.tick(100.0, true)
	t.eq(m.state, PhaseMachine.State.WON, "stays won")

func test_losing_ends_the_battle_once() -> void:
	var m := _machine()
	m.start()
	m.ready()
	m.lose()
	t.eq(m.state, PhaseMachine.State.LOST, "lost")
	m.lose()
	t.eq(_log.count("lost"), 1, "announced once")
	m.tick(100.0, true)
	t.eq(m.state, PhaseMachine.State.LOST, "stays lost")
	t.check(m.is_over(), "over")

func test_a_loss_after_a_win_changes_nothing() -> void:
	var m := _machine()
	m.start()
	for w in 20:
		_play_wave(m)
	m.lose()
	t.eq(m.state, PhaseMachine.State.WON, "still won")

func test_jump_to_wave_starts_that_wave_and_clamps() -> void:
	var m := _machine()
	m.start()
	m.jump_to_wave(12)
	t.eq(m.wave, 12, "wave 12")
	t.eq(m.state, PhaseMachine.State.ASSAULT, "assault")
	t.eq(m.current_phase(), 3, "phase 3")
	m.jump_to_wave(99)
	t.eq(m.wave, 20, "clamped to the last wave")
	m.jump_to_wave(-4)
	t.eq(m.wave, 1, "clamped to the first wave")

func test_skip_phase_jumps_to_the_first_wave_of_the_next_phase() -> void:
	var m := _machine()
	m.start()
	m.skip_phase()
	t.eq(m.wave, 6, "from the opening regroup to wave 6")
	m.skip_phase()
	t.eq(m.wave, 11, "wave 11")
	m.skip_phase()
	m.skip_phase()
	t.eq(m.wave, 20, "capped at the final wave")

func test_current_phase_during_an_assault_is_the_waves_phase() -> void:
	var m := _machine()
	m.start()
	m.jump_to_wave(5)
	t.eq(m.current_phase(), 1, "wave 5 is still phase 1")
	m.jump_to_wave(6)
	t.eq(m.current_phase(), 2, "wave 6")
