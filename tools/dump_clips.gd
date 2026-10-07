extends SceneTree
## Writes animation clip names of every Rig_* animation file and the character AnimationPlayers.
## Run: godot --headless --path . -s tools/dump_clips.gd

const SOURCES := {
	"rig_medium": "res://assets/kaykit/animations/rig_medium",
	"rig_large": "res://assets/kaykit/animations/rig_large",
}


func _initialize() -> void:
	var out := {}
	for key in SOURCES:
		var files := {}
		for f in DirAccess.get_files_at(SOURCES[key]):
			if not f.ends_with(".glb"):
				continue
			var scene: Node = (load(SOURCES[key] + "/" + f) as PackedScene).instantiate()
			var names: Array = []
			for ap in scene.find_children("*", "AnimationPlayer", true, false):
				for lib in (ap as AnimationPlayer).get_animation_library_list():
					for a in (ap as AnimationPlayer).get_animation_library(lib).get_animation_list():
						names.append(a)
			names.sort()
			files[f.get_basename()] = names
			scene.free()
		out[key] = files
	var fa := FileAccess.open("res://assets/animation_clips.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(out, "  "))
	fa.close()
	print("wrote assets/animation_clips.json")
	quit()
