class_name BlockerData
extends Resource
## Stub enemy group that halts the run until the squad has "fought" it.

@export var distance: float = 0.0
@export var enemy_count: int = 8
@export var fight_time: float = 1.0
## Squad units lost when the fight ends.
@export var losses: int = 4
