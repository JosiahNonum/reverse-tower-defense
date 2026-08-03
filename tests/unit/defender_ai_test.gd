extends "res://tests/framework/test_case.gd"

const HistoryScript = preload("res://src/defender_ai/observation_history.gd")
const ProjectorScript = preload("res://src/defender_ai/observation_projector.gd")
const GatewayScript = preload("res://src/simulation/defense_command_gateway.gd")
const PlannerScript = preload("res://src/defender_ai/defender_planner.gd")
const VariationScript = preload("res://src/defender_ai/defender_variation.gd")

func test_observation_history_applies_easy_delay_and_returns_copies() -> void:
	var history = HistoryScript.new()
	history.append_finalized(1, _analysis(9, 2, 0))
	history.append_finalized(2, _analysis(8, 1, 1))
	assert_equal(history.visible(1).size(), 1)
	assert_equal(history.visible(0).size(), 2)
	var rows: Array = history.visible(0)
	rows[0]["leaks"] = 99
	assert_equal(history.visible(0)[0]["leaks"], 2)

func test_difficulty_profiles_expose_only_their_documented_history_age() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var history = HistoryScript.new()
	history.append_finalized(1, _analysis(9, 0, 0))
	history.append_finalized(2, _analysis(8, 1, 0))
	assert_equal(history.visible(catalog.get_defender_profile(&"profile.easy").history_delay_rounds).size(), 1)
	assert_equal(history.visible(catalog.get_defender_profile(&"profile.normal").history_delay_rounds).size(), 2)
	assert_equal(history.visible(catalog.get_defender_profile(&"profile.hard").history_delay_rounds).size(), 2)

func test_ai_modules_do_not_name_forbidden_runtime_or_ui_dependencies() -> void:
	var directory := DirAccess.open("res://src/defender_ai")
	for file_name: String in directory.get_files():
		if not file_name.ends_with(".gd"): continue
		var source: String = FileAccess.get_file_as_string("res://src/defender_ai".path_join(file_name))
		for forbidden: String in ["MatchState", "WaveDraft", "CommittedWave", "src/presentation", "src/ui", "extends Node", "get_node("]:
			assert_false(source.contains(forbidden), "%s names %s" % [file_name, forbidden])

func test_planner_is_bounded_stable_and_uses_only_observation_values() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var profile: DefenderProfileDefinition = catalog.get_defender_profile(&"profile.easy")
	var history = HistoryScript.new()
	history.append_finalized(1, _analysis(8, 2, 0))
	var observation = ProjectorScript.project(2, MatchPhase.DEFENDER_ADAPTATION, profile, 8, 40, [], history, rules, catalog.content_fingerprint())
	var first = PlannerScript.new().plan(observation, profile, catalog, rules, GatewayScript.new(catalog, rules, 40), VariationScript.new(7), 1)
	var second = PlannerScript.new().plan(observation, profile, catalog, rules, GatewayScript.new(catalog, rules, 40), VariationScript.new(7), 1)
	assert_true(first.candidate_count <= first.candidate_cap)
	assert_false(first.truncated)
	assert_true(first.chosen_commands.size() <= profile.action_cap)
	assert_equal(first.chosen_commands, second.chosen_commands)
	assert_equal(first.observation_fingerprint, observation.fingerprint())
	assert_equal(first.to_dictionary(), second.to_dictionary())

func _analysis(core: int, leaks: int, survivors: int):
	return _Analysis.new(core, leaks, survivors)

class _Analysis:
	var _core: int
	var _leaks: int
	var _survivors: int
	func _init(core: int, leaks: int, survivors: int) -> void:
		_core = core
		_leaks = leaks
		_survivors = survivors
	func get_core_integrity() -> int: return _core
	func get_leak_count() -> int: return _leaks
	func get_survivor_count() -> int: return _survivors
	func get_damage_by_location() -> Dictionary[String, int]: return {}
