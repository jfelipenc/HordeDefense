class_name CardData
extends Resource

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var effect_script: Script  ## effect implementation, wired in M3.5
@export var magnitude: float = 0.0
@export var unlock_condition: String = "start"
