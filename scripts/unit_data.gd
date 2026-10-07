class_name UnitData
extends Resource
## One player unit type (soldier, archer, ...).

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: float = 10.0
@export var damage: float = 1.0
## 0 = melee on the wall.
@export var attack_range: float = 0.0
@export var attack_interval: float = 1.0
@export var color: Color = Color.WHITE
