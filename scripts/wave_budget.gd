class_name WaveBudget
extends RefCounted
## Wave and phase arithmetic from the design spec, section 8. Pure functions, no state.

## Phase (1-4) a wave belongs to; waves past the last phase stay in it.
static func phase_of(wave: int, tuning: TuningData) -> int:
	var phases := tuning.waves_per_battle / tuning.phase_length
	return clampi((wave - 1) / tuning.phase_length + 1, 1, phases)

static func is_milestone(wave: int, tuning: TuningData) -> bool:
	return wave >= 1 and wave <= tuning.waves_per_battle and wave % tuning.phase_length == 0

## FLANK, KEEP_STRIKE, SIEGE or BOSS at waves 5, 10, 15, 20; NONE everywhere else.
static func milestone_of(wave: int, tuning: TuningData) -> WaveData.Milestone:
	if not is_milestone(wave, tuning):
		return WaveData.Milestone.NONE
	return (wave / tuning.phase_length) as WaveData.Milestone

## budget(L, w) = B0 * g_L^L * g_w^w * m(w)
static func budget(wave: int, stage_index: int, tuning: TuningData) -> float:
	var m := tuning.milestone_mult if is_milestone(wave, tuning) else 1.0
	return tuning.b0 * pow(tuning.growth_stage, stage_index) * pow(tuning.growth_wave, wave) * m

## Multiplier on enemy HP and damage for a stage.
static func stat_mult(stage_index: int, tuning: TuningData) -> float:
	return pow(tuning.stat_growth, stage_index)
