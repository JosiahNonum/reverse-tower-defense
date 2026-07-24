extends SceneTree


func _initialize() -> void:
	var options: Dictionary = _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		push_error("SCENARIO ERROR: %s" % options["error"])
		quit(2)
		return

	var replay_path: String = options["replay_path"]
	if not FileAccess.file_exists(replay_path):
		push_error("SCENARIO ERROR: replay artifact does not exist")
		quit(2)
		return

	var catalog := ContentCatalog.load_from_directory("res://content")
	var runner := DiagnosticReplayRunner.new()
	var result: DiagnosticReplayResult = runner.replay_json(
		FileAccess.get_file_as_string(replay_path),
		catalog,
	)
	var expected_failure_code: StringName = StringName(options["expected_failure_code"])
	if expected_failure_code != &"":
		if not result.is_success and result.code == expected_failure_code:
			print("SCENARIO EXPECTED FAILURE PASS [%s]: %s" % [result.code, result.message])
			quit(0)
			return
		push_error("SCENARIO ERROR: expected failure %s but received %s" % [
			expected_failure_code,
			result.code,
		])
		quit(1)
		return

	if not result.is_success:
		push_error("SCENARIO FAIL [%s]: %s" % [result.code, result.message])
		quit(1)
		return

	print("SCENARIO SUMMARY: %s" % JSON.stringify(result.summary.to_dictionary()))
	print("SCENARIO PASS: diagnostic replay matched its checked result")
	quit(0)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {
		"replay_path": "",
		"expected_failure_code": "",
	}
	var index: int = 0
	while index < arguments.size():
		var argument: String = arguments[index]
		if argument != "--replay" and argument != "--expect-failure-code":
			return {"error": "unknown argument '%s'" % argument}
		if index + 1 >= arguments.size():
			return {"error": "missing value after '%s'" % argument}
		if argument == "--replay":
			options["replay_path"] = arguments[index + 1]
		else:
			options["expected_failure_code"] = arguments[index + 1]
		index += 2
	if String(options["replay_path"]).is_empty():
		return {"error": "--replay is required"}
	return options
