extends "res://tests/framework/test_case.gd"


func test_draft_uses_catalog_costs_defaults_and_round_budget() -> void:
	var draft: WaveDraft = _new_draft()
	assert_equal(draft.get_budget(), 100)
	assert_true(draft.add_unit(&"unit.swarm").is_accepted)
	assert_true(draft.add_unit(&"unit.runner").is_accepted)
	assert_true(draft.add_unit(&"unit.tank").is_accepted)

	var entries: Array[WaveDraftEntry] = draft.get_entries()
	var validation: WaveDraftValidation = draft.validate()
	assert_equal(entries.size(), 3)
	assert_equal(entries[0].get_route_id(), &"route.north")
	assert_equal(entries[0].get_spacing_after_previous(), WaveDraft.SPACING_STANDARD)
	assert_equal(validation.get_total_cost(), 50)
	assert_equal(validation.get_remaining_budget(), 50)
	assert_true(validation.is_valid())


func test_draft_reorders_spacing_and_undo_redo_are_isolated() -> void:
	var draft: WaveDraft = _new_draft()
	draft.add_unit(&"unit.swarm")
	draft.add_unit(&"unit.runner")
	draft.add_unit(&"unit.support")
	var entries: Array[WaveDraftEntry] = draft.get_entries()
	var support_id: int = entries[2].get_entry_id()
	var runner_id: int = entries[1].get_entry_id()

	assert_true(draft.move_entry(support_id, -1).is_accepted)
	assert_true(draft.set_spacing(support_id, WaveDraft.SPACING_WIDE).is_accepted)
	assert_equal(draft.get_entries()[1].get_unit_id(), &"unit.support")
	assert_equal(draft.get_entries()[1].get_spacing_after_previous(), WaveDraft.SPACING_WIDE)
	assert_true(draft.undo().is_accepted)
	assert_equal(draft.get_entries()[1].get_spacing_after_previous(), WaveDraft.SPACING_STANDARD)
	assert_true(draft.redo().is_accepted)
	assert_equal(draft.get_entries()[1].get_spacing_after_previous(), WaveDraft.SPACING_WIDE)
	assert_not_equal(draft.get_entries()[1].get_entry_id(), runner_id)


func test_over_budget_draft_stays_editable_and_reports_actionable_feedback() -> void:
	var draft: WaveDraft = _new_draft()
	for index: int in 4:
		assert_true(draft.add_unit(&"unit.tank").is_accepted)
	var validation: WaveDraftValidation = draft.validate()

	assert_false(validation.is_valid())
	assert_equal(validation.get_total_cost(), 120)
	assert_equal(validation.get_remaining_budget(), -20)
	assert_true(validation.get_summary().contains("Over budget by 20 points."))
	assert_true(draft.remove_entry(draft.get_entries()[3].get_entry_id()).is_accepted)
	assert_true(draft.validate().is_valid())


func test_two_distinct_valid_wave_shapes_can_be_authored_in_one_session() -> void:
	var draft: WaveDraft = _new_draft()
	var first_wave_units: Array[StringName] = [
		&"unit.swarm",
		&"unit.runner",
		&"unit.support",
		&"unit.tank",
	]
	for unit_id: StringName in first_wave_units:
		assert_true(draft.add_unit(unit_id).is_accepted)
	assert_true(draft.validate().is_valid())
	assert_equal(draft.validate().get_total_cost(), 70)

	assert_true(draft.clear().is_accepted)
	for index: int in 6:
		assert_true(draft.add_unit(&"unit.runner").is_accepted)
	assert_true(draft.validate().is_valid())
	assert_equal(draft.validate().get_total_cost(), 90)
	assert_equal(draft.get_entries().size(), 6)


func test_invalid_operations_do_not_mutate_or_expand_the_draft() -> void:
	var draft: WaveDraft = _new_draft()
	var missing: WaveDraftEditResult = draft.add_unit(&"unit.missing")
	assert_false(missing.is_accepted)
	assert_equal(missing.code, WaveDraftEditResult.CODE_UNIT_NOT_ALLOWED)
	assert_equal(draft.get_entries().size(), 0)
	assert_false(draft.set_spacing(99, 7).is_accepted)
	assert_false(draft.undo().is_accepted)
	assert_false(draft.redo().is_accepted)


func test_composer_panel_transitions_from_reveal_and_edits_a_wave() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	var coordinator := main.get_node("MatchCoordinator") as MatchCoordinator
	var composer: WaveComposerPanel = main.get_wave_composer_panel()

	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.DEFENSE_REVEAL)
	assert_false(composer.visible)
	main.begin_authoring_for_visual_check()
	assert_equal(coordinator.get_current_view().get_phase(), MatchPhase.WAVE_AUTHORING)
	assert_true(composer.visible)
	assert_true(composer.add_unit(&"unit.tank").is_accepted)
	assert_true(composer.add_unit(&"unit.tank").is_accepted)
	assert_true(composer.add_unit(&"unit.tank").is_accepted)
	assert_true(composer.add_unit(&"unit.tank").is_accepted)
	assert_equal(composer.get_draft_entries().size(), 4)
	assert_false(composer.get_validation().is_valid())
	assert_true(composer.get_feedback_text().contains("Over budget by 20 points."))
	assert_true(composer.set_selected_spacing(WaveDraft.SPACING_TIGHT).is_accepted)
	assert_equal(
		composer.get_draft_entries()[3].get_spacing_after_previous(),
		WaveDraft.SPACING_TIGHT,
	)
	assert_true(composer.undo().is_accepted)
	assert_equal(
		composer.get_draft_entries()[3].get_spacing_after_previous(),
		WaveDraft.SPACING_STANDARD,
	)
	main.free()


func _new_draft() -> WaveDraft:
	var catalog := ContentCatalog.load_from_directory("res://content")
	return WaveDraft.new(catalog, catalog.rules[0], 1)
