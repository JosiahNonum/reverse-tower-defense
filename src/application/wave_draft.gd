class_name WaveDraft
extends RefCounted


const MAX_ENTRIES: int = 300
const SPACING_TIGHT: int = 5
const SPACING_STANDARD: int = 15
const SPACING_WIDE: int = 30
const ALLOWED_SPACINGS: Array[int] = [SPACING_TIGHT, SPACING_STANDARD, SPACING_WIDE]

var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _round_index: int
var _budget: int
var _next_entry_id: int = 1
var _entries: Array[WaveDraftEntry] = []
var _undo_snapshots: Array[Array] = []
var _redo_snapshots: Array[Array] = []


func _init(
	catalog: ContentCatalog,
	rules: MatchRulesDefinition,
	round_index: int,
) -> void:
	assert(round_index >= 1 and round_index <= rules.attack_budgets.size())
	_catalog = catalog
	_rules = rules
	_round_index = round_index
	_budget = rules.attack_budgets[round_index - 1]


func get_round_index() -> int:
	return _round_index


func get_budget() -> int:
	return _budget


func get_entries() -> Array[WaveDraftEntry]:
	return _copy_entries(_entries)


func get_available_unit_ids() -> Array[StringName]:
	return _rules.unit_ids.duplicate()


func can_undo() -> bool:
	return not _undo_snapshots.is_empty()


func can_redo() -> bool:
	return not _redo_snapshots.is_empty()


func add_unit(unit_id: StringName, quantity: int = 1) -> WaveDraftEditResult:
	if quantity <= 0:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_INVALID_QUANTITY,
			"Choose at least one unit.",
		)
	if not _rules.unit_ids.has(unit_id):
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNIT_NOT_ALLOWED,
			"%s is not available in this match." % unit_id,
		)
	var unit: UnitDefinition = _catalog.get_unit(unit_id)
	if unit == null:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_UNIT,
			"%s is missing from the content catalog." % unit_id,
		)
	if _entries.size() + quantity > MAX_ENTRIES:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_ENTRY_LIMIT,
			"A v0 wave may contain at most %d entries." % MAX_ENTRIES,
		)
	_push_undo_snapshot()
	var route_id: StringName = _default_route_for(unit)
	for index: int in quantity:
		_entries.append(WaveDraftEntry.new(
			_next_entry_id,
			unit_id,
			route_id,
			SPACING_STANDARD,
		))
		_next_entry_id += 1
	return WaveDraftEditResult.accept("Added %d %s." % [quantity, unit_id])


func remove_entry(entry_id: int) -> WaveDraftEditResult:
	var index: int = _index_of(entry_id)
	if index < 0:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"That draft entry no longer exists.",
		)
	_push_undo_snapshot()
	_entries.remove_at(index)
	return WaveDraftEditResult.accept("Removed draft entry %d." % entry_id)


func move_entry(entry_id: int, offset: int) -> WaveDraftEditResult:
	var index: int = _index_of(entry_id)
	if index < 0:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"That draft entry no longer exists.",
		)
	var target_index: int = index + offset
	if target_index < 0 or target_index >= _entries.size():
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_MOVE_BOUNDARY,
			"That entry is already at the end of the order.",
		)
	_push_undo_snapshot()
	var entry: WaveDraftEntry = _entries[index]
	_entries.remove_at(index)
	_entries.insert(target_index, entry)
	return WaveDraftEditResult.accept("Moved draft entry %d." % entry_id)


func set_spacing(entry_id: int, spacing_ticks: int) -> WaveDraftEditResult:
	if not ALLOWED_SPACINGS.has(spacing_ticks):
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_INVALID_SPACING,
			"Spacing must be 5, 15, or 30 ticks.",
		)
	var index: int = _index_of(entry_id)
	if index < 0:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"That draft entry no longer exists.",
		)
	if _entries[index].get_spacing_after_previous() == spacing_ticks:
		return WaveDraftEditResult.accept("Spacing is already selected.")
	_push_undo_snapshot()
	_entries[index].set_spacing_after_previous(spacing_ticks)
	return WaveDraftEditResult.accept("Updated spacing.")


func set_route(entry_id: int, route_id: StringName) -> WaveDraftEditResult:
	var index: int = _index_of(entry_id)
	if index < 0:
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_UNKNOWN_ENTRY,
			"That draft entry no longer exists.",
		)
	var unit: UnitDefinition = _catalog.get_unit(_entries[index].get_unit_id())
	if unit == null or not unit.allowed_route_ids.has(route_id):
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_INVALID_ROUTE,
			"That unit cannot use the selected route.",
		)
	if _entries[index].get_route_id() == route_id:
		return WaveDraftEditResult.accept("Route is already selected.")
	_push_undo_snapshot()
	_entries[index].set_route_id(route_id)
	return WaveDraftEditResult.accept("Updated route.")


func clear() -> WaveDraftEditResult:
	if _entries.is_empty():
		return WaveDraftEditResult.accept("Draft is already clear.")
	_push_undo_snapshot()
	_entries.clear()
	return WaveDraftEditResult.accept("Cleared the draft.")


func undo() -> WaveDraftEditResult:
	if _undo_snapshots.is_empty():
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_NOTHING_TO_UNDO,
			"Nothing to undo.",
		)
	_redo_snapshots.append(_copy_entries(_entries))
	_restore_entries(_undo_snapshots.pop_back())
	return WaveDraftEditResult.accept("Undid the last draft edit.")


func redo() -> WaveDraftEditResult:
	if _redo_snapshots.is_empty():
		return WaveDraftEditResult.reject(
			WaveDraftEditResult.CODE_NOTHING_TO_REDO,
			"Nothing to redo.",
		)
	_undo_snapshots.append(_copy_entries(_entries))
	_restore_entries(_redo_snapshots.pop_back())
	return WaveDraftEditResult.accept("Restored the draft edit.")


func validate() -> WaveDraftValidation:
	var total_cost: int = 0
	var messages: Array[String] = []
	if _entries.is_empty():
		messages.append("Add at least one unit before committing.")
	for entry: WaveDraftEntry in _entries:
		var unit: UnitDefinition = _catalog.get_unit(entry.get_unit_id())
		if unit == null or not _rules.unit_ids.has(entry.get_unit_id()):
			messages.append("Entry %d has an unavailable unit." % entry.get_entry_id())
			continue
		total_cost += unit.cost
		if not unit.allowed_route_ids.has(entry.get_route_id()):
			messages.append("Entry %d has an invalid route." % entry.get_entry_id())
		if not ALLOWED_SPACINGS.has(entry.get_spacing_after_previous()):
			messages.append("Entry %d has an invalid spacing." % entry.get_entry_id())
	if _entries.size() > MAX_ENTRIES:
		messages.append("A v0 wave may contain at most %d entries." % MAX_ENTRIES)
	if total_cost > _budget:
		messages.append("Over budget by %d points." % (total_cost - _budget))
	return WaveDraftValidation.new(messages.is_empty(), total_cost, _budget, messages)


func _default_route_for(unit: UnitDefinition) -> StringName:
	var route_names: Array[String] = []
	for route_id: StringName in unit.allowed_route_ids:
		route_names.append(String(route_id))
	route_names.sort()
	assert(not route_names.is_empty(), "validated v0 unit must allow at least one route")
	return StringName(route_names[0])


func _index_of(entry_id: int) -> int:
	for index: int in _entries.size():
		if _entries[index].get_entry_id() == entry_id:
			return index
	return -1


func _push_undo_snapshot() -> void:
	_undo_snapshots.append(_copy_entries(_entries))
	_redo_snapshots.clear()


func _restore_entries(snapshot: Array) -> void:
	_entries.clear()
	for entry: WaveDraftEntry in snapshot:
		_entries.append(entry.copy())


func _copy_entries(source: Array[WaveDraftEntry]) -> Array[WaveDraftEntry]:
	var copy: Array[WaveDraftEntry] = []
	for entry: WaveDraftEntry in source:
		copy.append(entry.copy())
	return copy
