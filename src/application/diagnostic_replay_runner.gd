class_name DiagnosticReplayRunner
extends RefCounted


func replay_json(json_text: String, catalog: ContentCatalog) -> DiagnosticReplayResult:
	var parse_result: DiagnosticReplayArtifactParseResult = DiagnosticReplayArtifact.from_json(json_text)
	if not parse_result.is_success:
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_MALFORMED_ARTIFACT,
			"%s: %s" % [parse_result.code, parse_result.message],
		)
	return replay(parse_result.artifact, catalog)


func replay(
	artifact: DiagnosticReplayArtifact,
	catalog: ContentCatalog,
) -> DiagnosticReplayResult:
	if artifact.schema_version != DiagnosticReplayArtifact.CURRENT_SCHEMA_VERSION:
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_SCHEMA_MISMATCH,
			"artifact schema %d is incompatible with supported schema %d" % [
				artifact.schema_version,
				DiagnosticReplayArtifact.CURRENT_SCHEMA_VERSION,
			],
		)
	if not catalog.validate().is_valid():
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_CONTENT_MISMATCH,
			"current content catalog is invalid",
		)

	var rules: MatchRulesDefinition = catalog.get_rules(artifact.rules_id)
	if rules == null:
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_RULES_MISMATCH,
			"artifact rules ID '%s' is not present" % artifact.rules_id,
		)
	if artifact.rules_version != rules.rules_version:
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_RULES_MISMATCH,
			"artifact rules version '%s' does not match current version '%s'" % [
				artifact.rules_version,
				rules.rules_version,
			],
		)
	var current_fingerprint: String = catalog.content_fingerprint()
	if artifact.content_fingerprint != current_fingerprint:
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_CONTENT_MISMATCH,
			"artifact content fingerprint '%s' does not match current fingerprint '%s'" % [
				artifact.content_fingerprint,
				current_fingerprint,
			],
		)
	if not _content_ids_match(artifact, rules):
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_CONTENT_MISMATCH,
			"artifact content IDs do not match rules '%s'" % rules.content_id,
		)
	if artifact.scenario_id == &"":
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_SCENARIO_MISMATCH,
			"artifact scenario_id must be nonempty",
		)

	var state := MatchState.new(artifact.root_seed)
	for command: PhaseCommand in artifact.commands:
		var command_result: CommandResult = state.apply_phase_command(command)
		if not command_result.is_accepted:
			return DiagnosticReplayResult.reject(
				DiagnosticReplayResult.CODE_COMMAND_REJECTED,
				"command %d was rejected with %s: %s" % [
					command.command_id,
					command_result.code,
					command_result.message,
				],
			)
	for tick_index: int in artifact.ticks_to_advance:
		state.advance_one_tick()

	var actual_summary := DiagnosticReplaySummary.from_state(state)
	if actual_summary.to_dictionary() != artifact.expected_summary.to_dictionary():
		return DiagnosticReplayResult.reject(
			DiagnosticReplayResult.CODE_RESULT_MISMATCH,
			"replay summary differs: expected %s, received %s" % [
				JSON.stringify(artifact.expected_summary.to_dictionary()),
				JSON.stringify(actual_summary.to_dictionary()),
			],
			actual_summary,
		)
	return DiagnosticReplayResult.accept(actual_summary)


func _content_ids_match(
	artifact: DiagnosticReplayArtifact,
	rules: MatchRulesDefinition,
) -> bool:
	return (
		artifact.map_id == rules.map_id
		and artifact.unit_ids == _normalized_ids(rules.unit_ids)
		and artifact.tower_ids == _normalized_ids(rules.tower_ids)
		and artifact.defender_profile_ids == _normalized_ids(rules.defender_profile_ids)
	)


func _normalized_ids(values: Array[StringName]) -> Array[StringName]:
	var normalized: Array[StringName] = values.duplicate()
	normalized.sort()
	return normalized
