class_name StageData
extends Resource
## One 20-wave horde event. Authored as .tres.

@export var stage_name: String = ""
@export var region: StringName = &"greenfields"
## 0-based index used by the wave budget formula.
@export var stage_index: int = 0
@export var allowed_enemies: Array[EnemyData] = []
## Lane (0 left, 1 center, 2 right) hit by the wave 5 flank.
@export var flank_lane: int = 0
