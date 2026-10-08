class_name TroopData
extends Resource
## One troop type at one tier. All values are per troop; the pool holds counts.

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: UnitRole.Kind = UnitRole.Kind.INFANTRY
@export var tier: int = 1
@export var hp: float = 40.0
@export var dps: float = 3.0
## Metres from the wall the troop can hit. 0 = melee.
@export var attack_range: float = 0.0
@export var color: Color = Color.WHITE
