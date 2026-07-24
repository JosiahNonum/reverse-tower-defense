class_name DiagnosticReplayResult
extends RefCounted


const CODE_REPLAYED: StringName = &"replayed"
const CODE_MALFORMED_ARTIFACT: StringName = &"malformed_artifact"
const CODE_SCHEMA_MISMATCH: StringName = &"schema_mismatch"
const CODE_RULES_MISMATCH: StringName = &"rules_mismatch"
const CODE_CONTENT_MISMATCH: StringName = &"content_mismatch"
const CODE_SCENARIO_MISMATCH: StringName = &"scenario_mismatch"
const CODE_COMMAND_REJECTED: StringName = &"command_rejected"
const CODE_RESULT_MISMATCH: StringName = &"result_mismatch"

var is_success: bool
var code: StringName
var message: String
var summary: DiagnosticReplaySummary


func _init(
	success: bool,
	result_code: StringName,
	detail: String,
	replay_summary: DiagnosticReplaySummary = null,
) -> void:
	is_success = success
	code = result_code
	message = detail
	summary = replay_summary


static func accept(replay_summary: DiagnosticReplaySummary) -> DiagnosticReplayResult:
	return DiagnosticReplayResult.new(true, CODE_REPLAYED, "", replay_summary.copy())


static func reject(
	result_code: StringName,
	detail: String,
	replay_summary: DiagnosticReplaySummary = null,
) -> DiagnosticReplayResult:
	return DiagnosticReplayResult.new(false, result_code, detail, replay_summary)
