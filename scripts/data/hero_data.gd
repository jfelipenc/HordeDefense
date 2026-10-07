class_name HeroData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: float = 100.0
@export var damage: float = 5.0
@export var attack_interval: float = 1.0
@export var skill_name: String = ""
@export var skill_cooldown: float = 12.0  ## seconds, design range 8-20
@export var passive_description: String = ""
@export var unlock_condition: String = "start"
