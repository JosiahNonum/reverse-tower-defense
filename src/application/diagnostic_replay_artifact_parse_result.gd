class_name DiagnosticReplayArtifactParseResult
extends RefCounted


const CODE_PARSED: StringName = &"parsed"
const CODE_MALFORMED_JSON: StringName = &"malformed_json"
const CODE_INVALID_STRUCTURE: StringName = &"invalid_structure"

var is_success: bool
var code: StringName
var message: String
var artifact: DiagnosticReplayArtifact


func _init(
	success: bool,
	result_code: StringName,
	detail: String,
	parsed_artifact: DiagnosticReplayArtifact = null,
) -> void:
	is_success = success
	code = result_code
	message = detail
	artifact = parsed_artifact


static func accept(parsed_artifact: DiagnosticReplayArtifact) -> DiagnosticReplayArtifactParseResult:
	return DiagnosticReplayArtifactParseResult.new(true, CODE_PARSED, "", parsed_artifact)


static func reject(result_code: StringName, detail: String) -> DiagnosticReplayArtifactParseResult:
	return DiagnosticReplayArtifactParseResult.new(false, result_code, detail)
