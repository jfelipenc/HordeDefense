extends SceneTree
## Writes assets/clips.json: clip names per Rig_* animation pack, plus skeleton paths for matching.
## Run: godot --headless --path . -s res://tools/list_clips.gd

func _initialize() -> void:
	var out := {}
	var dir := "res://assets/kaykit/animations"
	for f in DirAccess.get_files_at(dir):
		if not f.begins_with("Rig_") or not f.ends_with(".glb"):
			continue
		var root: Node = (load(dir.path_join(f)) as PackedScene).instantiate()
		var ap := _find(root, "AnimationPlayer") as AnimationPlayer
		var names := []
		if ap:
			names = Array(ap.get_animation_list())
			names.sort()
		out[f.get_basename()] = names
		print("%s: %d clips, e.g. %s | skeleton: %s" % [f, names.size(), names.slice(0, 2), root.get_path_to(_find(root, "Skeleton3D")) if _find(root, "Skeleton3D") else "-"])
		root.free()
	var file := FileAccess.open("res://assets/clips.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "  "))
	quit()

func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null
