class_name PhaseMachine
extends RefCounted
## The shape of a battle: REGROUP -> (ASSAULT -> BREATHER)* -> ASSAULT -> REGROUP ... -> WON / LOST.
## A regroup opens the battle and follows each milestone wave (5, 10, 15). Pure state, no nodes.

enum State { REGROUP, ASSAULT, BREATHER, WON, LOST }

signal regroup_started(phase: int)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal phase_cleared(phase: int)
signal battle_ended(victory: bool)

var tuning: TuningData
var state: State = State.REGROUP
## The wave in progress, or the last one cleared; 0 before the first wave.
var wave: int = 0
var highest_wave: int = 0
## Seconds left in the current REGROUP or BREATHER.
var timer: float = 0.0

func _init(p_tuning: TuningData) -> void:
	tuning = p_tuning

func is_over() -> bool:
	return state == State.WON or state == State.LOST

## The phase the player is in, or about to enter during a regroup.
func current_phase() -> int:
	var in_wave := state == State.ASSAULT or state == State.BREATHER or state == State.LOST
	return WaveBudget.phase_of(maxi(wave, 1) if in_wave else wave + 1, tuning)

## Opens the battle with its first regroup.
func start() -> void:
	state = State.REGROUP
	timer = tuning.regroup_seconds
	regroup_started.emit(1)

## The player pressed Ready (or the countdown ended).
func ready() -> void:
	if state == State.REGROUP:
		_begin_wave()

## Advances timers. `wave_done` is true once every enemy of the wave has spawned and died.
func tick(dt: float, wave_done: bool) -> void:
	match state:
		State.REGROUP, State.BREATHER:
			timer -= dt
			if timer <= 0.0:
				_begin_wave()
		State.ASSAULT:
			if wave_done:
				_finish_wave()

func lose() -> void:
	if is_over():
		return
	state = State.LOST
	battle_ended.emit(false)

## Debug: start wave `n` right now.
func jump_to_wave(n: int) -> void:
	if is_over():
		return
	wave = clampi(n, 1, tuning.waves_per_battle) - 1
	_begin_wave()

## Debug: jump to the first wave of the next phase (or the last wave if already in phase 4).
func skip_phase() -> void:
	var next_first := current_phase() * tuning.phase_length + 1
	jump_to_wave(mini(next_first, tuning.waves_per_battle))

func _begin_wave() -> void:
	wave += 1
	highest_wave = maxi(highest_wave, wave)
	state = State.ASSAULT
	wave_started.emit(wave)

func _finish_wave() -> void:
	wave_cleared.emit(wave)
	var milestone := WaveBudget.is_milestone(wave, tuning)
	if milestone:
		phase_cleared.emit(WaveBudget.phase_of(wave, tuning))
	if wave >= tuning.waves_per_battle:
		state = State.WON
		battle_ended.emit(true)
	elif milestone:
		state = State.REGROUP
		timer = tuning.regroup_seconds
		regroup_started.emit(WaveBudget.phase_of(wave + 1, tuning))
	else:
		state = State.BREATHER
		timer = tuning.breather_seconds
