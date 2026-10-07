class_name UnitData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: float = 10.0
@export var damage: float = 1.0
@export var attack_interval: float = 1.0  ## seconds
@export var range: float = 0.0  ## 0 = melee, engages only enemies at the wall
@export var unlock_condition: String = "start"
