class_name GateData
extends Resource
## One gate option. Pure data: new gates are new .tres files.

enum Type { ADDITIVE, MULTIPLIER, NEGATIVE, TYPE, BUFF }

@export var type: Type = Type.ADDITIVE
## Additive/negative/type: unit count. Multiplier: factor. Buff: percent.
@export var value: float = 1.0
## Only for Type.TYPE (e.g. "archer").
@export var unit_type: StringName = &""
## Only for Type.BUFF (e.g. "fire_damage").
@export var buff_id: StringName = &""

static func make(p_type: Type, p_value: float, p_unit: StringName = &"", p_buff: StringName = &"") -> GateData:
	var g := GateData.new()
	g.type = p_type
	g.value = p_value
	g.unit_type = p_unit
	g.buff_id = p_buff
	return g

func label() -> String:
	var v := int(value)
	match type:
		Type.ADDITIVE:
			return "+%d" % v
		Type.MULTIPLIER:
			return "x%s" % (str(v) if is_equal_approx(value, v) else str(value))
		Type.NEGATIVE:
			return "-%d" % v
		Type.TYPE:
			return "+%d %s" % [v, String(unit_type).capitalize()]
		Type.BUFF:
			return "+%d%% %s" % [v, String(buff_id).capitalize()]
	return ""

func is_bad() -> bool:
	return type == Type.NEGATIVE
