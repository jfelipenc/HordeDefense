class_name SectionData
extends Resource

@export var index: int = 0  ## 0-based; the world map shows index + 1
@export var display_name: String = ""
@export var region: StringName = &"greenfields"
@export var theme: StringName = &""
@export var base_budget: float = 100.0  ## B0
@export var wave_count: int = 5
@export var allowed_enemies: Array[EnemyData] = []
@export var boss: EnemyData
## Gate pair i is (gates_left[i], gates_right[i]).
@export var gates_left: Array[GateData] = []
@export var gates_right: Array[GateData] = []
