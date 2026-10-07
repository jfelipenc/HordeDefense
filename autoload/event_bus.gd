extends Node
## Global signal hub. Gameplay emits, HUD / audio / save listen.

@warning_ignore("unused_signal")
signal enemy_killed(enemy_id: StringName, lane: int)
@warning_ignore("unused_signal")
signal wall_damaged(segment: int, amount: float, hp_left: float)
@warning_ignore("unused_signal")
signal wave_cleared(wave: int)
@warning_ignore("unused_signal")
signal battle_ended(victory: bool)
@warning_ignore("unused_signal")
signal gate_passed(gate_id: StringName, count_after: int)
