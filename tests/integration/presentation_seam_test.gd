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
	assert_equal(battlefield.get_visual_kind(1), &"unit")
	assert_equal(battlefield.get_visual_kind(3), &"unit")
	assert_equal(battlefield.get_last_tick(), 1)
	assert_equal(battlefield.get_consumed_event_count(), 3)
	battlefield.free()

func test_battlefield_draws_visible_entities_and_attack_feedback() -> void:
	var battlefield := BattlefieldView.new()
	var entities: Array[EntityView] = [
		EntityView.new(1, &"tower", 1200, 1500),
		EntityView.new(2, &"unit", 1600, 1500, 75, 100),
	]
	var attack := DomainEvent.new(2, 0, &"tower_attacked", {
		"tower_entity_id": 1,
		"victim_ids": [2],
	})
	battlefield.reconcile(MatchView.new(MatchPhase.RESOLVING, 2, 2, entities), [attack])

	assert_equal(battlefield.get_visual_kind(1), &"tower")
	assert_equal(battlefield.get_visual_kind(2), &"unit")
	assert_equal(battlefield.get_attack_feedback_count(), 1)
	assert_equal(battlefield.get_projectile_count(), 1)
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
	var battlefield := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Body/BattlefieldPanel/MapLayout/DefenseMapView/BattlefieldView",
	) as BattlefieldView
	assert_true(coordinator.is_initialized())
	assert_equal(coordinator.get_rules_id(), &"rules.v0")
	assert_equal(coordinator.get_content_fingerprint().length(), 64)
	assert_equal(coordinator.get_current_view().get_tick(), 0)
	assert_true(coordinator.get_defender_deployments().size() > 0)
	assert_true(main.get_defense_inspection_model().get_towers().size() > 0)
	assert_equal(battlefield.get_last_tick(), 0)
	main.free()

func test_main_scene_can_advance_to_next_round_without_map_redraw_type_error() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	main.begin_authoring_for_visual_check()
	var composer := main.get_wave_composer_panel()
	assert_true(composer.add_unit(&"unit.runner").is_accepted)
	assert_true(composer.request_commit())
	var coordinator := main.get_node("MatchCoordinator") as MatchCoordinator
	while not coordinator.get_active_simulation().is_resolved():
		coordinator.advance_resolution_tick()
	main._finish_resolution()
	main._on_continue_button_pressed()
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
	main.free()

func test_two_round_composed_playthrough_keeps_feedback_and_defense_visible() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	var coordinator := main.get_node("MatchCoordinator") as MatchCoordinator
	var battlefield := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Body/BattlefieldPanel/MapLayout/DefenseMapView/BattlefieldView",
	) as BattlefieldView

	for round_index: int in 2:
		main.begin_authoring_for_visual_check()
		var composer := main.get_wave_composer_panel()
		for unit_index: int in 6:
			assert_true(composer.add_unit(&"unit.swarm").is_accepted)
		assert_true(composer.request_commit())
		while not coordinator.get_active_simulation().is_resolved():
			coordinator.advance_resolution_tick()
		assert_true(battlefield.get_visual_count() > 0, "round %d should retain runtime visuals" % (round_index + 1))
		assert_true(battlefield.get_attack_event_count() > 0, "round %d should publish tower attack feedback" % (round_index + 1))
		main._finish_resolution()
		if round_index == 0:
			main._on_continue_button_pressed()
			assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
			assert_true(main.get_defense_inspection_model().get_towers().size() > 0)
			assert_equal(battlefield.get_visual_count(), 0)
			assert_equal(battlefield.get_projectile_count(), 0)

	main.free()

func test_four_round_main_scene_progression_keeps_phase_and_authoring_ui_in_sync() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	var coordinator := main.get_node("MatchCoordinator") as MatchCoordinator
	var phase_value := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Header/PhaseBlock/PhaseValue",
	) as Label
	var begin_button := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Header/PhaseBlock/BeginAuthoringButton",
	) as Button
	var continue_button := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Header/PhaseBlock/ContinueButton",
	) as Button
	var inspection_panel := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Body/DefenseInspectionPanel",
	) as Control
	var composer := main.get_wave_composer_panel()

	for round_index: int in 4:
		assert_equal(coordinator.get_round_index(), round_index + 1)
		assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
		assert_true(phase_value.text.contains("ROUND %d" % (round_index + 1)))
		assert_true(begin_button.visible)
		assert_true(inspection_panel.visible)
		assert_false(composer.visible)
		main.begin_authoring_for_visual_check()
		assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.WAVE_AUTHORING)
		assert_true(composer.visible)
		assert_true(composer.add_unit(&"unit.swarm").is_accepted)
		assert_true(composer.request_commit())
		while not coordinator.get_active_simulation().is_resolved():
			coordinator.advance_resolution_tick()
		main._finish_resolution()
		assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.ANALYSIS)
		assert_true(continue_button.visible)
		assert_equal(continue_button.text, "NEXT ROUND")
		main._on_continue_button_pressed()

	assert_equal(coordinator.get_round_index(), 5)
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
	main.free()

func test_terminal_round_uses_result_state_before_offering_restart() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	var coordinator := main.get_node("MatchCoordinator") as MatchCoordinator
	var phase_value := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Header/PhaseBlock/PhaseValue",
	) as Label
	var continue_button := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Header/PhaseBlock/ContinueButton",
	) as Button
	var inspection_panel := main.get_node(
		"MatchScreen/SafeArea/RootLayout/Body/DefenseInspectionPanel",
	) as Control

	for round_index: int in 5:
		main.begin_authoring_for_visual_check()
		var composer := main.get_wave_composer_panel()
		assert_true(composer.add_unit(&"unit.swarm").is_accepted)
		assert_true(composer.request_commit())
		while not coordinator.get_active_simulation().is_resolved():
			coordinator.advance_resolution_tick()
		main._finish_resolution()
		if round_index < 4:
			main._on_continue_button_pressed()

	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.ANALYSIS)
	assert_equal(continue_button.text, "VIEW RESULT")
	assert_true(phase_value.text.contains("FINAL ANALYSIS"))
	main._on_continue_button_pressed()
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.MATCH_END)
	assert_equal(continue_button.text, "RESTART")
	assert_true(phase_value.text.contains("MATCH COMPLETE"))
	assert_true(inspection_panel.visible)
	main._on_continue_button_pressed()
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
	assert_equal(coordinator.get_round_index(), 1)
	assert_true(phase_value.text.contains("ROUND 1"))
	assert_false(continue_button.visible)
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
