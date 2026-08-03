extends "res://tests/framework/test_case.gd"

const MatchCoordinatorScript = preload("res://src/application/match_coordinator.gd")


func test_five_round_scripted_match_reaches_defender_win_and_preserves_core() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var coordinator = MatchCoordinatorScript.new()
	coordinator.initialize(catalog, rules, 11)
	coordinator.configure_fixed_defense([])
	var command_id: int = 1
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	command_id += 1
	for round_index: int in rules.round_count:
		assert_true(coordinator.apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.BEGIN_WAVE_AUTHORING, MatchPhase.DEFENSE_REVEAL, PhaseCommand.ACTOR_PLAYER)).is_accepted)
		command_id += 1
		var entries: Array[WaveDraftEntry] = [WaveDraftEntry.new(1, &"unit.swarm", &"route.north", 15)]
		assert_true(coordinator.commit_wave(PhaseCommand.new(command_id, PhaseCommand.COMMIT_WAVE, MatchPhase.WAVE_AUTHORING, PhaseCommand.ACTOR_PLAYER), entries).is_accepted)
		command_id += 1
		assert_true(coordinator.begin_resolution(PhaseCommand.new(command_id, PhaseCommand.BEGIN_RESOLUTION, MatchPhase.WAVE_COMMITTED, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
		command_id += 1
		while not coordinator.advance_resolution_tick():
			pass
		assert_true(coordinator.apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
		command_id += 1
		assert_true(coordinator.complete_analysis(command_id).is_accepted)
		command_id += 2 if round_index < rules.round_count - 1 else 1
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.MATCH_END)
	assert_equal(coordinator.call("get_match_outcome"), &"defender_win")


func test_core_zero_ends_the_match_with_player_win_after_first_wave() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var coordinator = MatchCoordinatorScript.new()
	coordinator.initialize(catalog, rules, 12)
	coordinator.configure_fixed_defense([])
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(1, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(2, PhaseCommand.BEGIN_WAVE_AUTHORING, MatchPhase.DEFENSE_REVEAL, PhaseCommand.ACTOR_PLAYER)).is_accepted)
	var entries: Array[WaveDraftEntry] = []
	for index: int in 5:
		entries.append(WaveDraftEntry.new(index + 1, &"unit.runner", &"route.north", 15))
	assert_true(coordinator.commit_wave(PhaseCommand.new(3, PhaseCommand.COMMIT_WAVE, MatchPhase.WAVE_AUTHORING, PhaseCommand.ACTOR_PLAYER), entries).is_accepted)
	assert_true(coordinator.begin_resolution(PhaseCommand.new(4, PhaseCommand.BEGIN_RESOLUTION, MatchPhase.WAVE_COMMITTED, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	while not coordinator.advance_resolution_tick():
		pass
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(5, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(coordinator.complete_analysis(6).is_accepted)
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.MATCH_END)
	assert_equal(coordinator.call("get_match_outcome"), &"player_win")


func test_restart_discards_match_damage_and_returns_to_initial_defense() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var coordinator = MatchCoordinatorScript.new()
	coordinator.initialize(catalog, catalog.rules[0], 99)
	coordinator.configure_fixed_defense([])
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(1, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	coordinator.restart()
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.INITIAL_DEFENSE)
	assert_equal(coordinator.get_current_view().get_tick(), 0)
	assert_equal(coordinator.call("get_match_outcome"), &"")
