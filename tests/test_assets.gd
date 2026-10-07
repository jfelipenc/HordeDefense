extends RefCounted

var t

const DOC := "res://assets/ASSETS.md"
const IGNORED_EXT := ["import", "uid", "md", "json"]

func _walk(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.get_extension() in IGNORED_EXT:
			continue
		out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(d), out)

func test_every_imported_file_has_a_row_in_assets_md() -> void:
	t.check(FileAccess.file_exists(DOC), "ASSETS.md exists")
	if not FileAccess.file_exists(DOC):
		return
	var doc := FileAccess.get_file_as_string(DOC)
	var files: Array = []
	_walk("res://assets", files)
	t.check(files.size() > 100, "assets imported (%d files)" % files.size())
	var missing := 0
	for f in files:
		if not doc.contains("`%s`" % f.trim_prefix("res://assets/")):
			missing += 1
			if missing <= 5:
				printerr("not in ASSETS.md: " + f)
	t.eq(missing, 0, "files missing from ASSETS.md")

func test_kaykit_and_kenney_listed_separately_with_license() -> void:
	var doc := FileAccess.get_file_as_string(DOC)
	t.check(doc.contains("## KayKit"), "KayKit section")
	t.check(doc.contains("## Kenney"), "Kenney section")
	t.check(doc.contains("CC0"), "license named")

func test_core_models_load() -> void:
	for p in ["kaykit/adventurers/Knight.glb", "kaykit/skeletons/Skeleton_Minion.glb",
			"kaykit/hexagon/buildings/blue/building_castle_blue.gltf",
			"kaykit/animations/Rig_Medium_CombatMelee.glb"]:
		var s := load("res://assets/" + p) as PackedScene
		t.check(s != null, p + " loads as a scene")

func test_clip_names_are_documented() -> void:
	var doc := FileAccess.get_file_as_string(DOC)
	var scene := load("res://assets/kaykit/animations/Rig_Medium_CombatMelee.glb") as PackedScene
	var root := scene.instantiate()
	var ap := _find_player(root)
	t.check(ap != null, "melee pack has an AnimationPlayer")
	if ap:
		var names := ap.get_animation_list()
		t.check(names.size() > 0, "melee pack has clips")
		for n in names:
			t.check(doc.contains("`%s`" % n), "clip %s documented" % n)
	root.free()

func test_asset_test_scene_plays_a_melee_clip_on_the_knight() -> void:
	var scene := load("res://scenes/debug/asset_test.tscn") as PackedScene
	t.check(scene != null, "asset test scene exists")
	if scene == null:
		return
	var n := scene.instantiate()
	t.root.add_child(n)
	await t.process_frame
	t.check(n.knight_is_animating(), "knight plays a CombatMelee clip")
	t.check(n.castle_loaded(), "castle present")
	n.queue_free()

func _find_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_player(c)
		if r:
			return r
	return null
