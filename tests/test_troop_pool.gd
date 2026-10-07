extends RefCounted

var t

func _pool() -> TroopPool:
	return TroopPool.new([[10, 4, 6], [10, 4, 6], [10, 4, 6]])

func test_totals() -> void:
	var p := _pool()
	t.eq(p.count(0, UnitRole.Kind.CAVALRY), 4, "count")
	t.eq(p.section_total(1), 20, "section total")
	t.eq(p.kind_total(UnitRole.Kind.INFANTRY), 30, "kind total")
	t.eq(p.total(), 60, "total")

func test_empty_pool_is_all_zero() -> void:
	t.eq(TroopPool.new().total(), 0, "default pool is empty")

func test_take_losses_clamps_to_living_troops() -> void:
	var p := _pool()
	t.eq(p.take_losses(0, UnitRole.Kind.ARCHERS, 4), 4, "four die")
	t.eq(p.count(0, UnitRole.Kind.ARCHERS), 2, "two left")
	t.eq(p.take_losses(0, UnitRole.Kind.ARCHERS, 50), 2, "cannot kill more than are alive")
	t.eq(p.count(0, UnitRole.Kind.ARCHERS), 0, "none left, never negative")
	t.eq(p.take_losses(0, UnitRole.Kind.ARCHERS, -3), 0, "negative losses do nothing")

func test_heal_returns_60_percent_of_losses_once() -> void:
	var p := _pool()
	p.take_losses(0, UnitRole.Kind.INFANTRY, 10)
	p.take_losses(1, UnitRole.Kind.ARCHERS, 5)
	t.eq(p.heal(0.6), 9, "6 + 3 troops return")
	t.eq(p.count(0, UnitRole.Kind.INFANTRY), 6, "infantry: 0 left + 6 healed")
	t.eq(p.count(1, UnitRole.Kind.ARCHERS), 4, "archers: 1 left + 3 healed")
	t.eq(p.heal(0.6), 0, "a second heal finds no new losses")

func test_heal_rounds_per_cell_and_never_exceeds_losses() -> void:
	var p := _pool()
	p.take_losses(0, UnitRole.Kind.CAVALRY, 1)
	var before := p.total()
	var healed := p.heal(0.6)
	t.check(healed <= 1, "never heals more than died")
	t.eq(p.total(), before + healed, "total grows by exactly the healed amount")

func test_full_and_zero_heal_shares() -> void:
	var p := _pool()
	p.take_losses(2, UnitRole.Kind.INFANTRY, 7)
	t.eq(p.heal(1.0), 7, "share 1.0 restores everyone")
	p.take_losses(2, UnitRole.Kind.INFANTRY, 7)
	t.eq(p.heal(0.0), 0, "share 0.0 restores no one")
	t.eq(p.count(2, UnitRole.Kind.INFANTRY), 3, "the 7 stay dead")

func test_reset_to_replaces_counts_and_clears_the_loss_log() -> void:
	var p := _pool()
	p.take_losses(0, UnitRole.Kind.INFANTRY, 5)
	p.reset_to([[1, 1, 1], [2, 2, 2], [3, 3, 3]])
	t.eq(p.total(), 18, "new counts in place")
	t.eq(p.heal(1.0), 0, "old losses forgotten")

func test_pool_does_not_alias_the_array_it_was_built_from() -> void:
	var src := [[1, 1, 1], [1, 1, 1], [1, 1, 1]]
	var p := TroopPool.new(src)
	p.take_losses(0, 0, 1)
	t.eq(src[0][0], 1, "source untouched")
