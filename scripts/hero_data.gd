class_name HeroData
extends Resource
## A hero: auto-attacks from the wall, one tap skill with a cooldown, one passive.

@export var id: StringName = &""
@export var display_name: String = ""
@export var hp: float = 100.0
@export var damage: float = 5.0
@export var attack_interval: float = 1.0
@export var skill_name: String = ""
## Design range is 8-20 s.
@export var skill_cooldown: float = 12.0
@export var passive_text: String = ""
