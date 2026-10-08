class_name Horde
extends RefCounted
## The enemies of one battle as plain data arrays (design spec, section 13): no nodes, no physics.
## Index i across all arrays is one enemy. Lanes are 1D: `dist` is metres from the wall.

var types: Array[EnemyData] = []
var lane := PackedInt32Array()
var dist := PackedFloat32Array()
var hp := PackedFloat32Array()
## Stage stat multiplier, applied to the enemy's damage (its HP is scaled at spawn).
var power := PackedFloat32Array()
## 1 if the enemy arrived from the side (flank), for the view only.
var from_side := PackedByteArray()
## Sideways offset in -0.5..0.5 fixed at spawn (the view scales it), so it survives swap-removal.
var jitter := PackedFloat32Array()
var _spawned: int = 0

func count() -> int:
	return types.size()

func spawn(enemy: EnemyData, spawn_lane: int, spawn_dist: float, stat_mult: float, side: bool = false) -> void:
	types.append(enemy)
	lane.append(spawn_lane)
	dist.append(spawn_dist)
	hp.append(enemy.hp * stat_mult)
	power.append(stat_mult)
	from_side.append(1 if side else 0)
	jitter.append(fposmod(_spawned * 0.618034, 1.0) - 0.5)
	_spawned += 1

func count_in_lane(section: int) -> int:
	var n := 0
	for i in count():
		if lane[i] == section:
			n += 1
	return n

## The lane with the most enemies (lowest index on ties), or -1 if the horde is empty.
func busiest_lane() -> int:
	var best := -1
	var best_n := 0
	for s in BattleState.SECTIONS:
		var n := count_in_lane(s)
		if n > best_n:
			best_n = n
			best = s
	return best

## Enemy indices per lane, nearest the wall first.
func lane_orders() -> Array:
	var orders: Array = [[], [], []]
	for i in count():
		orders[lane[i]].append(i)
	for o in orders:
		o.sort_custom(func(a, b): return dist[a] < dist[b])
	return orders

# --- enemy turn -------------------------------------------------------------

## Moves every enemy toward the wall and lets the ones in range attack.
func step(dt: float, state: BattleState) -> void:
	for i in count():
		var e := types[i]
		if dist[i] > e.attack_range:
			dist[i] = maxf(dist[i] - e.speed * dt, e.attack_range)
			continue
		_attack(i, e, e.dps * power[i] * dt, state)

func _attack(i: int, e: EnemyData, dmg: float, state: BattleState) -> void:
	var s := lane[i]
	if e.target == EnemyData.Target.TOWN_CENTER:
		state.damage_town_center(dmg)
		return
	if e.target == EnemyData.Target.ARCHERS and state.damage_troops(s, UnitRole.Kind.ARCHERS, dmg):
		return
	var rest := dmg
	var to_troops := dmg * e.troop_share
	if to_troops > 0.0 and state.damage_troops_front(s, to_troops):
		rest -= to_troops
	if state.wall_broken(s):
		state.damage_town_center(rest)
	else:
		state.damage_wall(s, rest)

# --- defender turn ----------------------------------------------------------

## Spends `raw` damage on the enemies in `order` that are within `reach`, nearest first. Damage is
## scaled by the triangle against each victim; leftover damage after a kill carries to the next one.
func strike_front(order: Array, reach: float, raw: float, attacker: UnitRole.Kind, tuning: TuningData) -> void:
	var remaining := raw
	for i in order:
		if remaining <= 0.0:
			return
		if hp[i] <= 0.0:
			continue
		if dist[i] > reach:
			return
		var mult := Triangle.multiplier(attacker, types[i].role, tuning)
		var dealt := remaining * mult
		if dealt >= hp[i]:
			remaining -= hp[i] / mult
			hp[i] = 0.0
		else:
			hp[i] -= dealt
			return

## Gives each of the first `max_targets` living enemies within `reach` the full `raw` damage
## (towers: splash or pierce), times `strong_mult` for roles in `strong_vs`.
func strike_many(order: Array, reach: float, raw: float, max_targets: int, strong_vs: PackedInt32Array, strong_mult: float) -> void:
	var hit := 0
	for i in order:
		if hit >= max_targets:
			return
		if hp[i] <= 0.0:
			continue
		if dist[i] > reach:
			return
		hp[i] -= raw * (strong_mult if types[i].role in strong_vs else 1.0)
		hit += 1

## Damages every enemy within `reach` in one lane and pushes the survivors back (hero skill).
func blast(section: int, reach: float, damage: float, knockback: float, lane_length: float) -> void:
	for i in count():
		if lane[i] == section and dist[i] <= reach and hp[i] > 0.0:
			hp[i] -= damage
			dist[i] = minf(dist[i] + knockback, lane_length)

## Removes dead enemies; returns how many were removed.
func reap() -> int:
	var kills := 0
	for i in range(count() - 1, -1, -1):
		if hp[i] <= 0.0:
			_remove(i)
			kills += 1
	return kills

func _remove(i: int) -> void:
	var last := count() - 1
	if i != last:
		types[i] = types[last]
		lane[i] = lane[last]
		dist[i] = dist[last]
		hp[i] = hp[last]
		power[i] = power[last]
		from_side[i] = from_side[last]
		jitter[i] = jitter[last]
	types.pop_back()
	lane.resize(last)
	dist.resize(last)
	hp.resize(last)
	power.resize(last)
	from_side.resize(last)
	jitter.resize(last)
