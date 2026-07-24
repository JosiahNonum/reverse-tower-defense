class_name FixedDefenseSimulation
extends RefCounted


const EVENT_UNIT_SPAWNED: StringName = &"unit_spawned"
const EVENT_UNIT_ENTERED_EDGE: StringName = &"unit_entered_edge"
const EVENT_UNIT_LEAKED: StringName = &"unit_leaked"

var _root_seed: int
var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _movement: LaneMovementSystem
var _spawns: Array[ScheduledUnitSpawn] = []
var _next_spawn_index: int = 0
var _next_entity_id: int = 1
var _tick: int = 0
var _core_integrity: int
var _events: Array[DomainEvent] = []
var _units: Array[UnitState] = []
var _next_event_ordinal: int = 0


func _init(
	root_seed: int,
	catalog: ContentCatalog,
	rules: MatchRulesDefinition,
	schedule: SpawnScheduleResult,
) -> void:
	assert(schedule.is_accepted, "fixed-defense simulation requires a valid schedule")
	var map: MapDefinition = catalog.get_map(rules.map_id)
	assert(map != null, "rules map must exist in the catalog")
	_root_seed = root_seed
	_catalog = catalog
	_rules = rules
	_movement = LaneMovementSystem.new(map)
	_core_integrity = rules.core_health
	for spawn: ScheduledUnitSpawn in schedule.spawns:
		_spawns.append(spawn.copy())
	_spawns.sort_custom(_spawn_before)


func advance_one_tick() -> void:
	_next_event_ordinal = 0
	_spawn_due_units()
	var arrivals: Array[UnitState] = []
	for unit: UnitState in _units:
		if not unit.is_active():
			continue
		var movement_result: LaneMovementResult = _movement.advance_unit(unit)
		for edge_id: StringName in movement_result.entered_edge_ids:
			_emit_event(EVENT_UNIT_ENTERED_EDGE, {
				"entity_id": unit.entity_id,
				"route_id": String(unit.route_id),
				"edge_id": String(edge_id),
			})
		if movement_result.arrived_now:
			arrivals.append(unit)
	arrivals.sort_custom(_entity_id_before)
	for unit: UnitState in arrivals:
		_resolve_leak(unit)
	_tick += 1


func get_tick() -> int:
	return _tick


func get_root_seed() -> int:
	return _root_seed


func get_core_integrity() -> int:
	return _core_integrity


func get_units() -> Array[UnitState]:
	var result: Array[UnitState] = []
	for unit: UnitState in _units:
		result.append(unit.copy())
	return result


func get_events() -> Array[DomainEvent]:
	var result: Array[DomainEvent] = []
	for event: DomainEvent in _events:
		result.append(event.copy())
	return result


func create_entity_views() -> Array[EntityView]:
	var views: Array[EntityView] = []
	for unit: UnitState in _units:
		if not unit.is_active():
			continue
		var position: Vector2i = _movement.logical_position(unit)
		views.append(EntityView.new(unit.entity_id, &"unit", position.x, position.y))
	return views


func event_digest() -> String:
	var serialized_events: PackedStringArray = []
	for event: DomainEvent in _events:
		serialized_events.append(JSON.stringify(event.to_dictionary()))
	return "\n".join(serialized_events).sha256_text()


func _spawn_due_units() -> void:
	while (
		_next_spawn_index < _spawns.size()
		and _spawns[_next_spawn_index].spawn_tick == _tick
	):
		var spawn: ScheduledUnitSpawn = _spawns[_next_spawn_index]
		var definition: UnitDefinition = _catalog.get_unit(spawn.unit_id)
		var unit := UnitState.new(
			definition,
			_next_entity_id,
			spawn.route_id,
			spawn.spawn_tick,
		)
		_next_entity_id += 1
		unit.spawn()
		_units.append(unit)
		_emit_event(EVENT_UNIT_SPAWNED, {
			"entity_id": unit.entity_id,
			"wave_entry_index": spawn.wave_entry_index,
			"unit_id": String(unit.definition_id),
			"route_id": String(unit.route_id),
			"edge_id": String(_movement.current_edge_id(unit)),
		})
		_next_spawn_index += 1


func _resolve_leak(unit: UnitState) -> void:
	if unit.has_leaked:
		return
	var core_before: int = _core_integrity
	_core_integrity = maxi(0, _core_integrity - unit.leak_damage)
	unit.mark_leaked()
	_emit_event(EVENT_UNIT_LEAKED, {
		"entity_id": unit.entity_id,
		"unit_id": String(unit.definition_id),
		"route_id": String(unit.route_id),
		"leak_damage": unit.leak_damage,
		"core_before": core_before,
		"core_after": _core_integrity,
	})


func _emit_event(event_type: StringName, data: Dictionary) -> void:
	_events.append(DomainEvent.new(_tick, _next_event_ordinal, event_type, data))
	_next_event_ordinal += 1


func _entity_id_before(left: UnitState, right: UnitState) -> bool:
	return left.entity_id < right.entity_id


func _spawn_before(left: ScheduledUnitSpawn, right: ScheduledUnitSpawn) -> bool:
	if left.spawn_tick != right.spawn_tick:
		return left.spawn_tick < right.spawn_tick
	return left.wave_entry_index < right.wave_entry_index
