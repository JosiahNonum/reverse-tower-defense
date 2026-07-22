extends "res://tests/framework/test_case.gd"


func test_intentional_failure_proves_nonzero_exit() -> void:
	assert_true(false, "intentional failure fixture")
