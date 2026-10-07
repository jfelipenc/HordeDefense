extends Node

signal enemy_killed
signal wall_damaged
signal wave_cleared
signal battle_ended(victory: bool)
signal gate_passed(gate: GateData)
signal gate_run_finished(count: int, buffs: Dictionary, composition: Dictionary)
