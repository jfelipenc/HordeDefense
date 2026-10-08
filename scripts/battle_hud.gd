class_name BattleHud
extends CanvasLayer
## Battle HUD (design spec section 11): wave counter, a phase bar with the milestone waves marked,
## troop counts, Town Center HP, the hero skill button and one cavalry sortie button per section.
## Reads the Battle every frame; the buttons call Battle.use_* and nothing else.

const SECTION_NAMES := ["Left", "Center", "Right"]
const PHASE_COLORS := [Color(0.35, 0.55, 0.35), Color(0.55, 0.5, 0.3), Color(0.6, 0.4, 0.3), Color(0.6, 0.25, 0.25)]

var battle: Battle

var _wave_label: Label
var _horde_label: Label
var _phase_panels: Array[PanelContainer] = []
var _tc_bar: ProgressBar
var _hero_button: Button
var _sortie_buttons: Array[Button] = []
var _wall_bars: Array[ProgressBar] = []
var _troop_labels: Array[Label] = []

func _ready() -> void:
	layer = 10
	_build()
	refresh()

func _process(_delta: float) -> void:
	refresh()

func wave_text() -> String:
	var p := battle.phase
	return "Wave %d/%d" % [maxi(p.wave, 1), battle.tuning.waves_per_battle]

## "Phase 2/4" while fighting; "Regroup" between phases.
func phase_text() -> String:
	if battle.phase.state == PhaseMachine.State.REGROUP:
		return "Regroup"
	return "Phase %d/4" % battle.phase.current_phase()

func hero_text() -> String:
	var st := battle.state
	if st.hero == null:
		return "No hero"
	if st.hero_cooldown > 0.0:
		return "%s %.0f" % [st.hero.skill_name, ceilf(st.hero_cooldown)]
	return st.hero.skill_name

## Index (0-3) of the phase panel highlighted right now.
func active_phase_index() -> int:
	return battle.phase.current_phase() - 1

func refresh() -> void:
	if battle == null:
		return
	var st := battle.state
	_wave_label.text = "%s   %s" % [wave_text(), phase_text()]
	_horde_label.text = "Horde: %d" % battle.horde.count()
	for i in _phase_panels.size():
		_phase_panels[i].modulate = Color.WHITE if i == active_phase_index() else Color(1, 1, 1, 0.45)
	_tc_bar.max_value = st.town_center_max
	_tc_bar.value = st.town_center_hp
	var assault := battle.phase.state == PhaseMachine.State.ASSAULT
	_hero_button.text = hero_text()
	_hero_button.disabled = not assault or st.hero == null or st.hero_cooldown > 0.0
	for s in 3:
		_wall_bars[s].max_value = st.wall_max[s]
		_wall_bars[s].value = st.wall_hp[s]
		_troop_labels[s].text = "%s  %d" % [SECTION_NAMES[s], st.pool.section_total(s)]
		_sortie_buttons[s].disabled = not assault or st.sortie_cooldown > 0.0 or st.pool.count(s, UnitRole.Kind.CAVALRY) <= 0
		_sortie_buttons[s].text = "Sortie" if st.sortie_left[s] <= 0.0 else "Charging!"

func press_hero() -> bool:
	var lane := battle.horde.busiest_lane()
	return lane >= 0 and battle.use_hero_skill(lane)

func press_sortie(section: int) -> bool:
	return battle.use_sortie(section)

# --- building ---------------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	_wave_label = _label(54)
	top.add_child(_wave_label)
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar)
	for i in 4:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = PHASE_COLORS[i]
		panel.add_theme_stylebox_override("panel", style)
		var mark := _label(28)
		mark.text = "%d: %s" % [(i + 1) * 5, ["Flank", "Keep strike", "Siege", "Boss"][i]]
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(mark)
		bar.add_child(panel)
		_phase_panels.append(panel)
	_horde_label = _label(40)
	top.add_child(_horde_label)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	_hero_button = _button("Hero", press_hero, 56)
	bottom.add_child(_hero_button)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(row)
	for s in 3:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var troops := _label(36)
		col.add_child(troops)
		_troop_labels.append(troops)
		var wall := ProgressBar.new()
		wall.custom_minimum_size = Vector2(0, 28)
		wall.show_percentage = false
		col.add_child(wall)
		_wall_bars.append(wall)
		var sortie := _button("Sortie", press_sortie.bind(s), 40)
		col.add_child(sortie)
		_sortie_buttons.append(sortie)
		row.add_child(col)
	_tc_bar = ProgressBar.new()
	_tc_bar.custom_minimum_size = Vector2(0, 40)
	_tc_bar.show_percentage = false
	bottom.add_child(_tc_bar)

func _label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _button(text: String, cb: Callable, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(0, 100)
	b.pressed.connect(cb)
	return b
