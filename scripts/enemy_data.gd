class_name EnemyData
extends Resource
## One horde enemy type. Stats only; behavior lives in Horde.

enum Target { WALL, ARCHERS, TOWN_CENTER }

@export var id: StringName = &""
@export var display_name: String = ""
## Corner of the counter triangle; NONE for rams, siege and bosses.
@export var role: UnitRole.Kind = UnitRole.Kind.INFANTRY
@export var target: Target = Target.WALL
## Metres per second along the lane.
@export var speed: float = 1.0
@export var hp: float = 10.0
## Damage per second to whatever it attacks.
@export var dps: float = 1.0
## Metres from the wall at which it stops and attacks. 0 = melee.
@export var attack_range: float = 0.0
## Share of dps spent on the troops behind the wall (the rest hits the wall).
@export var troop_share: float = 0.0
## Wave-budget points this enemy costs. Reserved milestone enemies may be 0 (fixed count).
@export var cost: int = 1
@export var model_scale: float = 1.0
## Ordinary enemies (NONE) join the mix from this wave on.
@export var first_wave: int = 1
## Relative share of the mix among ordinary enemies.
@export var spawn_weight: float = 1.0
## Which milestone wave this enemy is reserved for; NONE = ordinary.
@export var milestone: WaveData.Milestone = WaveData.Milestone.NONE
