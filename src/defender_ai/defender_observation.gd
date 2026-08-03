class_name DefenderObservation
extends RefCounted

var round_index: int
var phase: StringName
var profile_id: StringName
var core_integrity: int
var defender_budget: int
var deployments: Array[Dictionary] = []
var history: Array[Dictionary] = []
var rules_version: String
var content_fingerprint: String

func _init(requested_round: int, requested_phase: StringName, requested_profile: StringName, requested_core: int, requested_budget: int, requested_deployments: Array[Dictionary], requested_history: Array[Dictionary], requested_rules_version: String, requested_fingerprint: String) -> void:
	round_index = requested_round
	phase = requested_phase
	profile_id = requested_profile
	core_integrity = requested_core
	defender_budget = requested_budget
	deployments = _copy_rows(requested_deployments)
	history = _copy_rows(requested_history)
	rules_version = requested_rules_version
	content_fingerprint = requested_fingerprint

func fingerprint() -> String:
	return JSON.stringify(to_dictionary()).sha256_text()

func to_dictionary() -> Dictionary:
	return {"round":round_index,"phase":String(phase),"profile":String(profile_id),"core":core_integrity,"budget":defender_budget,"deployments":_copy_rows(deployments),"history":_copy_rows(history),"rules_version":rules_version,"content":content_fingerprint}

func _copy_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for row: Dictionary in rows: copy.append(row.duplicate(true))
	return copy
