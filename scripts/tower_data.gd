class_name TowerData
extends Resource
## A wall tower. Placed at a regroup, fixed during a phase.

@export var id: StringName = &""
@export var display_name: String = ""
@export var dps: float = 20.0
@export var attack_range: float = 12.0
## Enemies hit at once (splash or pierce); each takes the full dps.
@export var max_targets: int = 1
## UnitRole.Kind values this tower is strong against.
@export var strong_vs: PackedInt32Array = PackedInt32Array()
@export var strong_mult: float = 1.5
