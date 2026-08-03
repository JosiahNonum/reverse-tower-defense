extends "res://tests/framework/test_case.gd"

func test_application_services_do_not_import_presentation_or_ui() -> void:
	var directory := DirAccess.open("res://src/application")
	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()
	for file_name: String in file_names:
		if not file_name.ends_with(".gd"):
			continue
		var source: String = FileAccess.get_file_as_string(
			"res://src/application".path_join(file_name),
		)
		assert_false(source.contains("src/presentation"), file_name)
		assert_false(source.contains("src/ui"), file_name)
		assert_false(source.contains("BattlefieldView"), file_name)
		assert_false(source.contains("extends Control"), file_name)
		assert_false(source.contains("extends PanelContainer"), file_name)

func test_project_has_no_match_state_autoload() -> void:
	var project_source: String = FileAccess.get_file_as_string("res://project.godot")
	assert_false(project_source.contains("[autoload]"))
	assert_false(project_source.contains("MatchState"))
