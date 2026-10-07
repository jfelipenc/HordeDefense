extends TestCase

const TEST_SCENE := "res://scenes/test/asset_test.tscn"
const CLIP := "Melee_1H_Attack_Chop"
const IGNORED_EXT := ["import", "uid", "md", "json"]


func _spawn() -> Node:
	var s: Node = (load(TEST_SCENE) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(s)
	return s


func test_knight_castle_and_clip_play_in_test_scene() -> void:
	var s := _spawn()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(s.knight != null and s.castle != null, "knight and castle instanced")
	assert_true(s.player.is_playing(), "clip playing")
	assert_eq(s.player.current_animation, CLIP, "clip name")
	s.queue_free()


func test_clip_tracks_resolve_on_the_knight_skeleton() -> void:
	var s := _spawn()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var anim: Animation = s.player.get_animation(CLIP)
	var base: Node = s.player.get_node(s.player.root_node)
	var bad := 0
	for i in anim.get_track_count():
		if base.get_node_or_null(NodePath(String(anim.track_get_path(i)).get_slice(":", 0))) == null:
			bad += 1
	assert_true(anim.get_track_count() > 0, "clip has tracks")
	assert_eq(bad, 0, "unresolved tracks")
	s.queue_free()


func _asset_files(dir: String, out: Array) -> void:
	for d in DirAccess.get_directories_at(dir):
		_asset_files(dir + "/" + d, out)
	for f in DirAccess.get_files_at(dir):
		if not IGNORED_EXT.has(f.get_extension()) and f != ".gitkeep":
			out.append(dir + "/" + f)


func test_every_imported_file_has_an_inventory_row() -> void:
	var text := FileAccess.get_file_as_string("res://assets/ASSETS.md")
	assert_true(text != "", "ASSETS.md exists")
	var files := []
	_asset_files("res://assets", files)
	assert_true(files.size() > 1000, "assets imported (%d files)" % files.size())
	var missing := []
	for f in files:
		var rel: String = f.trim_prefix("res://assets/")
		if not text.contains("`%s`" % rel):
			missing.append(rel)
	assert_eq(missing.size(), 0, "files without a row, first: " + str(missing.slice(0, 3)))


func test_inventory_separates_kaykit_and_kenney_with_licenses() -> void:
	var text := FileAccess.get_file_as_string("res://assets/ASSETS.md")
	assert_true(text.contains("## KayKit"), "KayKit section")
	assert_true(text.contains("## Kenney"), "Kenney section")
	assert_true(text.contains("CC0"), "license named")


func test_inventory_lists_rig_clip_names() -> void:
	var text := FileAccess.get_file_as_string("res://assets/ASSETS.md")
	for clip in [CLIP, "Melee_Unarmed_Idle", "Walking_A", "Death_A", "Dodge_Forward"]:
		assert_true(text.contains(clip), "clip %s listed" % clip)
	assert_true(text.contains("Rig_Large_Special") and text.contains("Rig_Medium_Tools"), "all rig files listed")
