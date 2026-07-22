extends "res://tests/framework/test_case.gd"


func test_headless_phase_boundary_commands_produce_ordered_transitions() -> void:
	var state := MatchState.new(731)
	var reveal_result := state.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))
	var author_result := state.apply_phase_command(PhaseCommand.new(
		2,
		PhaseCommand.BEGIN_WAVE_AUTHORING,
		MatchPhase.DEFENSE_REVEAL,
		PhaseCommand.ACTOR_PLAYER,
	))

	assert_true(reveal_result.is_accepted)
	assert_true(author_result.is_accepted)
	assert_equal(state.get_phase(), MatchPhase.WAVE_AUTHORING)
	var events: Array[DomainEvent] = state.get_events()
	assert_equal(events.size(), 2)
	assert_equal(events[0].tick, 0)
	assert_equal(events[0].ordinal, 0)
	assert_equal(events[1].tick, 0)
	assert_equal(events[1].ordinal, 1)
	assert_equal(events[0].data["from"], "initial_defense")
	assert_equal(events[1].data["to"], "wave_authoring")


func test_phase_command_rejects_the_wrong_actor_without_mutation() -> void:
	var state := MatchState.new(731)
	var result := state.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_PLAYER,
	))

	assert_false(result.is_accepted)
	assert_equal(result.code, CommandResult.CODE_FORBIDDEN_ACTOR)
	assert_equal(state.get_phase(), MatchPhase.INITIAL_DEFENSE)
	assert_equal(state.get_events().size(), 0)


func test_target_ties_end_with_the_lowest_stable_entity_id() -> void:
	var candidates: Array[TargetCandidate] = [
		TargetCandidate.new(9, 25),
		TargetCandidate.new(7, 10),
		TargetCandidate.new(2, 10),
	]

	var selected: TargetCandidate = StableOrder.first_target(candidates)

	assert_equal(selected.remaining_route_distance, 10)
	assert_equal(selected.entity_id, 2)


func test_named_rng_streams_do_not_depend_on_cross_stream_draw_order() -> void:
	var first := MatchSeed.new(8801)
	var first_defender_draw: int = first.next_int(&"defender_variation", 0, 1000000)
	var first_rules_draw: int = first.next_int(&"rules", 0, 1000000)

	var second := MatchSeed.new(8801)
	var second_rules_draw: int = second.next_int(&"rules", 0, 1000000)
	var second_defender_draw: int = second.next_int(&"defender_variation", 0, 1000000)

	assert_equal(first_defender_draw, second_defender_draw)
	assert_equal(first_rules_draw, second_rules_draw)
	assert_not_equal(first.stream_seed(&"rules"), first.stream_seed(&"defender_variation"))
