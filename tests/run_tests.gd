extends SceneTree
## Headless test runner: godot --headless --path . -s res://tests/run_tests.gd

var _failures: int = 0
var _passed: int = 0

func _initialize() -> void:
	await process_frame  # let the tree finish starting so _ready runs on added nodes
	for path in ["res://tests/test_gate_math.gd", "res://tests/test_resources.gd", "res://tests/test_formation.gd", "res://tests/test_squad.gd", "res://tests/test_gate_run.gd", "res://tests/test_handoff.gd", "res://tests/test_data_classes.gd", "res://tests/test_autoloads.gd", "res://tests/test_scene_swapper.gd", "res://tests/test_debug_panel.gd"]:
		var suite = load(path).new()
		suite.t = self
		for m in suite.get_method_list():
			if String(m.name).begins_with("test_"):
				await suite.call(m.name)
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
