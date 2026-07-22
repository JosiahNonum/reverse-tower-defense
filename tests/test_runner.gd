extends SceneTree


const DEFAULT_TEST_ROOTS: Array[String] = [
	"res://tests/unit",
	"res://tests/scenarios",
	"res://tests/contracts",
	"res://tests/integration",
]


func _initialize() -> void:
	var options: Dictionary = _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		push_error("TEST RUNNER ERROR: %s" % options["error"])
		quit(2)
		return

	var test_paths: Array[String] = _resolve_test_paths(options)
	if test_paths.is_empty():
		push_error("TEST RUNNER ERROR: no test scripts matched")
		quit(2)
		return

	var started_at: int = Time.get_ticks_msec()
	var passed: int = 0
	var failed: int = 0
	var assertions: int = 0
	var filter_text: String = options.get("filter", "")

	for test_path: String in test_paths:
		var script: GDScript = load(test_path) as GDScript
		if script == null:
			failed += 1
			push_error("TEST FAIL: %s could not be loaded" % test_path)
			continue

		var method_names: Array[String] = _test_method_names(script)
		for method_name: String in method_names:
			var test_name: String = "%s::%s" % [test_path, method_name]
			if not filter_text.is_empty() and test_name.findn(filter_text) == -1:
				continue

			var result: Dictionary = _run_test(script, method_name)
			assertions += result["assertions"]
			if result["failures"].is_empty():
				passed += 1
				print("TEST PASS: %s (%d ms, %d assertions)" % [
					test_name,
					result["duration_ms"],
					result["assertions"],
				])
			else:
				failed += 1
				push_error("TEST FAIL: %s (%d ms)" % [test_name, result["duration_ms"]])
				for failure: String in result["failures"]:
					push_error("  - %s" % failure)

	var duration_ms: int = Time.get_ticks_msec() - started_at
	if passed + failed == 0:
		push_error("TEST RUNNER ERROR: no test methods matched filter '%s'" % filter_text)
		quit(2)
		return

	print("TEST SUMMARY: %d passed, %d failed, %d assertions in %d ms" % [
		passed,
		failed,
		assertions,
		duration_ms,
	])
	quit(1 if failed > 0 else 0)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {"filter": "", "test_path": ""}
	var index: int = 0
	while index < arguments.size():
		var argument: String = arguments[index]
		if argument != "--filter" and argument != "--test-path":
			return {"error": "unknown argument '%s'" % argument}
		if index + 1 >= arguments.size():
			return {"error": "missing value after '%s'" % argument}
		var value: String = arguments[index + 1]
		if argument == "--filter":
			options["filter"] = value
		else:
			options["test_path"] = value
		index += 2
	return options


func _resolve_test_paths(options: Dictionary) -> Array[String]:
	var explicit_path: String = options.get("test_path", "")
	if not explicit_path.is_empty():
		return [explicit_path]

	var test_paths: Array[String] = []
	for root: String in DEFAULT_TEST_ROOTS:
		_collect_test_paths(root, test_paths)
	test_paths.sort()
	return test_paths


func _collect_test_paths(directory_path: String, test_paths: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()
	for file_name: String in file_names:
		if file_name.ends_with("_test.gd"):
			test_paths.append(directory_path.path_join(file_name))

	var directory_names: PackedStringArray = directory.get_directories()
	directory_names.sort()
	for child_name: String in directory_names:
		_collect_test_paths(directory_path.path_join(child_name), test_paths)


func _test_method_names(script: GDScript) -> Array[String]:
	var instance: RefCounted = script.new() as RefCounted
	var method_names: Array[String] = []
	for method: Dictionary in instance.get_method_list():
		var method_name: String = method.get("name", "")
		if method_name.begins_with("test_"):
			method_names.append(method_name)
	method_names.sort()
	return method_names


func _run_test(script: GDScript, method_name: String) -> Dictionary:
	var instance: RefCounted = script.new() as RefCounted
	instance.call("reset_result")
	instance.call("before_each")
	var started_at: int = Time.get_ticks_msec()
	instance.call(method_name)
	var duration_ms: int = Time.get_ticks_msec() - started_at
	instance.call("after_each")
	return {
		"assertions": instance.call("get_assertion_count"),
		"duration_ms": duration_ms,
		"failures": instance.call("get_failures"),
	}
