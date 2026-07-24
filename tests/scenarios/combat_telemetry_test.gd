extends "res://tests/framework/test_case.gd"


const SCENARIO_PATHS: Array[String] = [
	"res://tests/fixtures/combat_scenarios/mixed_counterplay.json",
	"res://tests/fixtures/combat_scenarios/splash_density.json",
	"res://tests/fixtures/combat_scenarios/support_breakthrough.json",
]

var _catalog: ContentCatalog


func before_each() -> void:
	_catalog = ContentCatalog.load_from_directory("res://content")


func test_checked_scenarios_round_trip_and_match_semantic_summaries() -> void:
	var runner := CombatScenarioRunner.new()
	for path: String in SCENARIO_PATHS:
		var json_text: String = FileAccess.get_file_as_string(path)
		var parsed: Dictionary = CombatScenarioArtifact.from_json(json_text)
		assert_true(parsed["is_success"], parsed["message"])
		if not parsed["is_success"]:
			continue
		var round_trip: Dictionary = CombatScenarioArtifact.from_json(
			parsed["artifact"].to_json(),
		)
		assert_true(round_trip["is_success"], round_trip["message"])
		assert_equal(
			round_trip["artifact"].to_dictionary(),
			parsed["artifact"].to_dictionary(),
		)
		var result: CombatScenarioResult = runner.run_json(json_text, _catalog)
		assert_true(result.is_success, result.message)
		if result.is_success:
			assert_true(SemanticResultDiff.compare(
				JSON.parse_string(result.summary.to_json()),
				result.summary.to_dictionary(),
			).is_empty())
			assert_equal(result.summary.semantic_digest().length(), 64)


func test_suite_covers_every_required_combat_event_family() -> void:
	var observed_event_types: Dictionary[String, bool] = {}
	var runner := CombatScenarioRunner.new()
	for path: String in SCENARIO_PATHS:
		var result: CombatScenarioResult = runner.run_json(
			FileAccess.get_file_as_string(path),
			_catalog,
		)
		assert_true(result.is_success, result.message)
		if not result.is_success:
			continue
		for event_type: String in result.summary.event_counts:
			observed_event_types[event_type] = true

	for required_type: StringName in [
		FixedDefenseSimulation.EVENT_UNIT_SPAWNED,
		FixedDefenseSimulation.EVENT_TOWER_ATTACKED,
		FixedDefenseSimulation.EVENT_UNIT_DAMAGED,
		FixedDefenseSimulation.EVENT_SLOW_STAGED,
		FixedDefenseSimulation.EVENT_RALLY_APPLIED,
		FixedDefenseSimulation.EVENT_UNIT_DIED,
		FixedDefenseSimulation.EVENT_UNIT_LEAKED,
	]:
		assert_true(
			observed_event_types.has(String(required_type)),
			"scenario suite is missing event family '%s'" % required_type,
		)


func test_semantic_mismatch_reports_precise_readable_paths() -> void:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(SCENARIO_PATHS[1]),
	)
	data["expected_summary"]["effective_damage_by_source"][
		"tower.splash@slot.approach"
	] = 71
	var result: CombatScenarioResult = CombatScenarioRunner.new().run_json(
		JSON.stringify(data),
		_catalog,
	)

	assert_equal(result.code, CombatScenarioResult.CODE_RESULT_MISMATCH)
	assert_true(result.message.contains(
		"$.effective_damage_by_source.tower.splash@slot.approach",
	))
	assert_true(result.message.contains("expected 71, received 72"))
	assert_equal(result.summary.total_effective_damage, 72)


func test_invalid_deployment_and_timeout_fail_with_reason_codes() -> void:
	var runner := CombatScenarioRunner.new()
	var malformed: CombatScenarioResult = runner.run_json("{", _catalog)
	assert_equal(malformed.code, CombatScenarioResult.CODE_MALFORMED_ARTIFACT)

	var deployment_data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(SCENARIO_PATHS[1]),
	)
	deployment_data["tower_deployments"].append({
		"tower_id": "tower.rapid",
		"slot_id": "slot.approach",
	})
	var deployment: CombatScenarioResult = runner.run_json(
		JSON.stringify(deployment_data),
		_catalog,
	)
	assert_equal(deployment.code, CombatScenarioResult.CODE_DEPLOYMENT_REJECTED)
	assert_true(deployment.message.contains("occupied"))

	var timeout_data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(SCENARIO_PATHS[2]),
	)
	timeout_data["maximum_ticks"] = 1
	var timeout: CombatScenarioResult = runner.run_json(
		JSON.stringify(timeout_data),
		_catalog,
	)
	assert_equal(timeout.code, CombatScenarioResult.CODE_TIMEOUT)
	assert_true(timeout.message.contains("1 ticks"))
