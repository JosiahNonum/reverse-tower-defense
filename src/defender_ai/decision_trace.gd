class_name DecisionTrace
extends RefCounted

var decision_id: int
var round_index: int
var phase: StringName
var difficulty: StringName
var rules_version: String
var content_fingerprint: String
var observation_fingerprint: String
var visible_rounds: Array[int] = []
var candidate_count: int
var candidate_cap: int
var truncated: bool
var legality_rejections: Array[Dictionary] = []
var score_components: Array[Dictionary] = []
var variation_draws: Array[Dictionary] = []
var chosen_commands: Array[Dictionary] = []
var gateway_results: Array[bool] = []
var remaining_budget: int
var stop_reason: StringName
var features: Dictionary[StringName, int] = {}

func to_dictionary() -> Dictionary:
	return {"decision_id":decision_id,"round":round_index,"phase":String(phase),"difficulty":String(difficulty),"rules_version":rules_version,"content":content_fingerprint,"observation":observation_fingerprint,"visible_rounds":visible_rounds.duplicate(),"candidate_count":candidate_count,"candidate_cap":candidate_cap,"truncated":truncated,"rejections":legality_rejections.duplicate(true),"scores":score_components.duplicate(true),"variation":variation_draws.duplicate(true),"commands":chosen_commands.duplicate(true),"results":gateway_results.duplicate(),"remaining_budget":remaining_budget,"stop_reason":String(stop_reason),"features":features.duplicate()}
