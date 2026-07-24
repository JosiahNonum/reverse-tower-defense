class_name FixedDefenseSimulation
extends RefCounted


const EVENT_UNIT_SPAWNED: StringName = &"unit_spawned"
const EVENT_UNIT_ENTERED_EDGE: StringName = &"unit_entered_edge"
const EVENT_UNIT_LEAKED: StringName = &"unit_leaked"
const EVENT_TOWER_ATTACKED: StringName = &"tower_attacked"
const EVENT_UNIT_DAMAGED: StringName = &"unit_damaged"
const EVENT_SLOW_STAGED: StringName = &"slow_staged"
const EVENT_RALLY_APPLIED: StringName = &"rally_applied"
const EVENT_UNIT_DIED: StringName = &"unit_died"

var _root_seed: int
var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _map: MapDefinition
var _movement: LaneMovementSystem
var _targeting: TowerTargetingSystem
var _spawns: Array[ScheduledUnitSpawn] = []
var _next_spawn_index: int = 0
var _next_entity_id: int = 1
var _tick: int = 0
var _core_integrity: int
var _events: Array[DomainEvent] = []
var _units: Array[UnitState] = []
var _towers: Array[TowerState] = []
var _next_event_ordinal: int = 0


func _init(
	root_seed: int,
	catalog: ContentCatalog,
	rules: MatchRulesDefinition,
	schedule: SpawnScheduleResult,
	tower_deployments: Array[TowerDeployment] = [],
) -> void:
	assert(schedule.is_accepted, "fixed-defense simulation requires a valid schedule")
	var map: MapDefinition = catalog.get_map(rules.map_id)
	assert(map != null, "rules map must exist in the catalog")
	_root_seed = root_seed
	_catalog = catalog
	_rules = rules
	_map = map
	_movement = LaneMovementSystem.new(map)
	_targeting = TowerTargetingSystem.new(_movement)
	_core_integrity = rules.core_health
	_deploy_towers(tower_deployments)
	for spawn: ScheduledUnitSpawn in schedule.spawns:
		_spawns.append(spawn.copy())
	_spawns.sort_custom(_spawn_before)


func advance_one_tick() -> void:
	_next_event_ordinal = 0
	_spawn_due_units()
	_apply_start_tick_statuses()
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
	for tower: TowerState in _towers:
		tower.begin_tick()
	var attack_intents: Array[AttackIntent] = _stage_attacks()
	_resolve_attack_intents(attack_intents)
	_resolve_deaths()
	_tick += 1


func get_tick() -> int:
	return _tick


func get_root_seed() -> int:
	return _root_seed


func get_core_integrity() -> int:
	return _core_integrity


func is_resolved() -> bool:
	if _next_spawn_index < _spawns.size():
		return false
	for unit: UnitState in _units:
		if unit.is_active():
			return false
	return true


func get_units() -> Array[UnitState]:
	var result: Array[UnitState] = []
	for unit: UnitState in _units:
		result.append(unit.copy())
	return result


func get_towers() -> Array[TowerState]:
	var result: Array[TowerState] = []
	for tower: TowerState in _towers:
		result.append(tower.copy())
	return result


func get_events() -> Array[DomainEvent]:
	var result: Array[DomainEvent] = []
	for event: DomainEvent in _events:
		result.append(event.copy())
	return result


func create_entity_views() -> Array[EntityView]:
	var views: Array[EntityView] = []
	for tower: TowerState in _towers:
		views.append(EntityView.new(
			tower.entity_id,
			&"tower",
			tower.logical_x,
			tower.logical_y,
		))
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


func _apply_start_tick_statuses() -> void:
	for unit: UnitState in _units:
		if unit.is_active():
			unit.begin_tick_status_stage()
	var rally_sources_by_target: Dictionary[int, Array] = {}
	var first_rally_source_by_target: Dictionary[int, UnitState] = {}
	for source: UnitState in _units:
		if not source.is_active() or not source.has_rally_aura():
			continue
		var source_position: Vector2i = _movement.logical_position(source)
		for target: UnitState in _units:
			if not target.is_active() or target.entity_id == source.entity_id:
				continue
			var target_position: Vector2i = _movement.logical_position(target)
			var distance_squared: int = IntegerMath.squared_distance(
				source_position.x,
				source_position.y,
				target_position.x,
				target_position.y,
			)
			if not IntegerMath.is_inside_inclusive_range(
				distance_squared,
				source.rally_range,
			):
				continue
			if not rally_sources_by_target.has(target.entity_id):
				rally_sources_by_target[target.entity_id] = []
				first_rally_source_by_target[target.entity_id] = source
			rally_sources_by_target[target.entity_id].append(source.entity_id)
	for target: UnitState in _units:
		if not target.is_active():
			continue
		if rally_sources_by_target.has(target.entity_id):
			var source: UnitState = first_rally_source_by_target[target.entity_id]
			target.apply_rally_for_tick(source.rally_numerator, source.rally_denominator)
			_emit_event(EVENT_RALLY_APPLIED, {
				"target_unit_id": target.entity_id,
				"target_unit_definition_id": String(target.definition_id),
				"source_unit_ids": rally_sources_by_target[target.entity_id],
				"numerator": source.rally_numerator,
				"denominator": source.rally_denominator,
				"route_id": String(target.route_id),
				"edge_id": String(_movement.current_edge_id(target)),
				"distance_on_edge": target.distance_on_edge,
			})
		target.apply_active_slow_for_tick()


func _stage_attacks() -> Array[AttackIntent]:
	var intents: Array[AttackIntent] = []
	for tower: TowerState in _towers:
		if not tower.is_ready():
			continue
		var primary: UnitState = _targeting.select_target(tower, _units)
		if primary == null:
			continue
		var attack_ordinal: int = tower.record_attack()
		var victims: Array[UnitState] = [primary]
		if tower.targeting_kind == TowerDefinition.TARGET_SPLASH:
			victims = _targeting.splash_victims(tower, primary, _units)
		var victim_ids: Array[int] = []
		for victim: UnitState in victims:
			victim_ids.append(victim.entity_id)
			intents.append(AttackIntent.new(
				tower.entity_id,
				attack_ordinal,
				victim.entity_id,
				tower.damage,
				tower.ignores_armor,
				tower.slow_numerator,
				tower.slow_denominator,
				tower.slow_duration_ticks,
			))
		_emit_event(EVENT_TOWER_ATTACKED, {
			"tower_entity_id": tower.entity_id,
			"tower_id": String(tower.definition_id),
			"slot_id": String(tower.slot_id),
			"logical_x": tower.logical_x,
			"logical_y": tower.logical_y,
			"attack_ordinal": attack_ordinal,
			"primary_target_id": primary.entity_id,
			"victim_ids": victim_ids,
		})
	return intents


func _resolve_attack_intents(intents: Array[AttackIntent]) -> void:
	intents.sort_custom(_attack_intent_before)
	for intent: AttackIntent in intents:
		var unit: UnitState = _find_unit(intent.target_unit_id)
		assert(unit != null, "staged attack targets must remain match-owned until deaths resolve")
		var tower: TowerState = _find_tower(intent.source_tower_id)
		assert(tower != null, "staged attack sources must remain match-owned")
		var resolved_damage: int = intent.raw_damage
		if not intent.ignores_armor:
			resolved_damage = maxi(1, intent.raw_damage - unit.armor)
		var health_before: int = unit.health
		unit.apply_damage(resolved_damage)
		_emit_event(EVENT_UNIT_DAMAGED, {
			"source_tower_id": intent.source_tower_id,
			"source_tower_definition_id": String(tower.definition_id),
			"source_slot_id": String(tower.slot_id),
			"attack_ordinal": intent.attack_ordinal,
			"target_unit_id": intent.target_unit_id,
			"target_unit_definition_id": String(unit.definition_id),
			"raw_damage": intent.raw_damage,
			"resolved_damage": resolved_damage,
			"ignores_armor": intent.ignores_armor,
			"health_before": health_before,
			"health_after": unit.health,
			"route_id": String(unit.route_id),
			"edge_id": String(_movement.current_edge_id(unit)),
			"distance_on_edge": unit.distance_on_edge,
		})
		if intent.slow_duration_ticks > 0:
			unit.stage_control_slow(
				intent.slow_numerator,
				intent.slow_denominator,
				intent.slow_duration_ticks,
			)
			_emit_event(EVENT_SLOW_STAGED, {
				"source_tower_id": intent.source_tower_id,
				"source_tower_definition_id": String(tower.definition_id),
				"source_slot_id": String(tower.slot_id),
				"attack_ordinal": intent.attack_ordinal,
				"target_unit_id": intent.target_unit_id,
				"target_unit_definition_id": String(unit.definition_id),
				"numerator": intent.slow_numerator,
				"denominator": intent.slow_denominator,
				"duration_ticks": intent.slow_duration_ticks,
				"route_id": String(unit.route_id),
				"edge_id": String(_movement.current_edge_id(unit)),
				"distance_on_edge": unit.distance_on_edge,
			})


func _resolve_deaths() -> void:
	var defeated: Array[UnitState] = []
	for unit: UnitState in _units:
		if unit.is_spawned and unit.health == 0 and not unit.has_died and not unit.has_leaked:
			defeated.append(unit)
	defeated.sort_custom(_entity_id_before)
	for unit: UnitState in defeated:
		unit.mark_died()
		_emit_event(EVENT_UNIT_DIED, {
			"entity_id": unit.entity_id,
			"unit_id": String(unit.definition_id),
			"route_id": String(unit.route_id),
			"edge_index": unit.edge_index,
			"distance_on_edge": unit.distance_on_edge,
		})


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


func _attack_intent_before(left: AttackIntent, right: AttackIntent) -> bool:
	if left.source_tower_id != right.source_tower_id:
		return left.source_tower_id < right.source_tower_id
	if left.attack_ordinal != right.attack_ordinal:
		return left.attack_ordinal < right.attack_ordinal
	return left.target_unit_id < right.target_unit_id


func _deploy_towers(deployments: Array[TowerDeployment]) -> void:
	var occupied_slots: Dictionary[StringName, bool] = {}
	for deployment: TowerDeployment in deployments:
		assert(not occupied_slots.has(deployment.slot_id), "tower slots may only be occupied once")
		var definition: TowerDefinition = _catalog.get_tower(deployment.tower_id)
		assert(definition != null, "deployed tower definition must exist")
		var slot: BuildSlotDefinition = _find_slot(deployment.slot_id)
		assert(slot != null, "deployed tower slot must exist")
		occupied_slots[deployment.slot_id] = true
		_towers.append(TowerState.new(
			definition,
			_next_entity_id,
			slot.slot_id,
			slot.logical_x,
			slot.logical_y,
		))
		_next_entity_id += 1


func _find_slot(slot_id: StringName) -> BuildSlotDefinition:
	for slot: BuildSlotDefinition in _map.build_slots:
		if slot.slot_id == slot_id:
			return slot
	return null


func _find_unit(entity_id: int) -> UnitState:
	for unit: UnitState in _units:
		if unit.entity_id == entity_id:
			return unit
	return null


func _find_tower(entity_id: int) -> TowerState:
	for tower: TowerState in _towers:
		if tower.entity_id == entity_id:
			return tower
	return null
