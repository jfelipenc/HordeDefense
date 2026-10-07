class_name WaveSpawner
extends RefCounted
## Turns a stage and a wave number into a WaveData: spends the wave budget on the stage's
## allowed enemies and shapes the four milestone waves. Pure and deterministic.

const SPREAD := -2

static func build(stage: StageData, tuning: TuningData, wave: int) -> WaveData:
	var data := WaveData.new()
	data.wave = wave
	data.phase = WaveBudget.phase_of(wave, tuning)
	data.milestone = WaveBudget.milestone_of(wave, tuning)
	data.budget = WaveBudget.budget(wave, stage.stage_index, tuning)
	var ordinary := _pool(stage, WaveData.Milestone.NONE, wave)
	var special := _pool(stage, data.milestone, wave)
	var seq: Array = []
	var left := data.budget
	match data.milestone:
		WaveData.Milestone.FLANK:
			var share := data.budget * tuning.flank_share
			_buy(seq, ordinary, share, stage.flank_lane, true)
			left -= share
		WaveData.Milestone.KEEP_STRIKE, WaveData.Milestone.SIEGE:
			var share := data.budget * tuning.special_share
			_buy(seq, special, share, SPREAD, false)
			left -= share
		WaveData.Milestone.BOSS:
			if not special.is_empty():
				seq.append({"enemy": special[0], "lane": 1, "side": false})
			left = data.budget * tuning.escort_share
	_buy(seq, ordinary, left, SPREAD, false)
	_finish(data, seq, tuning)
	return data

## Enemies that may appear: ordinary ones from their first wave on, or those reserved for `milestone`.
static func _pool(stage: StageData, milestone: WaveData.Milestone, wave: int) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	for e in stage.allowed_enemies:
		if e.milestone != milestone:
			continue
		if milestone == WaveData.Milestone.NONE and e.first_wave > wave:
			continue
		out.append(e)
	return out

## Buys enemies from `pool` until `budget` cannot afford the cheapest one. The mix follows
## spawn_weight: each pick is the enemy with the fewest purchases per unit of weight.
static func _buy(out: Array, pool: Array[EnemyData], budget: float, lane: int, side: bool) -> void:
	if pool.is_empty():
		return
	var bought := {}
	var left := budget
	var guard := 0
	while guard < 5000:
		var pick: EnemyData = null
		var best := INF
		for e in pool:
			if maxi(e.cost, 1) > left:
				continue
			var score := float(bought.get(e.id, 0)) / maxf(e.spawn_weight, 0.001)
			if score < best:
				best = score
				pick = e
		if pick == null:
			break
		bought[pick.id] = bought.get(pick.id, 0) + 1
		left -= maxi(pick.cost, 1)
		out.append({"enemy": pick, "lane": lane, "side": side})
		guard += 1

## Resolves SPREAD lanes round-robin, sends archer-hunters to the weakest section, spreads delays.
static func _finish(data: WaveData, seq: Array, tuning: TuningData) -> void:
	var rr := 0
	for i in seq.size():
		var s: Dictionary = seq[i]
		if s.lane == SPREAD:
			if s.enemy.target == EnemyData.Target.ARCHERS:
				s.lane = WaveData.LANE_AUTO
			else:
				s.lane = rr % 3
				rr += 1
		s["delay"] = float(i) / float(seq.size()) * tuning.spawn_window
		data.spawns.append(s)
