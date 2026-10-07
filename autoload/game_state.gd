extends Node

## Barracks capacity: max squad size after any gate. Debug default; village upgrades set it later.
var barracks_cap: int = 50
var base_squad_size: int = 20
var gold: int = 0

func add_gold(amount: int) -> void:
	gold += amount
