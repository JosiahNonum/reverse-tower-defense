class_name BalanceMatrixRunner
extends RefCounted

const MatchCoordinatorScript = preload("res://src/application/match_coordinator.gd")
const SPACINGS: Array[int] = [WaveDraft.SPACING_TIGHT, WaveDraft.SPACING_STANDARD, WaveDraft.SPACING_WIDE]
const ROUTES: Array[StringName] = [&"route.north", &"route.south"]
const PROFILES: Array[StringName] = [&"profile.easy", &"profile.normal", &"profile.hard"]
const SHAPES: Array[StringName] = [&"unit.swarm", &"unit.runner", &"unit.tank", &"unit.support"]


func run(catalog: ContentCatalog, rules: MatchRulesDefinition) -> Dictionary:
	var rows: Array[Dictionary] = []
	var shape_outcomes: Dictionary[StringName, Dictionary] = {}
	for profile: StringName in PROFILES:
		for shape: StringName in SHAPES:
			for route: StringName in ROUTES:
				for spacing: int in SPACINGS:
					var result: Dictionary = _run_match(catalog, rules, profile, shape, route, spacing, rows.size() + 1)
					rows.append(result)
					if not shape_outcomes.has(shape):
						shape_outcomes[shape] = {"matches": 0, "player_wins": 0, "core_integrity_total": 0}
					var aggregate: Dictionary = shape_outcomes[shape]
					aggregate["matches"] += 1
					aggregate["player_wins"] += 1 if result["outcome"] == "player_win" else 0
					aggregate["core_integrity_total"] += result["core_integrity"]
	var universal_attacker_shapes: Array[String] = []
	var unreachable_shapes: Array[String] = []
	for shape: StringName in SHAPES:
		var summary: Dictionary = shape_outcomes[shape]
		if summary["player_wins"] == summary["matches"]:
			universal_attacker_shapes.append(String(shape))
		if summary["player_wins"] == 0:
			unreachable_shapes.append(String(shape))
	return {
		"case_count": rows.size(),
		"rows": rows,
		"shape_outcomes": shape_outcomes,
		"universal_attacker_shapes": universal_attacker_shapes,
		"unreachable_shapes": unreachable_shapes,
	}


func _run_match(catalog: ContentCatalog, rules: MatchRulesDefinition, profile: StringName, shape: StringName, route: StringName, spacing: int, seed: int) -> Dictionary:
	var coordinator = MatchCoordinatorScript.new()
	coordinator.initialize(catalog, rules, seed, profile)
	var initial_deployment_count: int = coordinator.get_defender_deployments().size()
	var command_id: int = 1
	_assert_accepted(coordinator.apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)))
	command_id += 1
	while coordinator.get_match_outcome() == &"":
		_assert_accepted(coordinator.apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.BEGIN_WAVE_AUTHORING, MatchPhase.DEFENSE_REVEAL, PhaseCommand.ACTOR_PLAYER)))
		command_id += 1
		var entries := _entries_for_budget(catalog, rules.attack_budgets[coordinator.get_round_index() - 1], shape, route, spacing)
		_assert_accepted(coordinator.commit_wave(PhaseCommand.new(command_id, PhaseCommand.COMMIT_WAVE, MatchPhase.WAVE_AUTHORING, PhaseCommand.ACTOR_PLAYER), entries))
		command_id += 1
		_assert_accepted(coordinator.begin_resolution(PhaseCommand.new(command_id, PhaseCommand.BEGIN_RESOLUTION, MatchPhase.WAVE_COMMITTED, PhaseCommand.ACTOR_SYSTEM)))
		command_id += 1
		while not coordinator.advance_resolution_tick():
			pass
		_assert_accepted(coordinator.apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM)))
		command_id += 1
		var analysis = coordinator.get_post_wave_analysis()
		if coordinator.get_match_outcome() == &"":
			_assert_accepted(coordinator.complete_analysis(command_id))
			command_id += 2
		else:
			_assert_accepted(coordinator.complete_analysis(command_id))
			command_id += 1
	var latest_analysis = coordinator.get_post_wave_analysis()
	var result := {
		"profile": String(profile), "shape": String(shape), "route": String(route), "spacing": spacing,
		"outcome": String(coordinator.get_match_outcome()), "core_integrity": latest_analysis.get_core_integrity(),
		"last_round_leaks": latest_analysis.get_leak_count(), "trace_count": coordinator.get_decision_traces().size(),
		"initial_deployment_count": initial_deployment_count,
	}
	coordinator.free()
	return result


func _entries_for_budget(catalog: ContentCatalog, budget: int, unit_id: StringName, route: StringName, spacing: int) -> Array[WaveDraftEntry]:
	var cost: int = catalog.get_unit(unit_id).cost
	var entries: Array[WaveDraftEntry] = []
	for index: int in budget / cost:
		entries.append(WaveDraftEntry.new(index + 1, unit_id, route, spacing))
	return entries


func _assert_accepted(result: CommandResult) -> void:
	assert(result.is_accepted, result.message)
