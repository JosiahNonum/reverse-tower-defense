class_name TestCase
extends RefCounted


var _assertion_count: int = 0
var _failures: Array[String] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func reset_result() -> void:
	_assertion_count = 0
	_failures.clear()


func assert_true(condition: bool, message: String = "") -> void:
	_assertion_count += 1
	if condition:
		return
	_record_failure(message if not message.is_empty() else "expected true, received false")


func assert_false(condition: bool, message: String = "") -> void:
	_assertion_count += 1
	if not condition:
		return
	_record_failure(message if not message.is_empty() else "expected false, received true")


func assert_equal(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertion_count += 1
	if actual == expected:
		return
	var detail: String = "expected %s, received %s" % [str(expected), str(actual)]
	_record_failure(message + (": " if not message.is_empty() else "") + detail)


func assert_not_equal(actual: Variant, unexpected: Variant, message: String = "") -> void:
	_assertion_count += 1
	if actual != unexpected:
		return
	var detail: String = "did not expect %s" % str(unexpected)
	_record_failure(message + (": " if not message.is_empty() else "") + detail)


func get_assertion_count() -> int:
	return _assertion_count


func get_failures() -> Array[String]:
	return _failures.duplicate()


func _record_failure(message: String) -> void:
	_failures.append(message)
