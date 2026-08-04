extends "res://tests/framework/test_case.gd"

const BalanceMatrixRunnerScript = preload("res://src/application/balance_matrix_runner.gd")


func test_balance_matrix_is_repeatable_and_covers_shapes_routes_spacings_and_difficulties() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var first: Dictionary = BalanceMatrixRunnerScript.new().run(catalog, catalog.rules[0])
	var second: Dictionary = BalanceMatrixRunnerScript.new().run(catalog, catalog.rules[0])
	assert_equal(first["case_count"], 72)
	assert_equal(first, second)
	for row: Dictionary in first["rows"]:
		assert_true(row["outcome"] in ["player_win", "defender_win"])
		assert_true(row["trace_count"] >= 1)
