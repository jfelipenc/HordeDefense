class_name EnemyData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: float = 10.0
@export var speed: float = 1.0  ## lane units per second
@export var wall_damage: float = 1.0  ## per second against walls and the town center
@export var cost: int = 1  ## wave budget points
@export var first_section: int = 0  ## 0-based index, see design doc enemy table
@export var scale: float = 1.0
@export var tint: Color = Color.WHITE
