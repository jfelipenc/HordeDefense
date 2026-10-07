extends TestCase

const DIRS := ["autoload", "scenes", "scripts", "resources", "assets", "ui"]

func test_folder_layout_exists() -> void:
	for d in DIRS:
		assert_true(DirAccess.dir_exists_absolute("res://" + d), "missing res://" + d)

func test_readme_lists_each_folder() -> void:
	var f := FileAccess.open("res://README.md", FileAccess.READ)
	assert_true(f != null, "README.md missing")
	if f == null:
		return
	var text := f.get_as_text()
	for d in DIRS:
		assert_true(text.contains("`%s/`" % d), "README does not list %s/" % d)
