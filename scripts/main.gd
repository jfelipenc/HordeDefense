extends Node
## Root scene. Owns the active screen and swaps screens behind a black fade.

@export var fade_time: float = 0.25
@export_file("*.tscn") var start_scene: String = ""

var current_scene: Node = null
var current_scene_path: String = ""

@onready var _holder: Node = $SceneHolder
@onready var _fade: ColorRect = $FadeLayer/Fade

var _swapping := false


func _ready() -> void:
	_fade.color.a = 0.0
	if start_scene != "":
		swap_to(start_scene)


func fade_alpha() -> float:
	return _fade.color.a


func swap_to(path: String) -> void:
	if _swapping:
		push_warning("swap_to(%s) ignored: swap in progress" % path)
		return
	_swapping = true
	await _fade_to(1.0)
	if current_scene != null:
		_holder.remove_child(current_scene)
		current_scene.queue_free()
	current_scene = (load(path) as PackedScene).instantiate()
	current_scene_path = path
	_holder.add_child(current_scene)
	await _fade_to(0.0)
	_swapping = false


func _fade_to(alpha: float) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, fade_time)
	await tw.finished
