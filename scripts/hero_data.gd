class_name HeroData
extends Resource
## A hero: one tap skill with a cooldown and one passive that buffs a troop type or the towers.

enum BuffStat { HP, DAMAGE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var skill_name: String = ""
## Design range is 8-20 s.
@export var skill_cooldown: float = 12.0
## Damage to every enemy within skill_reach of the wall in the chosen section's lane.
@export var skill_damage: float = 200.0
@export var skill_reach: float = 22.0
## Metres the survivors are pushed back.
@export var skill_knockback: float = 3.0
@export var passive_text: String = ""
## Troop kind the passive buffs, or NONE.
@export var buff_kind: UnitRole.Kind = UnitRole.Kind.NONE
@export var buff_stat: BuffStat = BuffStat.HP
@export var buff_towers: bool = false
@export var buff_mult: float = 1.1
