class_name EnemyData
extends Resource
## One horde enemy type. Stats only; behavior comes with the horde manager (M2).

@export var id: StringName = &""
@export var display_name: String = ""
## Metres per second along the lane.
@export var speed: float = 1.0
@export var hp: float = 10.0
## Damage per second to a wall segment or the town center.
@export var wall_damage: float = 1.0
## Wave-budget points this enemy costs.
@export var cost: int = 1
@export var model_scale: float = 1.0
