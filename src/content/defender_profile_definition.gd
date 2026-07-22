class_name DefenderProfileDefinition
extends Resource


@export var content_id: StringName
@export var history_delay_rounds: int
@export var candidate_cap: int
@export var action_cap: int
@export var reserve_basis_points: int
@export var variation_basis_points: int
@export var scoring_weights: Dictionary[StringName, int] = {}


func to_dictionary() -> Dictionary:
	var weight_keys: Array[StringName] = []
	weight_keys.assign(scoring_weights.keys())
	weight_keys.sort()
	var serialized_weights: Dictionary = {}
	for key: StringName in weight_keys:
		serialized_weights[String(key)] = scoring_weights[key]
	return {
		"kind": "defender_profile",
		"id": String(content_id),
		"history_delay": history_delay_rounds,
		"candidate_cap": candidate_cap,
		"action_cap": action_cap,
		"reserve_basis_points": reserve_basis_points,
		"variation_basis_points": variation_basis_points,
		"weights": serialized_weights,
	}
