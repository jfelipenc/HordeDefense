class_name SectionData
extends Resource
## Replaced by StageData in Task 2. The gate-run fields are gone.

@export var section_name: String = ""
@export var region: StringName = &"greenfields"
## 0-based index used by the wave budget formula (the plan numbers sections from 1).
@export var section_index: int = 0
@export var allowed_enemies: Array[EnemyData] = []
