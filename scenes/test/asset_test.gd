extends Node3D
## Import smoke test: Knight.glb plus a Rig_Medium_CombatMelee clip, and a Hexagon castle.

const CLIP := "Melee_1H_Attack_Chop"

var knight: Node3D
var castle: Node3D
var player: AnimationPlayer


func _ready() -> void:
	knight = (load("res://assets/kaykit/adventurers/Knight.glb") as PackedScene).instantiate()
	add_child(knight)
	castle = (load("res://assets/kaykit/hexagon/buildings/building_castle_blue.gltf") as PackedScene).instantiate()
	castle.position = Vector3(5, 0, 0)
	add_child(castle)
	_attach_clips(knight, "res://assets/kaykit/animations/rig_medium/Rig_Medium_CombatMelee.glb")
	player.play(CLIP)
	player.get_animation(CLIP).loop_mode = Animation.LOOP_LINEAR
	_add_view()


## The animation files share Rig_Medium's skeleton, so their libraries drive any Medium-rig character.
func _attach_clips(target: Node3D, anim_scene_path: String) -> void:
	var src: Node = (load(anim_scene_path) as PackedScene).instantiate()
	var src_player: AnimationPlayer = src.find_children("*", "AnimationPlayer", true, false)[0]
	player = AnimationPlayer.new()
	player.name = "ClipPlayer"
	target.add_child(player)
	player.root_node = NodePath("..")
	player.add_animation_library("", src_player.get_animation_library(""))
	src.free()


func _add_view() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(2.5, 4, 8)
	cam.look_at(Vector3(2.5, 1, 0))
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-50, -30, 0)
