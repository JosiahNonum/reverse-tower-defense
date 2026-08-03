class_name WaveDraftEditResult
extends RefCounted


const CODE_ACCEPTED: StringName = &"accepted"
const CODE_UNKNOWN_UNIT: StringName = &"unknown_unit"
const CODE_UNIT_NOT_ALLOWED: StringName = &"unit_not_allowed"
const CODE_INVALID_QUANTITY: StringName = &"invalid_quantity"
const CODE_ENTRY_LIMIT: StringName = &"entry_limit"
const CODE_UNKNOWN_ENTRY: StringName = &"unknown_entry"
const CODE_INVALID_SPACING: StringName = &"invalid_spacing"
const CODE_MOVE_BOUNDARY: StringName = &"move_boundary"
const CODE_NOTHING_TO_UNDO: StringName = &"nothing_to_undo"
const CODE_NOTHING_TO_REDO: StringName = &"nothing_to_redo"

var is_accepted: bool
var code: StringName
var message: String


func _init(accepted: bool, result_code: StringName, result_message: String) -> void:
	is_accepted = accepted
	code = result_code
	message = result_message


static func accept(message: String = "") -> WaveDraftEditResult:
	return WaveDraftEditResult.new(true, CODE_ACCEPTED, message)


static func reject(result_code: StringName, message: String) -> WaveDraftEditResult:
	return WaveDraftEditResult.new(false, result_code, message)
