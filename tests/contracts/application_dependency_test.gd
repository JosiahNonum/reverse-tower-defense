extends "res://tests/framework/test_case.gd"

func test_match_coordinator_does_not_import_presentation_or_ui() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/application/match_coordinator.gd")
	assert_false(source.contains("src/presentation"))
	assert_false(source.contains("src/ui"))
	assert_false(source.contains("BattlefieldView"))
	assert_false(source.contains("Control"))

func test_project_has_no_match_state_autoload() -> void:
	var project_source: String = FileAccess.get_file_as_string("res://project.godot")
	assert_false(project_source.contains("[autoload]"))
	assert_false(project_source.contains("MatchState"))
