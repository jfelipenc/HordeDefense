extends Node

signal enemy_killed
signal wall_damaged(section: int, amount: float)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal phase_cleared(phase: int)
signal regroup_started(phase: int)
signal battle_ended(victory: bool)
## Debug panel requests, handled by the active Battle.
signal debug_spawn_wave(wave: int)
signal debug_skip_phase
