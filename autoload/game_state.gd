extends Node

var gold: int = 0
var shards: int = 0
## 1-based, as on the stage list.
var current_stage: int = 1
## Total troops fielded; the Town Center level sets this once the village exists (M6).
var march_capacity: int = 600

func add_gold(amount: int) -> void:
	gold += amount

## Rewards scale with the highest wave reached, so a loss still pays something.
func record_battle(victory: bool, highest_wave: int) -> void:
	add_gold(highest_wave * 10 + (100 if victory else 0))

func reset() -> void:
	gold = 0
	shards = 0
	current_stage = 1
	march_capacity = 600
