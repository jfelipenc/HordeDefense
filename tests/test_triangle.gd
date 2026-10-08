extends RefCounted

var t

func _tu() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

func test_infantry_beats_cavalry_beats_archers_beats_infantry() -> void:
	t.check(Triangle.beats(UnitRole.Kind.INFANTRY, UnitRole.Kind.CAVALRY), "infantry > cavalry")
	t.check(Triangle.beats(UnitRole.Kind.CAVALRY, UnitRole.Kind.ARCHERS), "cavalry > archers")
	t.check(Triangle.beats(UnitRole.Kind.ARCHERS, UnitRole.Kind.INFANTRY), "archers > infantry")
	t.check(not Triangle.beats(UnitRole.Kind.CAVALRY, UnitRole.Kind.INFANTRY), "not the reverse")

func test_multiplier_win_lose_neutral() -> void:
	var tu := _tu()
	t.eq(Triangle.multiplier(UnitRole.Kind.INFANTRY, UnitRole.Kind.CAVALRY, tu), 1.5, "winning matchup")
	t.eq(Triangle.multiplier(UnitRole.Kind.CAVALRY, UnitRole.Kind.INFANTRY, tu), 0.75, "losing matchup")
	t.eq(Triangle.multiplier(UnitRole.Kind.INFANTRY, UnitRole.Kind.INFANTRY, tu), 1.0, "same kind is neutral")

func test_enemies_outside_the_triangle_are_neutral_for_everyone() -> void:
	var tu := _tu()
	for k in UnitRole.TROOP_KINDS:
		t.eq(Triangle.multiplier(k, UnitRole.Kind.NONE, tu), 1.0, "kind %d vs NONE" % k)
		t.eq(Triangle.multiplier(UnitRole.Kind.NONE, k, tu), 1.0, "NONE vs kind %d" % k)

func test_counter_of_returns_the_kind_that_beats_it() -> void:
	t.eq(Triangle.counter_of(UnitRole.Kind.INFANTRY), UnitRole.Kind.ARCHERS, "archers counter infantry")
	t.eq(Triangle.counter_of(UnitRole.Kind.CAVALRY), UnitRole.Kind.INFANTRY, "infantry counter cavalry")
	t.eq(Triangle.counter_of(UnitRole.Kind.ARCHERS), UnitRole.Kind.CAVALRY, "cavalry counter archers")
	t.eq(Triangle.counter_of(UnitRole.Kind.NONE), UnitRole.Kind.NONE, "nothing counters NONE")
