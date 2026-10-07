class_name WaveData
extends RefCounted
## One wave as built by WaveSpawner. A runtime object, not an authored .tres.

enum Milestone { NONE, FLANK, KEEP_STRIKE, SIEGE, BOSS }

## Lane value meaning "the section with the fewest troops when the enemy spawns".
const LANE_AUTO := -1

var wave: int = 0
var phase: int = 1
var milestone: Milestone = Milestone.NONE
var budget: float = 0.0
## Each entry: { "enemy": EnemyData, "lane": int (0-2 or LANE_AUTO), "delay": float, "side": bool }
var spawns: Array = []

func count_of(id: StringName) -> int:
	var n := 0
	for s in spawns:
		if s.enemy.id == id:
			n += 1
	return n

## Total budget points actually spent (boss counts as its listed cost, which is 0).
func spent() -> int:
	var total := 0
	for s in spawns:
		total += s.enemy.cost
	return total
