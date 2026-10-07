class_name CardData
extends Resource
## A pick-1-of-3 card. `effect` is a small script applied when the card is chosen (M3).

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var effect: Script
