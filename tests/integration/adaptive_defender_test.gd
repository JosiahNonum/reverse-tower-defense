extends "res://tests/framework/test_case.gd"

const MatchCoordinatorScript = preload("res://src/application/match_coordinator.gd")

func test_adaptation_is_headless_repeatable_and_restart_clears_prior_history() -> void:
	var first = _run_one_round(73)
	var second = _run_one_round(73)
	assert_equal(first["trace"].to_dictionary(), second["trace"].to_dictionary())
	assert_true(first["trace"].chosen_commands.size() > 0)
	assert_true(first["coordinator"].get_defender_deployments().size() > 0)
	assert_true(first["coordinator"].get_latest_defense_explanation().contains("public") or first["coordinator"].get_latest_defense_explanation().contains("leaks"))
	first["coordinator"].restart()
	var traces: Array = first["coordinator"].get_decision_traces()
	assert_equal(traces.size(), 1)
	assert_equal(traces[0].visible_rounds.size(), 0)
	first["coordinator"].free()
	second["coordinator"].free()

func _run_one_round(seed: int) -> Dictionary:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var coordinator = MatchCoordinatorScript.new()
	coordinator.initialize(catalog, rules, seed)
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(1, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(2, PhaseCommand.BEGIN_WAVE_AUTHORING, MatchPhase.DEFENSE_REVEAL, PhaseCommand.ACTOR_PLAYER)).is_accepted)
	assert_true(coordinator.commit_wave(PhaseCommand.new(3, PhaseCommand.COMMIT_WAVE, MatchPhase.WAVE_AUTHORING, PhaseCommand.ACTOR_PLAYER), [WaveDraftEntry.new(1, &"unit.runner", &"route.north", 15)]).is_accepted)
	assert_true(coordinator.begin_resolution(PhaseCommand.new(4, PhaseCommand.BEGIN_RESOLUTION, MatchPhase.WAVE_COMMITTED, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	while not coordinator.advance_resolution_tick(): pass
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(5, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(coordinator.complete_analysis(6).is_accepted)
	var traces: Array = coordinator.get_decision_traces()
	return {"coordinator":coordinator,"trace":traces.back()}
