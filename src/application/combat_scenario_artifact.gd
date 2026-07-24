class_name CombatScenarioArtifact
extends RefCounted


const CURRENT_SCHEMA_VERSION: int = 1
const CODE_MALFORMED_JSON: StringName = &"malformed_json"
const CODE_INVALID_STRUCTURE: StringName = &"invalid_structure"

var schema_version: int
var rules_version: String
var content_fingerprint: String
var root_seed: int
var scenario_id: StringName
var rules_id: StringName
var wave_entries: Array[WaveScheduleEntry]
var tower_deployments: Array[TowerDeployment]
var maximum_ticks: int
var expected_summary: Dictionary


func _init(
	artifact_schema_version: int,
	artifact_rules_version: String,
	artifact_content_fingerprint: String,
	artifact_root_seed: int,
	artifact_scenario_id: StringName,
	artifact_rules_id: StringName,
	artifact_wave_entries: Array[WaveScheduleEntry],
	artifact_tower_deployments: Array[TowerDeployment],
	artifact_maximum_ticks: int,
	artifact_expected_summary: Dictionary,
) -> void:
	schema_version = artifact_schema_version
	rules_version = artifact_rules_version
	content_fingerprint = artifact_content_fingerprint
	root_seed = artifact_root_seed
	scenario_id = artifact_scenario_id
	rules_id = artifact_rules_id
	wave_entries = []
	for entry: WaveScheduleEntry in artifact_wave_entries:
		wave_entries.append(entry.copy())
	tower_deployments = []
	for deployment: TowerDeployment in artifact_tower_deployments:
		tower_deployments.append(deployment.copy())
	maximum_ticks = artifact_maximum_ticks
	expected_summary = artifact_expected_summary.duplicate(true)


static func from_json(json_text: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error: Error = parser.parse(json_text)
	if parse_error != OK:
		return _reject(
			CODE_MALFORMED_JSON,
			"JSON parse failed at line %d: %s" % [
				parser.get_error_line(),
				parser.get_error_message(),
			],
		)
	if typeof(parser.data) != TYPE_DICTIONARY:
		return _reject(CODE_INVALID_STRUCTURE, "artifact root must be an object")
	return _from_dictionary(parser.data)


func to_dictionary() -> Dictionary:
	var serialized_wave: Array[Dictionary] = []
	for entry: WaveScheduleEntry in wave_entries:
		serialized_wave.append({
			"unit_id": String(entry.unit_id),
			"route_id": String(entry.route_id),
			"spacing_after_previous_ticks": entry.spacing_after_previous_ticks,
		})
	var serialized_towers: Array[Dictionary] = []
	for deployment: TowerDeployment in tower_deployments:
		serialized_towers.append({
			"tower_id": String(deployment.tower_id),
			"slot_id": String(deployment.slot_id),
		})
	return {
		"schema_version": schema_version,
		"rules_version": rules_version,
		"content_fingerprint": content_fingerprint,
		"root_seed": str(root_seed),
		"scenario_id": String(scenario_id),
		"rules_id": String(rules_id),
		"wave_entries": serialized_wave,
		"tower_deployments": serialized_towers,
		"maximum_ticks": maximum_ticks,
		"expected_summary": expected_summary.duplicate(true),
	}


func to_json() -> String:
	return JSON.stringify(to_dictionary(), "\t") + "\n"


static func _from_dictionary(data: Dictionary) -> Dictionary:
	var required_fields: Array[String] = [
		"schema_version",
		"rules_version",
		"content_fingerprint",
		"root_seed",
		"scenario_id",
		"rules_id",
		"wave_entries",
		"tower_deployments",
		"maximum_ticks",
		"expected_summary",
	]
	for field_name: String in required_fields:
		if not data.has(field_name):
			return _reject(CODE_INVALID_STRUCTURE, "missing required field '%s'" % field_name)
	var schema_result: Dictionary = _integer(data["schema_version"])
	var maximum_ticks_result: Dictionary = _integer(data["maximum_ticks"])
	if not schema_result["is_valid"]:
		return _reject(CODE_INVALID_STRUCTURE, "schema_version must be an integer")
	if not maximum_ticks_result["is_valid"] or maximum_ticks_result["value"] <= 0:
		return _reject(CODE_INVALID_STRUCTURE, "maximum_ticks must be a positive integer")
	for field_name: String in [
		"rules_version",
		"content_fingerprint",
		"root_seed",
		"scenario_id",
		"rules_id",
	]:
		if typeof(data[field_name]) != TYPE_STRING or String(data[field_name]).is_empty():
			return _reject(
				CODE_INVALID_STRUCTURE,
				"%s must be a nonempty string" % field_name,
			)
	if not String(data["root_seed"]).is_valid_int():
		return _reject(CODE_INVALID_STRUCTURE, "root_seed must be a decimal integer string")
	if typeof(data["expected_summary"]) != TYPE_DICTIONARY:
		return _reject(CODE_INVALID_STRUCTURE, "expected_summary must be an object")

	var wave_result: Dictionary = _parse_wave(data["wave_entries"])
	if not wave_result["is_success"]:
		return wave_result
	var towers_result: Dictionary = _parse_towers(data["tower_deployments"])
	if not towers_result["is_success"]:
		return towers_result
	var artifact := CombatScenarioArtifact.new(
		schema_result["value"],
		data["rules_version"],
		data["content_fingerprint"],
		String(data["root_seed"]).to_int(),
		StringName(data["scenario_id"]),
		StringName(data["rules_id"]),
		wave_result["values"],
		towers_result["values"],
		maximum_ticks_result["value"],
		_normalize_json_value(data["expected_summary"]),
	)
	return {
		"is_success": true,
		"code": &"parsed",
		"message": "",
		"artifact": artifact,
	}


static func _parse_wave(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_ARRAY or value.is_empty():
		return _reject(CODE_INVALID_STRUCTURE, "wave_entries must be a nonempty array")
	var entries: Array[WaveScheduleEntry] = []
	for index: int in value.size():
		var entry_value: Variant = value[index]
		if typeof(entry_value) != TYPE_DICTIONARY:
			return _reject(CODE_INVALID_STRUCTURE, "wave entry %d must be an object" % index)
		var entry: Dictionary = entry_value
		for field_name: String in [
			"unit_id",
			"route_id",
			"spacing_after_previous_ticks",
		]:
			if not entry.has(field_name):
				return _reject(
					CODE_INVALID_STRUCTURE,
					"wave entry %d is missing '%s'" % [index, field_name],
				)
		if typeof(entry["unit_id"]) != TYPE_STRING or typeof(entry["route_id"]) != TYPE_STRING:
			return _reject(
				CODE_INVALID_STRUCTURE,
				"wave entry %d IDs must be strings" % index,
			)
		var spacing_result: Dictionary = _integer(entry["spacing_after_previous_ticks"])
		if not spacing_result["is_valid"]:
			return _reject(
				CODE_INVALID_STRUCTURE,
				"wave entry %d spacing must be an integer" % index,
			)
		entries.append(WaveScheduleEntry.new(
			StringName(entry["unit_id"]),
			StringName(entry["route_id"]),
			spacing_result["value"],
		))
	return {"is_success": true, "values": entries}


static func _parse_towers(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_ARRAY:
		return _reject(CODE_INVALID_STRUCTURE, "tower_deployments must be an array")
	var deployments: Array[TowerDeployment] = []
	for index: int in value.size():
		var deployment_value: Variant = value[index]
		if typeof(deployment_value) != TYPE_DICTIONARY:
			return _reject(
				CODE_INVALID_STRUCTURE,
				"tower deployment %d must be an object" % index,
			)
		var deployment: Dictionary = deployment_value
		if not deployment.has("tower_id") or not deployment.has("slot_id"):
			return _reject(
				CODE_INVALID_STRUCTURE,
				"tower deployment %d requires tower_id and slot_id" % index,
			)
		if (
			typeof(deployment["tower_id"]) != TYPE_STRING
			or typeof(deployment["slot_id"]) != TYPE_STRING
		):
			return _reject(
				CODE_INVALID_STRUCTURE,
				"tower deployment %d IDs must be strings" % index,
			)
		deployments.append(TowerDeployment.new(
			StringName(deployment["tower_id"]),
			StringName(deployment["slot_id"]),
		))
	return {"is_success": true, "values": deployments}


static func _integer(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_INT:
		return {"is_valid": true, "value": value}
	if typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value):
		return {"is_valid": true, "value": int(value)}
	return {"is_valid": false}


static func _normalize_json_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value):
		return int(value)
	if typeof(value) == TYPE_ARRAY:
		var normalized_array: Array = []
		for entry: Variant in value:
			normalized_array.append(_normalize_json_value(entry))
		return normalized_array
	if typeof(value) == TYPE_DICTIONARY:
		var normalized_dictionary: Dictionary = {}
		for key: Variant in value:
			normalized_dictionary[key] = _normalize_json_value(value[key])
		return normalized_dictionary
	return value


static func _reject(code: StringName, message: String) -> Dictionary:
	return {
		"is_success": false,
		"code": code,
		"message": message,
		"artifact": null,
	}
