extends Node3D
## Debug scene (M0.8): a KayKit Knight playing a Rig_Medium_CombatMelee clip beside a Hexagon castle.

const KNIGHT := "res://assets/kaykit/adventurers/Knight.glb"
const CASTLE := "res://assets/kaykit/hexagon/buildings/blue/building_castle_blue.gltf"
const MELEE_PACK := "res://assets/kaykit/animations/Rig_Medium_CombatMelee.glb"
const CLIP := "Melee_1H_Attack_Chop"

var _knight: Node3D
var _castle: Node3D
var _player: AnimationPlayer

func _ready() -> void:
	_knight = (load(KNIGHT) as PackedScene).instantiate()
	_knight.position = Vector3(-1.5, 0, 0)
	add_child(_knight)
	_castle = (load(CASTLE) as PackedScene).instantiate()
	_castle.position = Vector3(3.0, 0, -2.0)
	add_child(_castle)
	_player = AnimationPlayer.new()
	_knight.add_child(_player)
	_player.add_animation_library("", _library_from(MELEE_PACK))
	_player.play(CLIP)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 3.5, 8)
	cam.rotation_degrees = Vector3(-18, 0, 0)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)

func knight_is_animating() -> bool:
	return _player != null and _player.is_playing() and String(_player.current_animation).begins_with("Melee")

func castle_loaded() -> bool:
	return _castle != null and _castle.get_child_count() > 0

## Copies every clip of an animation-pack .glb into a library (looping, so the test scene keeps moving).
func _library_from(path: String) -> AnimationLibrary:
	var pack: Node = (load(path) as PackedScene).instantiate()
	var src: AnimationPlayer = pack.get_node("AnimationPlayer")
	var lib := AnimationLibrary.new()
	for n in src.get_animation_list():
		var a := src.get_animation(n).duplicate() as Animation
		a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(n, a)
	pack.free()
	return lib
