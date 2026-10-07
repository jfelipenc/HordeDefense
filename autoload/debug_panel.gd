extends CanvasLayer
## Debug panel (M0.6): F1 or a 3-finger tap toggles it. Actions are stubs that
## publish on EventBus / GameState until the systems they drive exist.

var _panel: PanelContainer
var _wave_box: SpinBox
var _section_box: SpinBox
var _fast: bool = false
var _touches := {}

func _ready() -> void:
	layer = 99
	_build_ui()
	_panel.visible = false

func is_open() -> bool:
	return _panel.visible

func toggle() -> void:
	_panel.visible = not _panel.visible

func spawn_wave(wave: int) -> void:
	EventBus.debug_spawn_wave.emit(wave)

func set_section(section: int) -> void:
	GameState.current_section = section

func add_gold(amount: int) -> void:
	GameState.add_gold(amount)

func toggle_speed() -> void:
	_fast = not _fast
	Engine.time_scale = 4.0 if _fast else 1.0

## Called for every touch press/release; opens the panel when a third finger lands.
func track_touch(index: int, pressed: bool) -> void:
	if pressed:
		_touches[index] = true
		if _touches.size() == 3:
			toggle()
	else:
		_touches.erase(index)

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventScreenTouch:
		track_touch(event.index, event.pressed)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(20, 20)
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	box.add_child(_label("DEBUG"))
	_wave_box = _spin(1, 99, 1)
	box.add_child(_row("Wave", _wave_box, "Spawn", func(): spawn_wave(int(_wave_box.value))))
	_section_box = _spin(1, 30, 1)
	box.add_child(_row("Section", _section_box, "Set", func(): set_section(int(_section_box.value))))
	box.add_child(_button("+1000 gold", func(): add_gold(1000)))
	box.add_child(_button("Toggle 4x speed", toggle_speed))

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 36)
	return l

func _spin(lo: int, hi: int, v: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = v
	s.custom_minimum_size = Vector2(200, 80)
	return s

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 36)
	b.custom_minimum_size = Vector2(0, 90)
	b.pressed.connect(cb)
	return b

func _row(label: String, spin: SpinBox, action: String, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(_label(label))
	h.add_child(spin)
	h.add_child(_button(action, cb))
	return h
