class_name TestCase
extends RefCounted
## Base class for headless tests. Methods named test_* are run by run_tests.gd.

var failures: Array[String] = []
var checks: int = 0


func assert_true(cond: bool, msg: String = "expected true") -> void:
	checks += 1
	if not cond:
		failures.append(msg)


func assert_eq(actual, expected, msg: String = "") -> void:
	checks += 1
	if actual != expected:
		failures.append("%s expected %s, got %s" % [msg, str(expected), str(actual)])
