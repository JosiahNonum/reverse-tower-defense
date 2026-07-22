class_name CommandResult
extends RefCounted


const CODE_ACCEPTED: StringName = &"accepted"
const CODE_UNKNOWN_COMMAND: StringName = &"unknown_command"
const CODE_WRONG_PHASE: StringName = &"wrong_phase"
const CODE_FORBIDDEN_ACTOR: StringName = &"forbidden_actor"
const CODE_INVALID_COMMAND_ID: StringName = &"invalid_command_id"
const CODE_DUPLICATE_COMMAND: StringName = &"duplicate_command"
const CODE_EXPECTED_PHASE_MISMATCH: StringName = &"expected_phase_mismatch"

var is_accepted: bool
var code: StringName
var message: String


func _init(accepted: bool, result_code: StringName, detail: String = "") -> void:
	is_accepted = accepted
	code = result_code
	message = detail


static func accept() -> CommandResult:
	return CommandResult.new(true, CODE_ACCEPTED)


static func reject(result_code: StringName, detail: String) -> CommandResult:
	return CommandResult.new(false, result_code, detail)
