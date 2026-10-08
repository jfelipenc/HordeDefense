class_name Formation
extends RefCounted
## What the player sets at a regroup: the ratio of the three troop kinds, and for each kind
## how it is shared across the three wall sections. Both are weights; counts() normalises them.

## ratio[kind]: Infantry, Cavalry, Archers.
var ratio: Array[float] = [5.0, 2.0, 3.0]
## shares[kind][section]: left, center, right.
var shares: Array = [[1.0, 1.0, 1.0], [1.0, 1.0, 1.0], [1.0, 1.0, 1.0]]

## Splits `total` troops into counts[section][kind]. Always sums to exactly `total`.
func counts(total: int) -> Array:
	var per_kind := apportion(total, ratio)
	var out: Array = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
	for k in 3:
		var per_section := apportion(per_kind[k], shares[k])
		for s in 3:
			out[s][k] = per_section[s]
	return out

## The game's suggested formation for an enemy mix ({UnitRole.Kind: count}): half the default
## ratio, half weighted toward the kinds that counter what is coming.
static func recommended(enemy_mix: Dictionary) -> Formation:
	var f := Formation.new()
	var want: Array[float] = [0.0, 0.0, 0.0]
	var total := 0.0
	for role in enemy_mix:
		var counter := Triangle.counter_of(role)
		if counter != UnitRole.Kind.NONE:
			want[counter] += float(enemy_mix[role])
			total += float(enemy_mix[role])
	if total <= 0.0:
		return f
	for k in 3:
		f.ratio[k] = f.ratio[k] / 10.0 * 0.5 + want[k] / total * 0.5
	return f

## Largest-remainder split of `total` by `weights` into ints that sum to `total`.
## Negative weights count as 0; all-zero weights split evenly; ties go to the lower index.
static func apportion(total: int, weights: Array) -> Array[int]:
	var n := weights.size()
	var out: Array[int] = []
	out.resize(n)
	out.fill(0)
	if n == 0 or total <= 0:
		return out
	var w: Array[float] = []
	var sum := 0.0
	for x in weights:
		var v := maxf(float(x), 0.0)
		w.append(v)
		sum += v
	if sum <= 0.0:
		w.fill(1.0)
		sum = float(n)
	var rem: Array[float] = []
	var given := 0
	for i in n:
		var exact := float(total) * w[i] / sum
		out[i] = int(floor(exact))
		rem.append(exact - out[i])
		given += out[i]
	var left := total - given
	while left > 0:
		var best := 0
		for i in n:
			if rem[i] > rem[best]:
				best = i
		out[best] += 1
		rem[best] = -1.0
		left -= 1
	return out
