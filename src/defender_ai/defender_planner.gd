class_name DefenderPlanner
extends RefCounted

const DefenseCommandScript = preload("res://src/simulation/defense_command.gd")
const ThreatAnalyzerScript = preload("res://src/defender_ai/threat_analyzer.gd")

func plan(observation, profile: DefenderProfileDefinition, catalog: ContentCatalog, rules: MatchRulesDefinition, gateway, variation, decision_id: int):
	var trace := preload("res://src/defender_ai/decision_trace.gd").new()
	trace.decision_id = decision_id
	trace.round_index = observation.round_index
	trace.phase = observation.phase
	trace.difficulty = profile.content_id
	trace.rules_version = observation.rules_version
	trace.content_fingerprint = observation.content_fingerprint
	trace.observation_fingerprint = observation.fingerprint()
	trace.candidate_cap = profile.candidate_cap
	trace.features = ThreatAnalyzerScript.analyze(observation)
	for row: Dictionary in observation.history: trace.visible_rounds.append(int(row["round"]))
	for action_index: int in profile.action_cap:
		var candidates: Array = _candidates(catalog, rules, gateway, observation.phase != MatchPhase.INITIAL_DEFENSE)
		trace.candidate_count += candidates.size()
		candidates.sort_custom(func(left, right) -> bool: return _candidate_before(left, right))
		if candidates.size() > profile.candidate_cap:
			candidates.resize(profile.candidate_cap)
			trace.truncated = true
		if candidates.is_empty():
			trace.stop_reason = &"no_legal_candidates"
			break
		var best_score: int = int(candidates[0]["score"])
		var eligible: Array = []
		var band: int = maxi(1, absi(best_score)) * profile.variation_basis_points / 10000
		for candidate: Dictionary in candidates:
			if int(candidate["score"]) >= best_score - band: eligible.append(candidate)
		var selected: Dictionary = candidates[0]
		if profile.variation_basis_points > 0 and eligible.size() > 1:
			var draw: Dictionary = variation.choose_index(eligible.size() - 1)
			trace.variation_draws.append(draw)
			selected = eligible[int(draw["index"])]
		trace.score_components.append({"command":selected["command"].to_dictionary(),"coverage":selected["coverage"],"leak_risk":selected["leak_risk"],"total":selected["score"]})
		var command = selected["command"]
		var result: CommandResult = gateway.apply(command)
		trace.chosen_commands.append(command.to_dictionary())
		trace.gateway_results.append(result.is_accepted)
		if not result.is_accepted:
			trace.legality_rejections.append({"command":command.to_dictionary(),"code":String(result.code)})
			trace.stop_reason = &"gateway_rejected"
			break
		if command.command_type == DefenseCommandScript.RESERVE_BUDGET:
			trace.stop_reason = &"reserve_intention"
			break
	if trace.stop_reason == &"": trace.stop_reason = &"action_cap"
	trace.remaining_budget = gateway.get_budget()
	return trace

func _candidates(catalog: ContentCatalog, rules: MatchRulesDefinition, gateway, allow_sales: bool) -> Array:
	var result: Array = []
	var map: MapDefinition = catalog.get_map(rules.map_id)
	var towers: Array[TowerDefinition] = []
	for id: StringName in rules.tower_ids: towers.append(catalog.get_tower(id))
	towers.sort_custom(func(a: TowerDefinition, b: TowerDefinition) -> bool: return a.content_id < b.content_id)
	var command_id: int = 1
	for slot: BuildSlotDefinition in map.build_slots:
		for tower: TowerDefinition in towers:
			var command = DefenseCommandScript.new(command_id, DefenseCommandScript.PLACE_TOWER, tower.content_id, slot.slot_id)
			if gateway.is_legal(command): _append_candidate(result, command, tower, 0)
			command_id += 1
	for deployment: TowerDeployment in gateway.get_deployments():
		var tower: TowerDefinition = catalog.get_tower(deployment.tower_id)
		if tower.upgrade_to_id != &"":
			var upgrade_command = DefenseCommandScript.new(command_id, DefenseCommandScript.UPGRADE_TOWER, tower.upgrade_to_id, deployment.slot_id)
			if gateway.is_legal(upgrade_command): _append_candidate(result, upgrade_command, catalog.get_tower(tower.upgrade_to_id), 20)
			command_id += 1
		# Keep a visible, playable defense anchor between rounds. Adaptation may
		# replace or improve towers, but it must not sell the final tower away.
		if allow_sales and gateway.get_deployments().size() > 1:
			var sell_command = DefenseCommandScript.new(command_id, DefenseCommandScript.SELL_TOWER, tower.content_id, deployment.slot_id)
			if gateway.is_legal(sell_command): _append_candidate(result, sell_command, tower, -20)
			command_id += 1
	if gateway.get_budget() * 10000 <= rules.adaptation_grant * 10000:
		var reserve_command = DefenseCommandScript.new(command_id, DefenseCommandScript.RESERVE_BUDGET)
		if gateway.is_legal(reserve_command): _append_candidate(result, reserve_command, null, -10000)
	return result

func _append_candidate(result: Array, command, tower: TowerDefinition, adjustment: int) -> void:
	var coverage: int = 0 if tower == null else tower.range / 10
	var leak_risk: int = 0 if tower == null else tower.damage + (100 if tower.targeting_kind == TowerDefinition.TARGET_CONTROL else 0)
	result.append({"command":command,"coverage":coverage,"leak_risk":leak_risk,"score":coverage + leak_risk + adjustment})

func _candidate_before(left: Dictionary, right: Dictionary) -> bool:
	if int(left["score"]) != int(right["score"]): return int(left["score"]) > int(right["score"])
	var left_command = left["command"]
	var right_command = right["command"]
	if left_command.command_type != right_command.command_type: return left_command.command_type < right_command.command_type
	if left_command.slot_id != right_command.slot_id: return left_command.slot_id < right_command.slot_id
	return left_command.tower_id < right_command.tower_id
