extends SceneTree
## Balance probe: godot --headless --path . -s res://tools/sim_battle.gd
## Prints how stage 1 plays out for a few capacities, hero and tower setups.

func _initialize() -> void:
	for cap in [0, 300, 600, 1000, 1500, 2500]:
		_report("cap %d, default, no towers" % cap, BattleFactory.create(cap, null, "knight_captain", ""))
	for tower in ["arrow_tower", "crossbow_tower", "cannon_tower"]:
		_report("cap 600, default, %s" % tower, BattleFactory.create(600, null, "knight_captain", tower))
	var archers := Formation.new()
	archers.ratio = [3.0, 1.0, 6.0]
	_report("cap 600, archer-heavy", BattleFactory.create(600, archers, "ranger", "arrow_tower"))
	var all_inf := Formation.new()
	all_inf.ratio = [1.0, 0.0, 0.0]
	_report("cap 600, all infantry", BattleFactory.create(600, all_inf, "knight_captain", ""))
	quit()

func _report(label: String, battle: Battle) -> void:
	var r := BattleSim.run(battle, true)
	print("%-34s -> %s wave %2d  tc %5.0f  troops %4d  kills %5d  %4.0fs%s" % [label, "WIN " if r.victory else "LOSE", r.highest_wave, r.town_center, r.troops_left, r.kills, r.seconds, " TIMEOUT" if r.timed_out else ""])
