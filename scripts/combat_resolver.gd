class_name CombatResolver
extends RefCounted
## The defenders' turn: troops and towers of each wall section shoot the enemies in that lane.

static func step(dt: float, state: BattleState, horde: Horde) -> void:
	if horde.count() == 0:
		return
	var tu := state.tuning
	var orders := horde.lane_orders()
	for s in BattleState.SECTIONS:
		var order: Array = orders[s]
		if order.is_empty():
			continue
		for k in UnitRole.TROOP_KINDS:
			var n := state.pool.count(s, k)
			if n <= 0:
				continue
			var def: TroopData = state.troop_defs[k]
			var dps := n * def.dps * state.damage_mult(k) * dt
			var reach := tu.melee_reach
			if k == UnitRole.Kind.ARCHERS:
				reach = def.attack_range
			elif k == UnitRole.Kind.CAVALRY:
				if state.sortie_left[s] > 0.0:
					reach = tu.sortie_reach
					dps *= tu.sortie_mult
				else:
					dps *= tu.cavalry_reserve_mult
			horde.strike_front(order, reach, dps, k, tu)
		for tw in state.towers[s]:
			if tw != null:
				horde.strike_many(order, tw.attack_range, tw.dps * state.tower_mult() * dt, tw.max_targets, tw.strong_vs, tw.strong_mult)
