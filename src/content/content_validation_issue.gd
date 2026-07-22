class_name ContentValidationIssue
extends RefCounted


var code: StringName
var location: String
var message: String


func _init(issue_code: StringName, issue_location: String, detail: String) -> void:
	code = issue_code
	location = issue_location
	message = detail


func format() -> String:
	return "%s [%s]: %s" % [code, location, message]
