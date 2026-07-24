extends "res://tests/framework/test_case.gd"


const FIXTURE_PATH: String = "res://tests/fixtures/replays/foundation_phase_replay.json"

var _catalog: ContentCatalog
var _fixture_json: String


func before_each() -> void:
	_catalog = ContentCatalog.load_from_directory("res://content")
	_fixture_json = FileAccess.get_file_as_string(FIXTURE_PATH)


func test_checked_fixture_round_trips_without_contract_loss() -> void:
	var first: DiagnosticReplayArtifactParseResult = DiagnosticReplayArtifact.from_json(_fixture_json)
	assert_true(first.is_success, first.message)
	if not first.is_success:
		return
	var second: DiagnosticReplayArtifactParseResult = DiagnosticReplayArtifact.from_json(first.artifact.to_json())
	assert_true(second.is_success, second.message)
	if not second.is_success:
		return
	assert_equal(second.artifact.to_dictionary(), first.artifact.to_dictionary())


func test_checked_fixture_replays_to_an_identical_result() -> void:
	var runner := DiagnosticReplayRunner.new()
	var first: DiagnosticReplayResult = runner.replay_json(_fixture_json, _catalog)
	var second: DiagnosticReplayResult = runner.replay_json(_fixture_json, _catalog)

	assert_true(first.is_success, "%s: %s" % [first.code, first.message])
	assert_true(second.is_success, "%s: %s" % [second.code, second.message])
	if not first.is_success or not second.is_success:
		return
	assert_equal(first.summary.to_dictionary(), second.summary.to_dictionary())


func test_incompatible_schema_rules_and_content_fail_clearly() -> void:
	var runner := DiagnosticReplayRunner.new()
	var schema_data: Dictionary = JSON.parse_string(_fixture_json)
	schema_data["schema_version"] = 99
	var schema_result: DiagnosticReplayResult = runner.replay_json(JSON.stringify(schema_data), _catalog)

	var rules_data: Dictionary = JSON.parse_string(_fixture_json)
	rules_data["rules_version"] = "future-rules"
	var rules_result: DiagnosticReplayResult = runner.replay_json(JSON.stringify(rules_data), _catalog)

	var content_data: Dictionary = JSON.parse_string(_fixture_json)
	content_data["content_fingerprint"] = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	var content_result: DiagnosticReplayResult = runner.replay_json(JSON.stringify(content_data), _catalog)

	assert_equal(schema_result.code, DiagnosticReplayResult.CODE_SCHEMA_MISMATCH)
	assert_true(schema_result.message.contains("schema"))
	assert_equal(rules_result.code, DiagnosticReplayResult.CODE_RULES_MISMATCH)
	assert_true(rules_result.message.contains("rules version"))
	assert_equal(content_result.code, DiagnosticReplayResult.CODE_CONTENT_MISMATCH)
	assert_true(content_result.message.contains("fingerprint"))


func test_malformed_artifact_and_rejected_command_do_not_mutate_a_live_match() -> void:
	var runner := DiagnosticReplayRunner.new()
	var malformed: DiagnosticReplayResult = runner.replay_json("{", _catalog)
	assert_equal(malformed.code, DiagnosticReplayResult.CODE_MALFORMED_ARTIFACT)

	var rejected_data: Dictionary = JSON.parse_string(_fixture_json)
	rejected_data["accepted_phase_commands"][0]["actor"] = "player"
	var rejected: DiagnosticReplayResult = runner.replay_json(JSON.stringify(rejected_data), _catalog)
	assert_equal(rejected.code, DiagnosticReplayResult.CODE_COMMAND_REJECTED)

	var live_match := MatchState.new(731)
	assert_equal(live_match.get_phase(), MatchPhase.INITIAL_DEFENSE)
	assert_equal(live_match.get_tick(), 0)
	assert_equal(live_match.get_events().size(), 0)
