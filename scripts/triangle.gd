class_name Triangle
extends RefCounted
## The counter triangle: Infantry > Cavalry > Archers > Infantry. NONE is outside it.

static func beats(attacker: UnitRole.Kind, defender: UnitRole.Kind) -> bool:
	match attacker:
		UnitRole.Kind.INFANTRY:
			return defender == UnitRole.Kind.CAVALRY
		UnitRole.Kind.CAVALRY:
			return defender == UnitRole.Kind.ARCHERS
		UnitRole.Kind.ARCHERS:
			return defender == UnitRole.Kind.INFANTRY
	return false

## Damage multiplier for `attacker` hitting `defender`: win, lose or neutral.
static func multiplier(attacker: UnitRole.Kind, defender: UnitRole.Kind, tuning: TuningData) -> float:
	if beats(attacker, defender):
		return tuning.triangle_win
	if beats(defender, attacker):
		return tuning.triangle_lose
	return 1.0

## The troop kind that beats `enemy`, or NONE when the enemy is outside the triangle.
static func counter_of(enemy: UnitRole.Kind) -> UnitRole.Kind:
	for k in UnitRole.TROOP_KINDS:
		if beats(k, enemy):
			return k
	return UnitRole.Kind.NONE
