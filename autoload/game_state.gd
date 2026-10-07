extends Node

## Barracks capacity: max squad size after any gate. Debug default; village upgrades set it later.
var barracks_cap: int = 50
var base_squad_size: int = 20
var gold: int = 0
var shards: int = 0
var relics: int = 0
## 1-based, as on the world map.
var current_section: int = 1

func add_gold(amount: int) -> void:
	gold += amount

func reset() -> void:
	gold = 0
	shards = 0
	relics = 0
	current_section = 1
