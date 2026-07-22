extends "res://tests/framework/test_case.gd"


func test_assertions_record_successes_without_failures() -> void:
	assert_true(true)
	assert_false(false)
	assert_equal(20, 20)
	assert_not_equal("rules", "cosmetic")
	assert_equal(get_assertion_count(), 4)
