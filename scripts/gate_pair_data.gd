class_name GatePairData
extends Resource
## Two gates side by side at one distance along the road. The squad passes through exactly one.

@export var distance: float = 0.0
@export var left: GateData
@export var right: GateData

## x is the squad's lateral position at the pair; left of the road centre picks `left`.
func pick(x: float) -> GateData:
	return left if x < 0.0 else right
