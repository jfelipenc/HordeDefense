class_name Formation
extends RefCounted
## Squad slot layout: a sunflower (golden-angle) spiral. Compact, never stacks,
## and existing slots stay put when units are added or removed at the end.

const GOLDEN_ANGLE := 2.399963229728653

static func slots(count: int, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(count)
	for i in count:
		var r := spacing * 0.9 * sqrt(i + 0.5)
		var a := i * GOLDEN_ANGLE
		out[i] = Vector2(cos(a), sin(a)) * r
	return out
