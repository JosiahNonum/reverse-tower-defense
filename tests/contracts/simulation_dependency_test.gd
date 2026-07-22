extends "res://tests/framework/test_case.gd"


const SIMULATION_ROOT: String = "res://src/simulation"
const FORBIDDEN_TEXT: Array[String] = [
	"extends Node",
	"res://src/presentation",
	"res://src/ui",
	"src/presentation",
	"src/ui",
]


func test_simulation_scripts_do_not_depend_on_nodes_presentation_or_ui() -> void:
	var script_paths: Array[String] = []
	_collect_scripts(SIMULATION_ROOT, script_paths)
	assert_true(not script_paths.is_empty(), "expected simulation scripts to scan")

	for script_path: String in script_paths:
		var source: String = FileAccess.get_file_as_string(script_path)
		for forbidden: String in FORBIDDEN_TEXT:
			assert_false(
				source.contains(forbidden),
				"%s contains forbidden dependency text '%s'" % [script_path, forbidden],
			)


func _collect_scripts(directory_path: String, script_paths: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if file_name.ends_with(".gd"):
			script_paths.append(directory_path.path_join(file_name))
	for child_name: String in directory.get_directories():
		_collect_scripts(directory_path.path_join(child_name), script_paths)
	script_paths.sort()
