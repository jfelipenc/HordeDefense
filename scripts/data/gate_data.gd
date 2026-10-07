class_name GateData
extends Resource
## One gate on the run. Fields only; behaviour lives in the Gate scene (M1.3).

enum GateType { ADDITIVE, MULTIPLIER, NEGATIVE, TYPE, BUFF }

@export var id: StringName = &""
@export var type: GateType = GateType.ADDITIVE
## Amount: +N for additive, xN for multiplier, N removed for negative, N units for type.
@export var value: float = 0.0
## TYPE gates: which unit to add. BUFF gates: which stat the buff touches.
@export var unit: UnitData
@export var buff_stat: StringName = &""
@export var buff_percent: float = 0.0
@export var label: String = ""
