extends Control
## Stand-in for the M2 wall hold: shows what the gate run handed over.

signal restart_requested

var received_count: int = -1
var received_composition: Dictionary = {}
var received_buffs: Dictionary = {}

@onready var _text: Label = $Text

func show_result(count: int, buffs: Dictionary, composition: Dictionary, gold: int) -> void:
	received_count = count
	received_buffs = buffs
	received_composition = composition
	var lines := ["Wall hold (placeholder)", "", "Army: %d" % count]
	for type in composition.keys():
		lines.append("  %s: %d" % [String(type).capitalize(), composition[type]])
	for id in buffs.keys():
		lines.append("Buff %s: +%d%%" % [String(id).capitalize(), buffs[id]])
	lines.append("")
	lines.append("Gold: %d" % gold)
	_text.text = "\n".join(lines)

func _on_again_pressed() -> void:
	restart_requested.emit()
