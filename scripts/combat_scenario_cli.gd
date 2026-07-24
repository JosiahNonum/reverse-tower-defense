extends SceneTree


func _initialize() -> void:
	var scenario_path: String = _scenario_path(OS.get_cmdline_user_args())
	if scenario_path.is_empty():
		push_error("COMBAT SCENARIO ERROR: --scenario is required")
		quit(2)
		return
	if not FileAccess.file_exists(scenario_path):
		push_error("COMBAT SCENARIO ERROR: artifact does not exist")
		quit(2)
		return

	var catalog := ContentCatalog.load_from_directory("res://content")
	var result: CombatScenarioResult = CombatScenarioRunner.new().run_json(
		FileAccess.get_file_as_string(scenario_path),
		catalog,
	)
	if result.summary != null:
		print("COMBAT SCENARIO SUMMARY: %s" % JSON.stringify(
			result.summary.to_dictionary(),
		))
	if not result.is_success:
		push_error("COMBAT SCENARIO FAIL [%s]: %s" % [result.code, result.message])
		quit(1)
		return
	print("COMBAT SCENARIO PASS: semantic summary matched")
	quit(0)


func _scenario_path(arguments: PackedStringArray) -> String:
	if arguments.size() != 2 or arguments[0] != "--scenario":
		return ""
	return arguments[1]
