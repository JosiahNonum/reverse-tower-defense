extends "res://tests/framework/test_case.gd"

const PlaybackControllerScript = preload("res://src/application/playback_controller.gd")


func test_phase_machine_rejects_skips_and_completes_resolution_in_order() -> void:
	var state := MatchState.new(1)
	assert_false(state.apply_phase_command(PhaseCommand.new(1, PhaseCommand.COMMIT_WAVE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_PLAYER)).is_accepted)
	assert_true(state.apply_phase_command(PhaseCommand.new(1, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(state.apply_phase_command(PhaseCommand.new(2, PhaseCommand.BEGIN_WAVE_AUTHORING, MatchPhase.DEFENSE_REVEAL, PhaseCommand.ACTOR_PLAYER)).is_accepted)
	assert_true(state.apply_phase_command(PhaseCommand.new(3, PhaseCommand.COMMIT_WAVE, MatchPhase.WAVE_AUTHORING, PhaseCommand.ACTOR_PLAYER)).is_accepted)
	assert_true(state.apply_phase_command(PhaseCommand.new(4, PhaseCommand.BEGIN_RESOLUTION, MatchPhase.WAVE_COMMITTED, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_true(state.apply_phase_command(PhaseCommand.new(5, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM)).is_accepted)
	assert_equal(state.get_phase(), MatchPhase.ANALYSIS)


func test_playback_rate_changes_tick_delivery_not_semantic_tick_order() -> void:
	var controller := PlaybackControllerScript.new()
	assert_equal(controller.consume_ticks(0.05, 20), 1)
	assert_true(controller.set_speed(4))
	assert_equal(controller.consume_ticks(0.05, 20), 4)
	controller.set_paused(true)
	assert_equal(controller.consume_ticks(2.0, 20), 0)
	assert_false(controller.set_speed(3))
