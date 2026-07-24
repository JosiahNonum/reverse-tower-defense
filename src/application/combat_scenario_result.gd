class_name CombatScenarioResult
extends RefCounted


const CODE_MATCHED: StringName = &"matched"
const CODE_MALFORMED_ARTIFACT: StringName = &"malformed_artifact"
const CODE_SCHEMA_MISMATCH: StringName = &"schema_mismatch"
const CODE_RULES_MISMATCH: StringName = &"rules_mismatch"
const CODE_CONTENT_MISMATCH: StringName = &"content_mismatch"
const CODE_SCHEDULE_REJECTED: StringName = &"schedule_rejected"
const CODE_DEPLOYMENT_REJECTED: StringName = &"deployment_rejected"
const CODE_TIMEOUT: StringName = &"timeout"
const CODE_RESULT_MISMATCH: StringName = &"result_mismatch"

var is_success: bool
var code: StringName
var message: String
var summary: CombatTelemetrySummary


func _init(
	success: bool,
	result_code: StringName,
	detail: String,
	actual_summary: CombatTelemetrySummary = null,
) -> void:
	is_success = success
	code = result_code
	message = detail
	summary = actual_summary.copy() if actual_summary != null else null


static func accept(actual_summary: CombatTelemetrySummary) -> CombatScenarioResult:
	return CombatScenarioResult.new(true, CODE_MATCHED, "", actual_summary)


static func reject(
	result_code: StringName,
	detail: String,
	actual_summary: CombatTelemetrySummary = null,
) -> CombatScenarioResult:
	return CombatScenarioResult.new(false, result_code, detail, actual_summary)
