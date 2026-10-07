extends CanvasLayer
## Developer panel. F1 or a three-finger tap toggles it. Wave spawning is a stub until M2.7.

signal wave_spawn_requested(wave: int)

const SPEED_FAST := 4.0

var _open := false
var _fingers := {}
var _root: PanelContainer
var _wave_box: SpinBox
var _section_box: SpinBox
var _gold_box: SpinBox
var _speed_button: Button


func _ready() -> void:
	_build_ui()
	_set_open(false)


func _input(event: InputEvent) -> void:
	handle_input(event)


func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_fingers[event.index] = true
			if _fingers.size() == 3:
				toggle()
		else:
			_fingers.erase(event.index)


func is_open() -> bool:
	return _open


func toggle() -> void:
	_set_open(not _open)


func spawn_wave(wave: int) -> void:
	print("[debug] spawn wave ", wave, " (stub)")
	wave_spawn_requested.emit(wave)


func set_section(index: int) -> void:
	GameState.set_section(index)


func add_gold(amount: int) -> void:
	GameState.add_gold(amount)


func toggle_speed() -> void:
	Engine.time_scale = 1.0 if Engine.time_scale == SPEED_FAST else SPEED_FAST
	if _speed_button != null:
		_speed_button.text = "Speed: %dx" % int(Engine.time_scale)


func emit_test_signals() -> void:
	EventBus.enemy_killed.emit(&"grunt", 1)
	EventBus.wall_damaged.emit(1, 5.0, 95.0)
	EventBus.wave_cleared.emit(1)
	EventBus.battle_ended.emit(true)
	EventBus.gate_passed.emit(&"add_8", 28)


func _set_open(value: bool) -> void:
	_open = value
	if _root != null:
		_root.visible = value


func _build_ui() -> void:
	_root = PanelContainer.new()
	_root.position = Vector2(20, 20)
	add_child(_root)
	var box := VBoxContainer.new()
	_root.add_child(box)
	var title := Label.new()
	title.text = "DEBUG"
	box.add_child(title)
	_wave_box = _row(box, "Wave", "Spawn", func(): spawn_wave(int(_wave_box.value)), 0, 4)
	_section_box = _row(box, "Section", "Set", func(): set_section(int(_section_box.value)), 0, 29)
	_gold_box = _row(box, "Gold", "Add", func(): add_gold(int(_gold_box.value)), 0, 100000, 100)
	_speed_button = Button.new()
	_speed_button.text = "Speed: 1x"
	_speed_button.pressed.connect(toggle_speed)
	box.add_child(_speed_button)
	var emit_button := Button.new()
	emit_button.text = "Emit test signals"
	emit_button.pressed.connect(emit_test_signals)
	box.add_child(emit_button)


func _row(parent: Control, label: String, button_text: String, on_press: Callable, min_v: int, max_v: int, value: int = 0) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 90
	row.add_child(l)
	var spin := SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.value = value
	row.add_child(spin)
	var b := Button.new()
	b.text = button_text
	b.pressed.connect(on_press)
	row.add_child(b)
	return spin
