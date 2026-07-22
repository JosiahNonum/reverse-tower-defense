class_name ContentValidationResult
extends RefCounted


var issues: Array[ContentValidationIssue] = []


func is_valid() -> bool:
	return issues.is_empty()


func add(code: StringName, location: String, message: String) -> void:
	issues.append(ContentValidationIssue.new(code, location, message))


func has_code(code: StringName) -> bool:
	for issue: ContentValidationIssue in issues:
		if issue.code == code:
			return true
	return false
