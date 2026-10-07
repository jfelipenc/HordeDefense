extends SceneTree
## Run: godot --headless --path . -s tests/run_tests.gd
## Optional filter: ... -- test_project_settings

func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			if filter == "" or f.contains(filter):
				files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		for m in script.get_script_method_list():
			if not String(m.name).begins_with("test_"):
				continue
			var t: TestCase = script.new()
			t.call(m.name)
			total += 1
			if t.failures.is_empty():
				print("PASS  %s::%s" % [f, m.name])
			else:
				failed += 1
				print("FAIL  %s::%s" % [f, m.name])
				for msg in t.failures:
					print("      - ", msg)
	print("%d/%d passed" % [total - failed, total])
	quit(1 if failed > 0 or total == 0 else 0)
