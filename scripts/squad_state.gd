class_name SquadState
extends RefCounted
## Pure squad model: unit counts per type plus accumulated buffs. No nodes, fully testable.

const FRONT_TYPE := "soldier"

var counts: Dictionary = {}
var buffs: Dictionary = {}

func _init(p_counts: Dictionary = {}) -> void:
	counts = p_counts.duplicate()

func total() -> int:
	var n := 0
	for c in counts.values():
		n += c
	return n

func apply_gate(gate: GateData) -> void:
	match gate.type:
		GateData.Type.ADDITIVE:
			_add(FRONT_TYPE, int(gate.value))
		GateData.Type.MULTIPLIER:
			for k in counts.keys():
				counts[k] = roundi(counts[k] * gate.value)
		GateData.Type.NEGATIVE:
			lose(int(gate.value))
		GateData.Type.TYPE:
			_add(String(gate.unit_type), int(gate.value))
		GateData.Type.BUFF:
			buffs[String(gate.buff_id)] = buffs.get(String(gate.buff_id), 0.0) + gate.value

## Removes up to n units (front type first), never dropping the squad below 1.
func lose(n: int) -> void:
	var remaining := mini(n, total() - 1)
	for k in _loss_order():
		if remaining <= 0:
			break
		var take := mini(counts[k], remaining)
		counts[k] -= take
		remaining -= take
		if counts[k] == 0:
			counts.erase(k)

## Trims to cap keeping type proportions; returns the number of units removed.
func clamp_to_cap(cap: int) -> int:
	var before := total()
	if before <= cap:
		return 0
	var kept := {}
	var kept_total := 0
	for k in counts.keys():
		kept[k] = int(counts[k] * cap / float(before))
		kept_total += kept[k]
	# Hand rounding leftovers back, front type first.
	for k in _loss_order():
		if kept_total >= cap:
			break
		kept[k] += 1
		kept_total += 1
	counts = kept
	for k in counts.keys():
		if counts[k] == 0:
			counts.erase(k)
	return before - cap

func _add(type: String, n: int) -> void:
	counts[type] = counts.get(type, 0) + n

## Soldiers first, then the other types in insertion order.
func _loss_order() -> Array:
	var order: Array = []
	if counts.has(FRONT_TYPE):
		order.append(FRONT_TYPE)
	for k in counts.keys():
		if k != FRONT_TYPE:
			order.append(k)
	return order
