class_name UnitRole
extends RefCounted
## The three corners of the counter triangle, plus NONE for units outside it.

enum Kind { INFANTRY, CAVALRY, ARCHERS, NONE }

const TROOP_KINDS := [Kind.INFANTRY, Kind.CAVALRY, Kind.ARCHERS]
