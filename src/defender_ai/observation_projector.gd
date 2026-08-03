class_name ObservationProjector
extends RefCounted

const DefenderObservationScript = preload("res://src/defender_ai/defender_observation.gd")

static func project(round_index: int, phase: StringName, profile: DefenderProfileDefinition, core: int, budget: int, deployments: Array[TowerDeployment], history, rules: MatchRulesDefinition, fingerprint: String):
	var rows: Array[Dictionary] = []
	for deployment: TowerDeployment in deployments:
		rows.append({"tower_id":String(deployment.tower_id),"slot_id":String(deployment.slot_id)})
	return DefenderObservationScript.new(round_index, phase, profile.content_id, core, budget, rows, history.visible(profile.history_delay_rounds), rules.rules_version, fingerprint)
