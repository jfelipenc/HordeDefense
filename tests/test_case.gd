class_name TestCase
extends RefCounted
## Base class for headless tests. Methods named test_* are run by run_tests.gd.

var failures: Array[String] = []


func assert_true(cond: bool, msg: String = "expected true") -> void:
	if not cond:
		failures.append(msg)


func assert_eq(actual, expected, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [msg, str(expected), str(actual)])
