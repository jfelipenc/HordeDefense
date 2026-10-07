class_name GateView
extends Node3D
## Visual for one gate: a translucent panel plus a big label, coloured by gate type.

const TYPE_COLORS := {
	GateData.Type.ADDITIVE: Color(0.2, 0.8, 0.3),
	GateData.Type.MULTIPLIER: Color(0.2, 0.55, 1.0),
	GateData.Type.NEGATIVE: Color(0.9, 0.2, 0.2),
	GateData.Type.TYPE: Color(0.7, 0.35, 0.95),
	GateData.Type.BUFF: Color(1.0, 0.75, 0.15),
}

var gate: GateData

func build(p_gate: GateData, width: float) -> void:
	gate = p_gate
	var color: Color = TYPE_COLORS.get(gate.type, Color.WHITE)
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width - 0.3, 3.0, 0.3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = mat
	panel.mesh = box
	panel.position.y = 1.5
	add_child(panel)
	var label := Label3D.new()
	var text := gate.label()
	label.text = text if text.length() <= 5 else text.substr(0, text.find(" ")) + "
" + text.substr(text.find(" ") + 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 160 if text.length() <= 5 else 90
	label.pixel_size = 0.01
	label.outline_size = 32
	label.position.y = 3.8
	add_child(label)
