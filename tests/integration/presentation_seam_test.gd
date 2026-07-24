extends "res://tests/framework/test_case.gd"

func test_battlefield_reconciles_spawn_update_and_remove_by_stable_id() -> void:
	var battlefield := BattlefieldView.new()
	var first_entities: Array[EntityView] = [
		EntityView.new(1, &"unit", 1000, 2000),
		EntityView.new(2, &"tower", 3000, 1000),
	]
	var first_events: Array[DomainEvent] = [DomainEvent.new(0, 0, &"spawned")]
	battlefield.reconcile(MatchView.new(MatchPhase.RESOLVING, 0, 2, first_entities), first_events)

	assert_equal(battlefield.get_visual_count(), 2)
	assert_true(battlefield.has_visual(1))
	assert_equal(battlefield.get_visual_position(1), Vector2(100, 200))

	var second_entities: Array[EntityView] = [
		EntityView.new(1, &"unit", 1500, 2200),
		EntityView.new(3, &"unit", 500, 500),
	]
	var second_events: Array[DomainEvent] = [
		DomainEvent.new(1, 0, &"moved"),
		DomainEvent.new(1, 1, &"removed"),
	]
	battlefield.reconcile(MatchView.new(MatchPhase.RESOLVING, 1, 3, second_entities), second_events)

	assert_equal(battlefield.get_visual_count(), 2)
	assert_true(battlefield.has_visual(1))
	assert_false(battlefield.has_visual(2))
	assert_true(battlefield.has_visual(3))
	assert_equal(battlefield.get_visual_position(1), Vector2(150, 220))
	assert_equal(battlefield.get_last_tick(), 1)
	assert_equal(battlefield.get_consumed_event_count(), 3)
	battlefield.free()

func test_presentation_receives_copies_and_cannot_mutate_match_state() -> void:
	var state := MatchState.new(77)
	var view: MatchView = state.create_view()
	var serialized: Dictionary = view.to_dictionary()
	serialized["tick"] = 99
	serialized["phase"] = "match_end"
	var battlefield := BattlefieldView.new()
	battlefield.reconcile(view, [])

	assert_equal(state.get_tick(), 0)
	assert_equal(state.get_phase(), MatchPhase.INITIAL_DEFENSE)
	assert_equal(view.get_tick(), 0)
	assert_equal(view.get_phase(), MatchPhase.INITIAL_DEFENSE)
	battlefield.free()

func test_main_scene_composes_coordinator_and_battlefield_explicitly() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()

	var coordinator := main.get_node("MatchCoordinator") as MatchCoordinator
	var battlefield := main.get_node("MatchScreen/BattlefieldView") as BattlefieldView
	assert_true(coordinator.is_initialized())
	assert_equal(coordinator.get_rules_id(), &"rules.v0")
	assert_equal(coordinator.get_content_fingerprint().length(), 64)
	assert_equal(coordinator.get_current_view().get_tick(), 0)
	assert_equal(battlefield.get_last_tick(), 0)
	main.free()

func test_coordinator_runs_headlessly_without_loading_presentation_scene() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var coordinator := MatchCoordinator.new()
	coordinator.initialize(catalog, catalog.rules[0], 77)
	var result: CommandResult = coordinator.apply_phase_command(PhaseCommand.new(
		1,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))

	assert_true(result.is_accepted)
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
	coordinator.advance_one_tick()
	assert_equal(coordinator.get_current_view().get_tick(), 1)
	coordinator.free()
