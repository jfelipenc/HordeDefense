class_name BattleFactory
extends RefCounted
## Builds a Battle from the stock resources: stage 1, default tuning and tier-1 troops.

## `capacity` troops dealt by `formation` (default 50/20/30, even), an optional hero id
## ("knight_captain", "ranger", "mage") and optionally one tower type in every slot.
static func create(capacity: int, formation: Formation = null, hero_id: String = "knight_captain", tower_id: String = "") -> Battle:
	var tuning := load("res://resources/tuning/default.tres") as TuningData
	var stage := load("res://resources/stages/stage_01.tres") as StageData
	var defs := {
		UnitRole.Kind.INFANTRY: load("res://resources/troops/infantry_t1.tres"),
		UnitRole.Kind.CAVALRY: load("res://resources/troops/cavalry_t1.tres"),
		UnitRole.Kind.ARCHERS: load("res://resources/troops/archers_t1.tres"),
	}
	var f := formation if formation != null else Formation.new()
	var hero: HeroData = null
	if hero_id != "":
		hero = load("res://resources/heroes/%s.tres" % hero_id) as HeroData
	var st := BattleState.new(tuning, defs, TroopPool.new(f.counts(capacity)), hero)
	if tower_id != "":
		var tower := load("res://resources/towers/%s.tres" % tower_id) as TowerData
		for s in BattleState.SECTIONS:
			for slot in BattleState.TOWER_SLOTS:
				st.towers[s][slot] = tower
	return Battle.new(stage, tuning, st)
