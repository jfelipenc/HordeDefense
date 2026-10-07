extends SceneTree
## Headless test runner: godot --headless --path . -s res://tests/run_tests.gd
## Runs every tests/test_*.gd. Pass a name after `--` to run one suite, e.g. `-- test_formation`.

var _failures: int = 0
var _passed: int = 0

func _initialize() -> void:
	await process_frame  # let the tree finish starting so _ready runs on added nodes
	var only := OS.get_cmdline_user_args()
	var paths: Array = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and (only.is_empty() or f.get_basename() in only):
			paths.append("res://tests/" + f)
	paths.sort()
	for path in paths:
		var script = load(path)
		if script == null or not script.can_instantiate():
			_failures += 1
			printerr("FAIL: could not load " + path)
			continue
		var suite = script.new()
		if suite == null:
			_failures += 1
			printerr("FAIL: could not instantiate " + path)
			continue
		suite.t = self
		# A suite that failed to compile still instantiates; its test_ methods then abort at the first
		# runtime error (e.g. a missing class) with no check recorded. A suite with no checks is a failure.
		var before := _passed + _failures
		for m in suite.get_method_list():
			if String(m.name).begins_with("test_"):
				await suite.call(m.name)
		if _passed + _failures == before:
			_failures += 1
			printerr("FAIL: no checks ran in " + path)
	print("RESULT: %d passed, %d failed" % [_passed, _failures])
	quit(1 if _failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failures += 1
		printerr("FAIL: " + msg)

func eq(actual, expected, msg: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])
