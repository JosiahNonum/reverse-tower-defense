class_name MatchRulesDefinition
extends Resource


@export var content_id: StringName
@export var rules_version: String
@export var map_id: StringName
@export var unit_ids: Array[StringName] = []
@export var tower_ids: Array[StringName] = []
@export var defender_profile_ids: Array[StringName] = []
@export var round_count: int
@export var attack_budgets: Array[int] = []
@export var initial_defense_budget: int
@export var adaptation_grant: int
@export var sale_refund_basis_points: int
@export var core_health: int
@export var ticks_per_second: int


func to_dictionary() -> Dictionary:
	return {
		"kind": "match_rules",
		"id": String(content_id),
		"rules_version": rules_version,
		"map": String(map_id),
		"units": _strings(unit_ids),
		"towers": _strings(tower_ids),
		"profiles": _strings(defender_profile_ids),
		"round_count": round_count,
		"attack_budgets": attack_budgets.duplicate(),
		"initial_defense_budget": initial_defense_budget,
		"adaptation_grant": adaptation_grant,
		"sale_refund_basis_points": sale_refund_basis_points,
		"core_health": core_health,
		"ticks_per_second": ticks_per_second,
	}


func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	result.sort()
	return result
