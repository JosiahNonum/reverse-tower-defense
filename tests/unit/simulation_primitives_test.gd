extends "res://tests/framework/test_case.gd"


func test_same_seed_and_commands_produce_identical_results_and_event_digest() -> void:
	var first: MatchState = _run_foundation_scenario(4402)
	var second: MatchState = _run_foundation_scenario(4402)

	assert_equal(first.event_digest(), second.event_digest())
	assert_equal(first.create_wave_result(1).to_json(), second.create_wave_result(1).to_json())
	assert_equal(
		first.create_match_result(&"foundation_complete", 1).to_json(),
		second.create_match_result(&"foundation_complete", 1).to_json(),
	)


func test_different_root_seeds_derive_different_named_streams() -> void:
	var first := MatchSeed.new(4402)
	var second := MatchSeed.new(4403)

	assert_not_equal(first.stream_seed(&"rules"), second.stream_seed(&"rules"))
	assert_not_equal(
		first.stream_seed(&"defender_variation"),
		second.stream_seed(&"defender_variation"),
	)


func test_invalid_and_duplicate_commands_return_structured_codes() -> void:
	var state := MatchState.new(4402)
	var invalid_id := state.apply_phase_command(PhaseCommand.new(
		0,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))
	var wrong_expected_phase := state.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.DEFENSE_REVEAL,
		PhaseCommand.ACTOR_SYSTEM,
	))
	var accepted := state.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))
	var duplicate := state.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.BEGIN_WAVE_AUTHORING,
		MatchPhase.DEFENSE_REVEAL,
		PhaseCommand.ACTOR_PLAYER,
	))

	assert_equal(invalid_id.code, CommandResult.CODE_INVALID_COMMAND_ID)
	assert_equal(wrong_expected_phase.code, CommandResult.CODE_EXPECTED_PHASE_MISMATCH)
	assert_true(accepted.is_accepted)
	assert_equal(duplicate.code, CommandResult.CODE_DUPLICATE_COMMAND)
	assert_equal(state.get_events().size(), 1)


func test_tick_and_ordinal_form_a_total_event_order() -> void:
	var state := MatchState.new(4402)
	_apply_opening_transitions(state)
	state.advance_one_tick()

	var events: Array[DomainEvent] = state.get_events()
	assert_equal(events.size(), 3)
	assert_equal(events[0].tick, 0)
	assert_equal(events[0].ordinal, 0)
	assert_equal(events[1].tick, 0)
	assert_equal(events[1].ordinal, 1)
	assert_equal(events[2].tick, 1)
	assert_equal(events[2].ordinal, 0)


func test_integer_rounding_distance_and_inclusive_range_rules() -> void:
	assert_equal(IntegerMath.multiply_ratio_floor(5, 3, 4), 3)
	assert_equal(IntegerMath.multiply_ratio_floor(125, 60, 100), 75)
	assert_equal(IntegerMath.squared_distance(0, 0, 3, 4), 25)
	assert_true(IntegerMath.is_inside_inclusive_range(25, 5))
	assert_false(IntegerMath.is_inside_inclusive_range(26, 5))


func test_match_instances_and_snapshots_are_independent() -> void:
	var first := MatchState.new(4402)
	var second := MatchState.new(4402)
	var initial_view: MatchView = first.create_view()

	assert_equal(first.allocate_entity_id(), 1)
	first.advance_one_tick()

	assert_equal(first.get_tick(), 1)
	assert_equal(second.get_tick(), 0)
	assert_equal(second.allocate_entity_id(), 1)
	assert_equal(initial_view.get_tick(), 0)
	assert_equal(initial_view.get_allocated_entity_count(), 0)
	assert_equal(first.create_view().get_allocated_entity_count(), 1)


func test_result_summaries_are_json_serializable() -> void:
	var state: MatchState = _run_foundation_scenario(4402)
	var wave_json: String = state.create_wave_result(1).to_json()
	var match_json: String = state.create_match_result(&"foundation_complete", 1).to_json()

	var wave_data: Variant = JSON.parse_string(wave_json)
	var match_data: Variant = JSON.parse_string(match_json)
	assert_true(wave_data is Dictionary)
	assert_true(match_data is Dictionary)
	assert_equal(wave_data["round_index"], 1.0)
	assert_equal(match_data["outcome"], "foundation_complete")
	assert_equal(wave_data["event_digest"], state.event_digest())


func _run_foundation_scenario(root_seed: int) -> MatchState:
	var state := MatchState.new(root_seed)
	_apply_opening_transitions(state)
	state.advance_one_tick()
	state.allocate_entity_id()
	return state


func _apply_opening_transitions(state: MatchState) -> void:
	state.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))
	state.apply_phase_command(PhaseCommand.new(
		2,
		PhaseCommand.BEGIN_WAVE_AUTHORING,
		MatchPhase.DEFENSE_REVEAL,
		PhaseCommand.ACTOR_PLAYER,
	))
