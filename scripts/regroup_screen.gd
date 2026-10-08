class_name RegroupScreen
extends CanvasLayer
## The pre-set-formation screen (design spec sections 3, 4 and 7). Shown at the start of a battle
## and after each milestone wave: troop ratio, how each kind is shared across the wall sections,
## the six tower slots, a scout preview of the next phase and a Ready button.
## Plain Controls only; art comes later.

signal ready_pressed

const SECTION_NAMES := ["Left", "Center", "Right"]
const KIND_NAMES := ["Infantry", "Cavalry", "Archers"]
const SECTION_LABEL_WIDTH := 150.0
const SHARE_SLIDER_WIDTH := 170.0
const MILESTONE_NAMES := {
	WaveData.Milestone.FLANK: "Flank",
	WaveData.Milestone.KEEP_STRIKE: "Keep strike",
	WaveData.Milestone.SIEGE: "Siege",
	WaveData.Milestone.BOSS: "Boss",
}

var battle: Battle
## Tower choices: index 0 is "no tower".
var tower_options: Array = [null]

var _root: Control
var _title: Label
var _countdown: Label
var _preview: Label
var _summary: Label
var _ratio_sliders: Array[HSlider] = []
## _share_sliders[section][kind]
var _share_sliders: Array = [[], [], []]
## _tower_pickers[section][slot]
var _tower_pickers: Array = [[], [], []]
## The "Infantry / Cavalry / Archers" captions over the share sliders.
var _kind_header_labels: Array[Label] = []
var _first_open := true

func _ready() -> void:
	layer = 20
	for id in ["arrow_tower", "crossbow_tower", "cannon_tower"]:
		tower_options.append(load("res://resources/towers/%s.tres" % id))
	_build()
	visible = false

func _process(_delta: float) -> void:
	if visible and battle != null:
		_countdown.text = "Starting in %d s" % ceili(battle.phase.timer)
		_summary.text = _summary_text()

func open() -> void:
	var p := battle.preview_next_phase()
	if _first_open:
		_first_open = false
		_load_sliders(Formation.recommended(p.roles))
	_title.text = "Regroup - Phase %d" % p.phase
	_preview.text = preview_text(p)
	visible = true

func close() -> void:
	visible = false

## The formation the sliders currently describe.
func build_formation() -> Formation:
	var f := Formation.new()
	for k in 3:
		f.ratio[k] = _ratio_sliders[k].value
		for s in 3:
			f.shares[k][s] = _share_sliders[s][k].value
	return f

func set_ratio(kind: int, value: float) -> void:
	_ratio_sliders[kind].value = value

func set_share(section: int, kind: int, value: float) -> void:
	_share_sliders[section][kind].value = value

func set_tower_choice(section: int, slot: int, option_index: int) -> void:
	_tower_pickers[section][slot].select(option_index)

func recommend() -> void:
	_load_sliders(Formation.recommended(battle.preview_next_phase().roles))

## Applies the formation and towers to the battle and starts the next wave.
func press_ready() -> void:
	battle.apply_formation(build_formation())
	for s in 3:
		for slot in 2:
			battle.set_tower(s, slot, tower_options[_tower_pickers[s][slot].selected])
	battle.ready()
	ready_pressed.emit()

func preview_text(p: Dictionary) -> String:
	var lines: Array[String] = ["Scouts report (phase %d):" % p.phase]
	var mix: Array[String] = []
	for id in p.mix:
		mix.append("%s x%d" % [String(id).capitalize(), p.mix[id]])
	lines.append(", ".join(mix) if not mix.is_empty() else "Nothing")
	for w in p.waves:
		if w.milestone != WaveData.Milestone.NONE:
			var extra := " (from the %s)" % SECTION_NAMES[w.flank_lane].to_lower() if w.milestone == WaveData.Milestone.FLANK else ""
			lines.append("Wave %d: %s%s" % [w.wave, MILESTONE_NAMES[w.milestone], extra])
	return "\n".join(lines)

# --- internals ----------------------------------------------------------------

func _summary_text() -> String:
	var counts := build_formation().counts(battle.state.pool.total())
	var parts: Array[String] = []
	for s in 3:
		parts.append("%s: I %d C %d A %d" % [SECTION_NAMES[s], counts[s][0], counts[s][1], counts[s][2]])
	return "\n".join(parts)

func _load_sliders(f: Formation) -> void:
	for k in 3:
		_ratio_sliders[k].value = snappedf(f.ratio[k] * 10.0, 0.5)
		for s in 3:
			_share_sliders[s][k].value = f.shares[k][s]

func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	_root.add_theme_stylebox_override("panel", bg)
	add_child(_root)
	var box := VBoxContainer.new()
	_root.add_child(box)
	_title = _label("Regroup", 56)
	box.add_child(_title)
	_countdown = _label("", 40)
	box.add_child(_countdown)
	_preview = _label("", 34)
	box.add_child(_preview)
	box.add_child(_label("Troop ratio", 40))
	for k in 3:
		_ratio_sliders.append(_slider_row(box, KIND_NAMES[k], 5.0 if k == 0 else (2.0 if k == 1 else 3.0), 10.0, 0.5))
	box.add_child(_label("Where each kind stands", 40))
	var header := HBoxContainer.new()
	box.add_child(header)
	var corner := _label("", 28)
	corner.custom_minimum_size = Vector2(SECTION_LABEL_WIDTH, 0)
	header.add_child(corner)
	for k in 3:
		var cap := _label(KIND_NAMES[k], 28)
		cap.custom_minimum_size = Vector2(SHARE_SLIDER_WIDTH, 0)
		header.add_child(cap)
		_kind_header_labels.append(cap)
	header.add_child(_label("Towers", 28))
	for s in 3:
		var row := HBoxContainer.new()
		box.add_child(row)
		var section_label := _label(SECTION_NAMES[s], 34)
		section_label.custom_minimum_size = Vector2(SECTION_LABEL_WIDTH, 0)
		row.add_child(section_label)
		for k in 3:
			var slider := _make_slider(1.0, 4.0, 1.0)
			slider.custom_minimum_size = Vector2(SHARE_SLIDER_WIDTH, 60)
			row.add_child(slider)
			_share_sliders[s].append(slider)
		var towers := HBoxContainer.new()
		for slot in 2:
			var picker := OptionButton.new()
			picker.add_theme_font_size_override("font_size", 30)
			for opt in ["No tower", "Arrow", "Crossbow", "Cannon"]:
				picker.add_item(opt)
			towers.add_child(picker)
			_tower_pickers[s].append(picker)
		row.add_child(towers)
	_summary = _label("", 32)
	box.add_child(_summary)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var rec := Button.new()
	rec.text = "Recommended"
	rec.add_theme_font_size_override("font_size", 44)
	rec.custom_minimum_size = Vector2(0, 110)
	rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rec.pressed.connect(recommend)
	buttons.add_child(rec)
	var go := Button.new()
	go.text = "Ready"
	go.add_theme_font_size_override("font_size", 56)
	go.custom_minimum_size = Vector2(0, 110)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(press_ready)
	buttons.add_child(go)

func _slider_row(parent: Control, text: String, value: float, max_value: float, step: float) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := _label(text, 36)
	name_label.custom_minimum_size = Vector2(240, 0)
	row.add_child(name_label)
	var slider := _make_slider(value, max_value, step)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return slider

func _make_slider(value: float, max_value: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = max_value
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 60)
	return s

func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
