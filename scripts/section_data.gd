class_name SectionData
extends Resource
## Describes one gate run: road, ordered gate pairs and blockers. Authored as .tres.

@export var section_name: String = ""
@export var region: StringName = &"greenfields"
## 0-based index used by the wave budget formula (the plan numbers sections from 1).
@export var section_index: int = 0
@export var allowed_enemies: Array[EnemyData] = []
@export var road_length: float = 120.0
@export var road_width: float = 8.0
@export var gate_pairs: Array[GatePairData] = []
@export var blockers: Array[BlockerData] = []
