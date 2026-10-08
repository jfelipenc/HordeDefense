class_name TroopPool
extends RefCounted
## Living troops per wall section and kind, plus this phase's losses (for healing at regroup).
## counts[section][kind] and lost[section][kind] are ints; kind is a UnitRole.Kind (0-2).

var counts: Array = []
var lost: Array = []

func _init(initial: Array = []) -> void:
	counts = _copy(initial) if not initial.is_empty() else _zeros()
	lost = _zeros()

func count(section: int, kind: int) -> int:
	return counts[section][kind]

func section_total(section: int) -> int:
	var n := 0
	for k in 3:
		n += counts[section][k]
	return n

func kind_total(kind: int) -> int:
	var n := 0
	for s in 3:
		n += counts[s][kind]
	return n

func total() -> int:
	return section_total(0) + section_total(1) + section_total(2)

## Removes up to n troops; returns how many actually died.
func take_losses(section: int, kind: int, n: int) -> int:
	var dead := clampi(n, 0, counts[section][kind])
	counts[section][kind] -= dead
	lost[section][kind] += dead
	return dead

## Returns `share` of this phase's losses to the living (rounded per cell) and clears the loss log.
## Returns the number of troops healed.
func heal(share: float) -> int:
	var healed := 0
	for s in 3:
		for k in 3:
			var back := roundi(lost[s][k] * share)
			counts[s][k] += back
			healed += back
			lost[s][k] = 0
	return healed

## Replaces the living counts (a new formation). The loss log is cleared.
func reset_to(new_counts: Array) -> void:
	counts = _copy(new_counts)
	lost = _zeros()

static func _zeros() -> Array:
	return [[0, 0, 0], [0, 0, 0], [0, 0, 0]]

static func _copy(src: Array) -> Array:
	var out: Array = []
	for row in src:
		out.append(row.duplicate())
	return out
