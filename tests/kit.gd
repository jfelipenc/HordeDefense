extends RefCounted
## Shared builders for battle tests. Not a suite: the runner only loads tests/test_*.gd.

static func tuning() -> TuningData:
	return load("res://resources/tuning/default.tres") as TuningData

static func stage() -> StageData:
	return load("res://resources/stages/stage_01.tres") as StageData

static func enemy(id: String) -> EnemyData:
	return load("res://resources/enemies/%s.tres" % id) as EnemyData

static func tower(id: String) -> TowerData:
	return load("res://resources/towers/%s.tres" % id) as TowerData

static func troop_defs() -> Dictionary:
	return {
		UnitRole.Kind.INFANTRY: load("res://resources/troops/infantry_t1.tres"),
		UnitRole.Kind.CAVALRY: load("res://resources/troops/cavalry_t1.tres"),
		UnitRole.Kind.ARCHERS: load("res://resources/troops/archers_t1.tres"),
	}

## A state with the same [infantry, cavalry, archers] counts in every section.
static func state(per_section: Array = [100, 40, 60], hero_id: String = "") -> BattleState:
	var hero: HeroData = null
	if hero_id != "":
		hero = load("res://resources/heroes/%s.tres" % hero_id) as HeroData
	var counts := [per_section.duplicate(), per_section.duplicate(), per_section.duplicate()]
	return BattleState.new(tuning(), troop_defs(), TroopPool.new(counts), hero)

## Spawns one enemy at `dist` in `lane` with full stats.
static func spawn(horde, id: String, lane: int, dist: float) -> void:
	horde.spawn(enemy(id), lane, dist, 1.0)
