class_name WaveComposerPanel
extends PanelContainer

signal commit_requested(entries: Array[WaveDraftEntry])

var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _draft: WaveDraft
var _selected_entry_id: int = -1
var _last_selected_spacing: int = WaveDraft.SPACING_STANDARD
var _last_selected_route: StringName = &""


func configure(catalog: ContentCatalog, rules: MatchRulesDefinition, round_index: int = 1) -> void:
	_catalog = catalog
	_rules = rules
	_draft = WaveDraft.new(catalog, rules, round_index)
	_build_unit_buttons()
	_build_spacing_options()
	_build_route_options()
	_refresh()


func get_draft_entries() -> Array[WaveDraftEntry]:
	_assert_configured()
	return _draft.get_entries()


func get_validation() -> WaveDraftValidation:
	_assert_configured()
	return _draft.validate()


func get_feedback_text() -> String:
	return %Feedback.text


func add_unit(unit_id: StringName) -> WaveDraftEditResult:
	_assert_configured()
	var result: WaveDraftEditResult = _draft.add_unit(
		unit_id, 1, _last_selected_route, _last_selected_spacing,
	)
	if result.is_accepted:
		var entries: Array[WaveDraftEntry] = _draft.get_entries()
		var added_entry: WaveDraftEntry = entries[entries.size() - 1]
		_selected_entry_id = added_entry.get_entry_id()
		_last_selected_spacing = added_entry.get_spacing_after_previous()
		_last_selected_route = added_entry.get_route_id()
	_apply_result(result)
	return result


func remove_selected_entry() -> WaveDraftEditResult:
	_assert_configured()
	if _selected_entry_id < 0:
		return _apply_result(WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"Select a draft entry to remove it.",
		))
	var result: WaveDraftEditResult = _draft.remove_entry(_selected_entry_id)
	if result.is_accepted:
		_selected_entry_id = -1
	_apply_result(result)
	return result


func move_selected_entry(offset: int) -> WaveDraftEditResult:
	_assert_configured()
	if _selected_entry_id < 0:
		return _apply_result(WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"Select a draft entry to move it.",
		))
	return _apply_result(_draft.move_entry(_selected_entry_id, offset))


func set_selected_spacing(spacing_ticks: int) -> WaveDraftEditResult:
	_assert_configured()
	if _selected_entry_id < 0:
		return _apply_result(WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"Select a draft entry before changing spacing.",
		))
	var result: WaveDraftEditResult = _draft.set_spacing(_selected_entry_id, spacing_ticks)
	if result.is_accepted:
		_last_selected_spacing = spacing_ticks
	return _apply_result(result)


func set_selected_route(route_id: StringName) -> WaveDraftEditResult:
	_assert_configured()
	if _selected_entry_id < 0:
		return _apply_result(WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"Select a draft entry before changing route.",
		))
	var result: WaveDraftEditResult = _draft.set_route(_selected_entry_id, route_id)
	if result.is_accepted:
		_last_selected_route = route_id
	return _apply_result(result)


func request_commit() -> bool:
	_assert_configured()
	var validation: WaveDraftValidation = _draft.validate()
	if not validation.is_valid():
		%Feedback.text = validation.get_summary()
		return false
	commit_requested.emit(_draft.get_entries())
	return true


func undo() -> WaveDraftEditResult:
	_assert_configured()
	return _apply_result(_draft.undo())


func redo() -> WaveDraftEditResult:
	_assert_configured()
	return _apply_result(_draft.redo())


func clear() -> WaveDraftEditResult:
	_assert_configured()
	_selected_entry_id = -1
	return _apply_result(_draft.clear())


func _build_unit_buttons() -> void:
	for child: Node in %UnitButtons.get_children():
		child.free()
	for unit_id: StringName in _draft.get_available_unit_ids():
		var definition: UnitDefinition = _catalog.get_unit(unit_id)
		var button := Button.new()
		button.text = "+ %s  ·  %d" % [_humanize_id(unit_id), definition.cost]
		button.tooltip_text = "Add one %s for %d points" % [_humanize_id(unit_id), definition.cost]
		button.pressed.connect(func() -> void:
			add_unit(unit_id)
		)
		%UnitButtons.add_child(button)


func _build_spacing_options() -> void:
	%Spacing.clear()
	_add_spacing_option("Tight · 5 ticks", WaveDraft.SPACING_TIGHT)
	_add_spacing_option("Standard · 15 ticks", WaveDraft.SPACING_STANDARD)
	_add_spacing_option("Wide · 30 ticks", WaveDraft.SPACING_WIDE)


func _add_spacing_option(label: String, spacing_ticks: int) -> void:
	%Spacing.add_item(label)
	%Spacing.set_item_metadata(%Spacing.item_count - 1, spacing_ticks)


func _build_route_options() -> void:
	%Route.clear()
	var map: MapDefinition = _catalog.get_map(_rules.map_id)
	for route: RouteDefinition in map.routes:
		%Route.add_item(_humanize_id(route.route_id))
		%Route.set_item_metadata(%Route.item_count - 1, route.route_id)
	if not _has_route_option(_last_selected_route) and %Route.item_count > 0:
		_last_selected_route = %Route.get_item_metadata(0)


func _apply_result(result: WaveDraftEditResult) -> WaveDraftEditResult:
	_refresh()
	var validation: WaveDraftValidation = _draft.validate()
	var feedback: String = result.message if not result.message.is_empty() else validation.get_summary()
	var color: Color = Color("9de2bb") if result.is_accepted else Color("ff9e9e")
	if result.is_accepted and not validation.is_valid():
		feedback = validation.get_summary()
		color = Color("ffcf85")
	%Feedback.text = feedback
	%Feedback.add_theme_color_override(
		"font_color",
		color,
	)
	return result


func _refresh() -> void:
	if _draft == null:
		return
	var validation: WaveDraftValidation = _draft.validate()
	%RoundLabel.text = "ROUND %d  ·  ATTACK BUDGET %d" % [
		_draft.get_round_index(),
		validation.get_budget(),
	]
	%BudgetValue.text = "%d / %d" % [
		validation.get_total_cost(),
		validation.get_budget(),
	]
	%RemainingValue.text = (
		"%d remaining" % validation.get_remaining_budget()
		if validation.get_remaining_budget() >= 0
		else "%d over" % -validation.get_remaining_budget()
	)
	%EntryCount.text = "%d / %d entries" % [
		_draft.get_entries().size(),
		WaveDraft.MAX_ENTRIES,
	]
	%EntryList.clear()
	var selected_index: int = -1
	var entries: Array[WaveDraftEntry] = _draft.get_entries()
	for index: int in entries.size():
		var entry: WaveDraftEntry = entries[index]
		var definition: UnitDefinition = _catalog.get_unit(entry.get_unit_id())
		var gap_label: String = "FIRST · tick 0" if index == 0 else _spacing_label(
			entry.get_spacing_after_previous(),
		)
		%EntryList.add_item("%02d  %s  ·  %s  ·  %s  ·  %d" % [
			index + 1,
			_humanize_id(entry.get_unit_id()),
			_humanize_id(entry.get_route_id()),
			gap_label,
			definition.cost,
		])
		%EntryList.set_item_metadata(index, entry.get_entry_id())
		if entry.get_entry_id() == _selected_entry_id:
			selected_index = index
	if selected_index >= 0:
		%EntryList.select(selected_index)
		_last_selected_spacing = entries[selected_index].get_spacing_after_previous()
		_last_selected_route = entries[selected_index].get_route_id()
		_set_spacing_selection(_last_selected_spacing)
		_set_route_selection(_last_selected_route)
	else:
		_set_spacing_selection(_last_selected_spacing)
		_set_route_selection(_last_selected_route)
	%RemoveButton.disabled = _selected_entry_id < 0
	%MoveUpButton.disabled = _selected_entry_id < 0
	%MoveDownButton.disabled = _selected_entry_id < 0
	%UndoButton.disabled = not _draft.can_undo()
	%RedoButton.disabled = not _draft.can_redo()
	%ClearButton.disabled = entries.is_empty()
	%CommitButton.disabled = not validation.is_valid()
	if %Feedback.text.is_empty():
		%Feedback.text = validation.get_summary()
		%Feedback.add_theme_color_override(
			"font_color",
			Color("9de2bb") if validation.is_valid() else Color("ffcf85"),
		)


func _set_spacing_selection(spacing_ticks: int) -> void:
	for index: int in %Spacing.item_count:
		if int(%Spacing.get_item_metadata(index)) == spacing_ticks:
			%Spacing.select(index)
			return


func _set_route_selection(route_id: StringName) -> void:
	for index: int in %Route.item_count:
		if %Route.get_item_metadata(index) == route_id:
			%Route.select(index)
			return


func _has_route_option(route_id: StringName) -> bool:
	for index: int in %Route.item_count:
		if %Route.get_item_metadata(index) == route_id:
			return true
	return false


func _spacing_label(spacing_ticks: int) -> String:
	match spacing_ticks:
		WaveDraft.SPACING_TIGHT:
			return "TIGHT · 5 ticks"
		WaveDraft.SPACING_WIDE:
			return "WIDE · 30 ticks"
		_:
			return "STANDARD · 15 ticks"


func _humanize_id(content_id: StringName) -> String:
	var pieces: PackedStringArray = String(content_id).split(".")
	var meaningful: PackedStringArray = pieces.slice(1) if pieces.size() > 1 else pieces
	var words: PackedStringArray = "_".join(meaningful).split("_")
	for index: int in words.size():
		words[index] = words[index].capitalize()
	return " ".join(words)


func _selected_from_list(index: int) -> void:
	_selected_entry_id = int(%EntryList.get_item_metadata(index))
	var entry: WaveDraftEntry = _find_entry(_selected_entry_id)
	if entry != null:
		_last_selected_spacing = entry.get_spacing_after_previous()
		_last_selected_route = entry.get_route_id()
		_set_spacing_selection(_last_selected_spacing)
		_set_route_selection(_last_selected_route)
	_refresh()


func _find_entry(entry_id: int) -> WaveDraftEntry:
	for entry: WaveDraftEntry in _draft.get_entries():
		if entry.get_entry_id() == entry_id:
			return entry
	return null


func _assert_configured() -> void:
	assert(_draft != null, "WaveComposerPanel must be configured before use")


func _on_entry_list_item_selected(index: int) -> void:
	_selected_from_list(index)


func _on_spacing_item_selected(index: int) -> void:
	if _selected_entry_id < 0:
		return
	set_selected_spacing(int(%Spacing.get_item_metadata(index)))


func _on_route_item_selected(index: int) -> void:
	if _selected_entry_id < 0:
		return
	set_selected_route(%Route.get_item_metadata(index))


func _on_remove_button_pressed() -> void:
	remove_selected_entry()


func _on_move_up_button_pressed() -> void:
	move_selected_entry(-1)


func _on_move_down_button_pressed() -> void:
	move_selected_entry(1)


func _on_undo_button_pressed() -> void:
	undo()


func _on_redo_button_pressed() -> void:
	redo()


func _on_clear_button_pressed() -> void:
	clear()


func _on_commit_button_pressed() -> void:
	request_commit()
