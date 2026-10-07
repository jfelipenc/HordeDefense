extends CanvasLayer
## Swaps the active scene behind a fade-to-black. Scenes live under this node's slot.

signal fade_changed(alpha: float)

var current: Node
var _slot: Node
var _veil: ColorRect
var _busy: bool = false

func _ready() -> void:
	layer = 100
	_slot = Node.new()
	_slot.name = "Slot"
	add_child(_slot)
	_veil = ColorRect.new()
	_veil.color = Color.BLACK
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.modulate.a = 0.0
	add_child(_veil)

func fade_alpha() -> float:
	return _veil.modulate.a

func swap_to(path: String, duration: float = 0.25) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0, duration * 0.5)
	if current:
		current.queue_free()
	current = (load(path) as PackedScene).instantiate()
	_slot.add_child(current)
	await _fade(0.0, duration * 0.5)
	_busy = false

func _fade(target: float, duration: float) -> void:
	if duration <= 0.0:
		_set_alpha(target)
		return
	var tw := create_tween()
	tw.tween_method(_set_alpha, _veil.modulate.a, target, duration)
	await tw.finished
	_set_alpha(target)

func _set_alpha(a: float) -> void:
	_veil.modulate.a = a
	fade_changed.emit(a)
