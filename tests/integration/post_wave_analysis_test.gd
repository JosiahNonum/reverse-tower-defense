extends "res://tests/framework/test_case.gd"

const PostWaveAnalysisScript = preload("res://src/application/post_wave_analysis.gd")
const MatchCoordinatorScript = preload("res://src/application/match_coordinator.gd")


func test_analysis_reports_only_event_backed_damage_deaths_and_leaks() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var entries: Array[WaveScheduleEntry] = [WaveScheduleEntry.new(&"unit.runner", &"route.north", 0)]
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(entries, catalog, catalog.get_map(rules.map_id))
	var simulation := FixedDefenseSimulation.new(1, catalog, rules, schedule, [])
	while not simulation.is_resolved():
		simulation.advance_one_tick()
	var analysis := PostWaveAnalysisScript.new(simulation)
	assert_equal(analysis.get_leak_count(), 1)
	assert_equal(analysis.get_survivor_count(), 0)
	assert_equal(analysis.get_core_integrity(), 8)
	assert_true(analysis.get_damage_by_tower().is_empty())
	assert_true(analysis.get_damage_by_location().is_empty())


func test_coordinator_only_exposes_analysis_after_resolution() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var coordinator = MatchCoordinatorScript.new()
	coordinator.initialize(catalog, rules, 2)
	coordinator.configure_fixed_defense([])
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(1, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(2, PhaseCommand.BEGIN_WAVE_AUTHORING, MatchPhase.DEFENSE_REVEAL, PhaseCommand.ACTOR_PLAYER)).is_accepted)
	var entries: Array[WaveDraftEntry] = [WaveDraftEntry.new(1, &"unit.runner", &"route.north", 15)]
	assert_true(coordinator.commit_wave(PhaseCommand.new(3, PhaseCommand.COMMIT_WAVE, MatchPhase.WAVE_AUTHORING, PhaseCommand.ACTOR_PLAYER), entries).is_accepted)
	assert_true(coordinator.begin_resolution(PhaseCommand.new(4, PhaseCommand.BEGIN_RESOLUTION, MatchPhase.WAVE_COMMITTED, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	while not coordinator.advance_resolution_tick():
		pass
	assert_true(coordinator.apply_phase_command(PhaseCommand.new(5, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	var analysis = coordinator.call("get_post_wave_analysis")
	assert_equal(analysis.get_leak_count(), 1)
