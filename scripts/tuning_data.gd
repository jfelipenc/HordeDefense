class_name TuningData
extends Resource
## Every balance number in one file (design spec section 8). Provisional until the Fun Gate.

@export_group("Waves")
@export var waves_per_battle: int = 20
@export var phase_length: int = 5
@export var b0: float = 100.0
@export var growth_stage: float = 1.12
@export var growth_wave: float = 1.10
@export var milestone_mult: float = 1.5
## Share of the wave 5 budget spent on the flanking group.
@export var flank_share: float = 0.4
## Share of the wave 10 / wave 15 budget spent on rams / siege units.
@export var special_share: float = 0.1
## Share of the wave 20 budget spent on the boss's escorts (the boss itself is free).
@export var escort_share: float = 0.5
## Enemy HP and damage grow by this factor per stage.
@export var stat_growth: float = 1.06
## Seconds over which a wave's enemies trickle in.
@export var spawn_window: float = 6.0
@export_group("Triangle")
@export var triangle_win: float = 1.5
@export var triangle_lose: float = 0.75
@export_group("Regroup")
@export var heal_share: float = 0.6
@export var wall_repair_share: float = 0.3
@export var breather_seconds: float = 4.0
@export var regroup_seconds: float = 15.0
@export_group("Battlefield")
@export var lane_length: float = 24.0
@export var wall_hp: float = 3000.0
@export var town_center_hp: float = 5000.0
## Extra wall HP per infantry troop assigned to a section (0.0005 x 200 troops = +10%).
@export var infantry_wall_bonus: float = 0.0005
@export var melee_reach: float = 1.0
@export_group("Cavalry sortie")
@export var cavalry_reserve_mult: float = 0.5
@export var sortie_mult: float = 3.0
@export var sortie_reach: float = 22.0
@export var sortie_duration: float = 4.0
@export var sortie_cooldown: float = 10.0
