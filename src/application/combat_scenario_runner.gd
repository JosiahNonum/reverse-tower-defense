class_name CombatScenarioRunner
extends RefCounted


func run_json(json_text: String, catalog: ContentCatalog) -> CombatScenarioResult:
	var parse_result: Dictionary = CombatScenarioArtifact.from_json(json_text)
	if not parse_result["is_success"]:
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_MALFORMED_ARTIFACT,
			"%s: %s" % [parse_result["code"], parse_result["message"]],
		)
	return run(parse_result["artifact"], catalog)


func run(
	artifact: CombatScenarioArtifact,
	catalog: ContentCatalog,
) -> CombatScenarioResult:
	if artifact.schema_version != CombatScenarioArtifact.CURRENT_SCHEMA_VERSION:
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_SCHEMA_MISMATCH,
			"artifact schema %d is incompatible with supported schema %d" % [
				artifact.schema_version,
				CombatScenarioArtifact.CURRENT_SCHEMA_VERSION,
			],
		)
	var validation: ContentValidationResult = catalog.validate()
	if not validation.is_valid():
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_CONTENT_MISMATCH,
			"current content catalog is invalid",
		)
	var rules: MatchRulesDefinition = catalog.get_rules(artifact.rules_id)
	if rules == null or rules.rules_version != artifact.rules_version:
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_RULES_MISMATCH,
			"artifact rules '%s' version '%s' do not match current content" % [
				artifact.rules_id,
				artifact.rules_version,
			],
		)
	if artifact.content_fingerprint != catalog.content_fingerprint():
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_CONTENT_MISMATCH,
			"artifact content fingerprint does not match current content",
		)
	var map: MapDefinition = catalog.get_map(rules.map_id)
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(
		artifact.wave_entries,
		catalog,
		map,
	)
	if not schedule.is_accepted:
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_SCHEDULE_REJECTED,
			"%s: %s" % [schedule.code, schedule.message],
		)
	var deployment_error: String = _deployment_error(
		artifact.tower_deployments,
		catalog,
		map,
	)
	if not deployment_error.is_empty():
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_DEPLOYMENT_REJECTED,
			deployment_error,
		)

	var simulation := FixedDefenseSimulation.new(
		artifact.root_seed,
		catalog,
		rules,
		schedule,
		artifact.tower_deployments,
	)
	while not simulation.is_resolved() and simulation.get_tick() < artifact.maximum_ticks:
		simulation.advance_one_tick()
	var summary := CombatTelemetrySummary.from_simulation(
		artifact.scenario_id,
		simulation,
	)
	if not simulation.is_resolved():
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_TIMEOUT,
			"scenario did not resolve within %d ticks" % artifact.maximum_ticks,
			summary,
		)
	var differences: Array[String] = SemanticResultDiff.compare(
		artifact.expected_summary,
		summary.to_dictionary(),
	)
	if not differences.is_empty():
		return CombatScenarioResult.reject(
			CombatScenarioResult.CODE_RESULT_MISMATCH,
			"semantic summary differs:\n%s" % "\n".join(differences),
			summary,
		)
	return CombatScenarioResult.accept(summary)


func _deployment_error(
	deployments: Array[TowerDeployment],
	catalog: ContentCatalog,
	map: MapDefinition,
) -> String:
	var occupied_slots: Dictionary[StringName, bool] = {}
	for deployment: TowerDeployment in deployments:
		if catalog.get_tower(deployment.tower_id) == null:
			return "unknown tower '%s'" % deployment.tower_id
		if _find_slot(map, deployment.slot_id) == null:
			return "unknown tower slot '%s'" % deployment.slot_id
		if occupied_slots.has(deployment.slot_id):
			return "tower slot '%s' is occupied more than once" % deployment.slot_id
		occupied_slots[deployment.slot_id] = true
	return ""


func _find_slot(map: MapDefinition, slot_id: StringName) -> BuildSlotDefinition:
	for slot: BuildSlotDefinition in map.build_slots:
		if slot.slot_id == slot_id:
			return slot
	return null
