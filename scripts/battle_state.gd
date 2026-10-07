class_name BattleState
extends RefCounted
## Everything the defenders own: three wall sections, the Town Center, troops, towers, the hero
## and the tap-skill timers. Pure data plus small rules; no nodes.

const SECTIONS := 3
const TOWER_SLOTS := 2

var tuning: TuningData
## UnitRole.Kind -> TroopData
var troop_defs: Dictionary
var pool: TroopPool
var hero: HeroData
## towers[section] is an Array of TOWER_SLOTS entries, each a TowerData or null.
var towers: Array = [[null, null], [null, null], [null, null]]
var wall_hp: Array[float] = [0.0, 0.0, 0.0]
var wall_max: Array[float] = [0.0, 0.0, 0.0]
var town_center_hp: float = 0.0
var town_center_max: float = 0.0
## Seconds of cavalry sortie left per section, and the shared cooldowns.
var sortie_left: Array[float] = [0.0, 0.0, 0.0]
var sortie_cooldown: float = 0.0
var hero_cooldown: float = 0.0
## Fractional troop damage not yet large enough to kill a whole troop: [section][kind].
var _carry: Array = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]

func _init(p_tuning: TuningData, p_defs: Dictionary, p_pool: TroopPool, p_hero: HeroData = null) -> void:
	tuning = p_tuning
	troop_defs = p_defs
	pool = p_pool
	hero = p_hero
	refresh_wall_max(true)
	town_center_max = tuning.town_center_hp
	town_center_hp = town_center_max

# --- walls and Town Center -------------------------------------------------

## Recomputes each section's max HP from its infantry. Keeps the HP ratio unless `fill` is set.
## A broken wall (ratio 0) stays broken.
func refresh_wall_max(fill: bool = false) -> void:
	for s in SECTIONS:
		var new_max := tuning.wall_hp * (1.0 + pool.count(s, UnitRole.Kind.INFANTRY) * tuning.infantry_wall_bonus)
		var ratio := 1.0 if fill or wall_max[s] <= 0.0 else wall_hp[s] / wall_max[s]
		wall_max[s] = new_max
		wall_hp[s] = new_max * ratio

func wall_broken(section: int) -> bool:
	return wall_hp[section] <= 0.0

func damage_wall(section: int, amount: float) -> void:
	wall_hp[section] = maxf(wall_hp[section] - amount, 0.0)

func damage_town_center(amount: float) -> void:
	town_center_hp = maxf(town_center_hp - amount, 0.0)

func town_center_dead() -> bool:
	return town_center_hp <= 0.0

## Restores `share` of each section's max HP (a broken wall stands again if share > 0).
func repair_walls(share: float) -> void:
	for s in SECTIONS:
		wall_hp[s] = minf(wall_hp[s] + wall_max[s] * share, wall_max[s])

## 0 = fresh, 1 = scuffed, 2 = cracked, 3 = broken (the three crack stages from the spec).
func crack_stage(section: int) -> int:
	if wall_hp[section] <= 0.0:
		return 3
	var ratio := wall_hp[section] / wall_max[section]
	if ratio <= 0.33:
		return 2
	if ratio <= 0.66:
		return 1
	return 0

# --- troops ------------------------------------------------------------------

func troop_hp(kind: int) -> float:
	var hp: float = troop_defs[kind].hp
	if hero and hero.buff_kind == kind and hero.buff_stat == HeroData.BuffStat.HP:
		hp *= hero.buff_mult
	return hp

func damage_mult(kind: int) -> float:
	if hero and hero.buff_kind == kind and hero.buff_stat == HeroData.BuffStat.DAMAGE:
		return hero.buff_mult
	return 1.0

func tower_mult() -> float:
	return hero.buff_mult if hero and hero.buff_towers else 1.0

## Applies damage to the troops of one kind in a section. Returns false if there are none,
## so the attacker can pick another target.
func damage_troops(section: int, kind: int, amount: float) -> bool:
	if pool.count(section, kind) <= 0:
		return false
	_carry[section][kind] += amount
	var per := troop_hp(kind)
	var n := int(_carry[section][kind] / per)
	if n > 0:
		_carry[section][kind] -= n * per
		pool.take_losses(section, kind, n)
	return true

## Damage to the front-most living troops of a section: infantry, then archers, then cavalry.
func damage_troops_front(section: int, amount: float) -> bool:
	for kind in [UnitRole.Kind.INFANTRY, UnitRole.Kind.ARCHERS, UnitRole.Kind.CAVALRY]:
		if damage_troops(section, kind, amount):
			return true
	return false

# --- timers ------------------------------------------------------------------

func tick_timers(dt: float) -> void:
	for s in SECTIONS:
		sortie_left[s] = maxf(sortie_left[s] - dt, 0.0)
	sortie_cooldown = maxf(sortie_cooldown - dt, 0.0)
	hero_cooldown = maxf(hero_cooldown - dt, 0.0)

func reset_skill_timers() -> void:
	sortie_left = [0.0, 0.0, 0.0]
	sortie_cooldown = 0.0
	hero_cooldown = 0.0
