class_name BattleSim
extends RefCounted
## Runs a Battle to its end with no view: skips regroup countdowns and optionally plays the
## light tactics (hero skill and cavalry sortie on the busiest lane). Used by tests and tools/sim_battle.gd.

static func run(battle: Battle, tactics: bool = true, dt: float = 0.1, max_seconds: float = 3600.0) -> Dictionary:
	battle.start()
	var elapsed := 0.0
	while battle.is_running() and elapsed < max_seconds:
		if battle.in_regroup():
			battle.ready()
		elif tactics and battle.phase.state == PhaseMachine.State.ASSAULT:
			var lane := battle.horde.busiest_lane()
			if lane >= 0:
				battle.use_hero_skill(lane)
				battle.use_sortie(lane)
		battle.tick(dt)
		elapsed += dt
	return {
		"victory": battle.phase.state == PhaseMachine.State.WON,
		"timed_out": battle.is_running(),
		"highest_wave": battle.phase.highest_wave,
		"seconds": elapsed,
		"kills": battle.kills,
		"town_center": battle.state.town_center_hp,
		"troops_left": battle.state.pool.total(),
	}
