class_name DiagnosticReplayArtifact
extends RefCounted


const CURRENT_SCHEMA_VERSION: int = 1

var schema_version: int
var rules_version: String
var content_fingerprint: String
var root_seed: int
var scenario_id: StringName
var rules_id: StringName
var map_id: StringName
var unit_ids: Array[StringName]
var tower_ids: Array[StringName]
var defender_profile_ids: Array[StringName]
var commands: Array[PhaseCommand]
var ticks_to_advance: int
var expected_summary: DiagnosticReplaySummary


func _init(
	artifact_schema_version: int,
	artifact_rules_version: String,
	artifact_content_fingerprint: String,
	artifact_root_seed: int,
	artifact_scenario_id: StringName,
	artifact_rules_id: StringName,
	artifact_map_id: StringName,
	artifact_unit_ids: Array[StringName],
	artifact_tower_ids: Array[StringName],
	artifact_defender_profile_ids: Array[StringName],
	artifact_commands: Array[PhaseCommand],
	artifact_ticks_to_advance: int,
	artifact_expected_summary: DiagnosticReplaySummary,
) -> void:
	schema_version = artifact_schema_version
	rules_version = artifact_rules_version
	content_fingerprint = artifact_content_fingerprint
	root_seed = artifact_root_seed
	scenario_id = artifact_scenario_id
	rules_id = artifact_rules_id
	map_id = artifact_map_id
	unit_ids = _normalized_ids(artifact_unit_ids)
	tower_ids = _normalized_ids(artifact_tower_ids)
	defender_profile_ids = _normalized_ids(artifact_defender_profile_ids)
	commands = []
	for command: PhaseCommand in artifact_commands:
		commands.append(command.copy())
	ticks_to_advance = artifact_ticks_to_advance
	expected_summary = artifact_expected_summary.copy()


func to_dictionary() -> Dictionary:
	var serialized_commands: Array[Dictionary] = []
	for command: PhaseCommand in commands:
		serialized_commands.append(command.to_dictionary())
	return {
		"schema_version": schema_version,
		"rules_version": rules_version,
		"content_fingerprint": content_fingerprint,
		"root_seed": str(root_seed),
		"scenario_id": String(scenario_id),
		"content_ids": {
			"rules": String(rules_id),
			"map": String(map_id),
			"units": _string_ids(unit_ids),
			"towers": _string_ids(tower_ids),
			"defender_profiles": _string_ids(defender_profile_ids),
		},
		"accepted_phase_commands": serialized_commands,
		"ticks_to_advance": ticks_to_advance,
		"expected_summary": expected_summary.to_dictionary(),
	}


func to_json() -> String:
	return JSON.stringify(to_dictionary(), "\t") + "\n"


static func from_json(json_text: String) -> DiagnosticReplayArtifactParseResult:
	var parser := JSON.new()
	var parse_error: Error = parser.parse(json_text)
	if parse_error != OK:
		return DiagnosticReplayArtifactParseResult.reject(
			DiagnosticReplayArtifactParseResult.CODE_MALFORMED_JSON,
			"JSON parse failed at line %d: %s" % [parser.get_error_line(), parser.get_error_message()],
		)
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return _invalid("artifact root must be an object")
	return _from_dictionary(parsed)


static func _from_dictionary(data: Dictionary) -> DiagnosticReplayArtifactParseResult:
	var required_fields: Array[String] = [
		"schema_version",
		"rules_version",
		"content_fingerprint",
		"root_seed",
		"scenario_id",
		"content_ids",
		"accepted_phase_commands",
		"ticks_to_advance",
		"expected_summary",
	]
	for field_name: String in required_fields:
		if not data.has(field_name):
			return _invalid("missing required field '%s'" % field_name)
	var schema_result: Dictionary = _parse_integer(data["schema_version"], "schema_version")
	if not schema_result["is_valid"]:
		return _invalid("schema_version must be an integer")
	if typeof(data["rules_version"]) != TYPE_STRING or typeof(data["content_fingerprint"]) != TYPE_STRING:
		return _invalid("rules_version and content_fingerprint must be strings")
	if (
		typeof(data["root_seed"]) != TYPE_STRING
		or not String(data["root_seed"]).is_valid_int()
		or typeof(data["scenario_id"]) != TYPE_STRING
	):
		return _invalid("root_seed must be a decimal integer string and scenario_id must be a string")
	var ticks_result: Dictionary = _parse_integer(data["ticks_to_advance"], "ticks_to_advance")
	if not ticks_result["is_valid"] or ticks_result["value"] < 0:
		return _invalid("ticks_to_advance must be a nonnegative integer")

	var content_result: Dictionary = _parse_content_ids(data["content_ids"])
	if not content_result["is_valid"]:
		return _invalid(content_result["message"])
	var command_result: Dictionary = _parse_commands(data["accepted_phase_commands"])
	if not command_result["is_valid"]:
		return _invalid(command_result["message"])
	var summary_result: Dictionary = _parse_summary(data["expected_summary"])
	if not summary_result["is_valid"]:
		return _invalid(summary_result["message"])

	var artifact := DiagnosticReplayArtifact.new(
		schema_result["value"],
		data["rules_version"],
		data["content_fingerprint"],
		String(data["root_seed"]).to_int(),
		StringName(data["scenario_id"]),
		StringName(content_result["rules"]),
		StringName(content_result["map"]),
		content_result["units"],
		content_result["towers"],
		content_result["defender_profiles"],
		command_result["commands"],
		ticks_result["value"],
		summary_result["summary"],
	)
	return DiagnosticReplayArtifactParseResult.accept(artifact)


static func _parse_content_ids(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _invalid_part("content_ids must be an object")
	var data: Dictionary = value
	for field_name: String in ["rules", "map", "units", "towers", "defender_profiles"]:
		if not data.has(field_name):
			return _invalid_part("content_ids is missing '%s'" % field_name)
	if typeof(data["rules"]) != TYPE_STRING or typeof(data["map"]) != TYPE_STRING:
		return _invalid_part("content rules and map IDs must be strings")
	var units_result: Dictionary = _parse_id_array(data["units"], "units")
	var towers_result: Dictionary = _parse_id_array(data["towers"], "towers")
	var profiles_result: Dictionary = _parse_id_array(data["defender_profiles"], "defender_profiles")
	for result: Dictionary in [units_result, towers_result, profiles_result]:
		if not result["is_valid"]:
			return result
	return {
		"is_valid": true,
		"rules": data["rules"],
		"map": data["map"],
		"units": units_result["ids"],
		"towers": towers_result["ids"],
		"defender_profiles": profiles_result["ids"],
	}


static func _parse_id_array(value: Variant, field_name: String) -> Dictionary:
	if typeof(value) != TYPE_ARRAY:
		return _invalid_part("content_ids.%s must be an array" % field_name)
	var ids: Array[StringName] = []
	for item: Variant in value:
		if typeof(item) != TYPE_STRING or String(item).is_empty():
			return _invalid_part("content_ids.%s must contain nonempty strings" % field_name)
		ids.append(StringName(item))
	return {"is_valid": true, "ids": ids}


static func _parse_commands(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_ARRAY:
		return _invalid_part("accepted_phase_commands must be an array")
	var parsed_commands: Array[PhaseCommand] = []
	for command_index: int in value.size():
		var command_value: Variant = value[command_index]
		if typeof(command_value) != TYPE_DICTIONARY:
			return _invalid_part("command %d must be an object" % command_index)
		var command_data: Dictionary = command_value
		for field_name: String in ["command_id", "command_type", "expected_phase", "actor"]:
			if not command_data.has(field_name):
				return _invalid_part("command %d is missing '%s'" % [command_index, field_name])
		var command_id_result: Dictionary = _parse_integer(
			command_data["command_id"],
			"command %d command_id" % command_index,
		)
		if not command_id_result["is_valid"]:
			return _invalid_part("command %d command_id must be an integer" % command_index)
		for field_name: String in ["command_type", "expected_phase", "actor"]:
			if typeof(command_data[field_name]) != TYPE_STRING:
				return _invalid_part("command %d %s must be a string" % [command_index, field_name])
		parsed_commands.append(PhaseCommand.new(
			command_id_result["value"],
			StringName(command_data["command_type"]),
			StringName(command_data["expected_phase"]),
			StringName(command_data["actor"]),
		))
	return {"is_valid": true, "commands": parsed_commands}


static func _parse_summary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return _invalid_part("expected_summary must be an object")
	var data: Dictionary = value
	for field_name: String in ["phase", "tick", "event_count", "event_digest"]:
		if not data.has(field_name):
			return _invalid_part("expected_summary is missing '%s'" % field_name)
	if typeof(data["phase"]) != TYPE_STRING or typeof(data["event_digest"]) != TYPE_STRING:
		return _invalid_part("expected summary phase and digest must be strings")
	var tick_result: Dictionary = _parse_integer(data["tick"], "expected_summary.tick")
	var event_count_result: Dictionary = _parse_integer(
		data["event_count"],
		"expected_summary.event_count",
	)
	if not tick_result["is_valid"] or not event_count_result["is_valid"]:
		return _invalid_part("expected summary tick and event_count must be integers")
	if tick_result["value"] < 0 or event_count_result["value"] < 0:
		return _invalid_part("expected summary counts must be nonnegative")
	return {
		"is_valid": true,
		"summary": DiagnosticReplaySummary.new(
			StringName(data["phase"]),
			tick_result["value"],
			event_count_result["value"],
			data["event_digest"],
		),
	}


static func _normalized_ids(values: Array[StringName]) -> Array[StringName]:
	var normalized: Array[StringName] = values.duplicate()
	normalized.sort()
	return normalized


static func _string_ids(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result


static func _parse_integer(value: Variant, field_name: String) -> Dictionary:
	if typeof(value) == TYPE_INT:
		return {"is_valid": true, "value": value}
	if typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value):
		return {"is_valid": true, "value": int(value)}
	return _invalid_part("%s must be an integer" % field_name)


static func _invalid(message: String) -> DiagnosticReplayArtifactParseResult:
	return DiagnosticReplayArtifactParseResult.reject(
		DiagnosticReplayArtifactParseResult.CODE_INVALID_STRUCTURE,
		message,
	)


static func _invalid_part(message: String) -> Dictionary:
	return {"is_valid": false, "message": message}
