extends Node
## Run-wide and meta progress. Stub: real persistence lands in M6.1.

signal gold_changed(gold: int)

var gold: int = 0
var shards: int = 0
var relics: Array[StringName] = []
var section_index: int = 0  ## 0-based, matches the design doc budget formula


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func set_section(index: int) -> void:
	section_index = maxi(index, 0)
