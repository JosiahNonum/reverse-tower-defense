extends "res://tests/framework/test_case.gd"


var _catalog: ContentCatalog
var _map: MapDefinition
var _rules: MatchRulesDefinition


func before_each() -> void:
	_catalog = ContentCatalog.load_from_directory("res://content")
	_rules = _catalog.get_rules(&"rules.v0")
	_map = _catalog.get_map(_rules.map_id)


func test_spawn_schedule_validates_spacing_units_and_routes_atomically() -> void:
	var entries: Array[WaveScheduleEntry] = [
		WaveScheduleEntry.new(&"unit.runner", &"route.north", 0),
		WaveScheduleEntry.new(&"unit.swarm", &"route.south", 5),
		WaveScheduleEntry.new(&"unit.tank", &"route.north", 30),
	]
	var accepted: SpawnScheduleResult = UnitSpawnSchedule.build(entries, _catalog, _map)
	var invalid_spacing: SpawnScheduleResult = UnitSpawnSchedule.build(
		[WaveScheduleEntry.new(&"unit.runner", &"route.north", 5)],
		_catalog,
		_map,
	)
	var invalid_route: SpawnScheduleResult = UnitSpawnSchedule.build(
		[WaveScheduleEntry.new(&"unit.runner", &"route.missing", 0)],
		_catalog,
		_map,
	)
	var north_only := _unit_definition(&"unit.north_only", 10, 1)
	north_only.allowed_route_ids = [&"route.north"]
	_catalog.add_definition(north_only)
	var forbidden_route: SpawnScheduleResult = UnitSpawnSchedule.build(
		[WaveScheduleEntry.new(north_only.content_id, &"route.south", 0)],
		_catalog,
		_map,
	)

	assert_true(accepted.is_accepted)
	assert_equal(accepted.spawns[0].spawn_tick, 0)
	assert_equal(accepted.spawns[1].spawn_tick, 5)
	assert_equal(accepted.spawns[2].spawn_tick, 35)
	assert_equal(invalid_spacing.code, SpawnScheduleResult.CODE_INVALID_SPACING)
	assert_equal(invalid_spacing.spawns.size(), 0)
	assert_equal(invalid_route.code, SpawnScheduleResult.CODE_UNKNOWN_ROUTE)
	assert_equal(invalid_route.spawns.size(), 0)
	assert_equal(forbidden_route.code, SpawnScheduleResult.CODE_FORBIDDEN_ROUTE)
	assert_equal(forbidden_route.spawns.size(), 0)


func test_movement_carries_remainder_through_each_authored_branch() -> void:
	var movement := LaneMovementSystem.new(_map)
	var definition: UnitDefinition = _catalog.get_unit(&"unit.runner")
	var north := UnitState.new(definition, 1, &"route.north", 0)
	var south := UnitState.new(definition, 2, &"route.south", 0)
	north.spawn()
	south.spawn()
	north.set_movement_speed_for_tick(2500)
	south.set_movement_speed_for_tick(2500)

	var north_result: LaneMovementResult = movement.advance_unit(north)
	var south_result: LaneMovementResult = movement.advance_unit(south)

	assert_equal(north.edge_index, 2)
	assert_equal(south.edge_index, 2)
	assert_equal(north.distance_on_edge, 500)
	assert_equal(south.distance_on_edge, 500)
	assert_equal(north_result.entered_edge_ids, [
		&"edge.approach_branch",
		&"edge.branch_north_1",
	])
	assert_equal(south_result.entered_edge_ids, [
		&"edge.approach_branch",
		&"edge.branch_south_1",
	])
	assert_true(movement.logical_position(north).y < movement.logical_position(south).y)

	var north_merge_edges: Array[StringName] = []
	var south_merge_edges: Array[StringName] = []
	for tick_index: int in 2:
		north_merge_edges.append_array(movement.advance_unit(north).entered_edge_ids)
		south_merge_edges.append_array(movement.advance_unit(south).entered_edge_ids)
	assert_equal(north_merge_edges, [
		&"edge.north_1_north_2",
		&"edge.north_2_merge",
		&"edge.merge_chokepoint",
		&"edge.chokepoint_core",
	])
	assert_equal(south_merge_edges, [
		&"edge.south_1_south_2",
		&"edge.south_2_merge",
		&"edge.merge_chokepoint",
		&"edge.chokepoint_core",
	])
	assert_equal(movement.current_edge_id(north), &"edge.chokepoint_core")
	assert_equal(movement.current_edge_id(south), &"edge.chokepoint_core")


func test_speed_changes_and_passing_do_not_change_route_or_other_units() -> void:
	var movement := LaneMovementSystem.new(_map)
	var runner := UnitState.new(_catalog.get_unit(&"unit.runner"), 1, &"route.north", 0)
	var tank := UnitState.new(_catalog.get_unit(&"unit.tank"), 2, &"route.north", 0)
	runner.spawn()
	tank.spawn()
	for tick_index: int in 50:
		movement.advance_unit(runner)
		movement.advance_unit(tank)
	var tank_distance_before: int = movement.remaining_route_distance(tank)
	runner.set_movement_speed_for_tick(0)
	movement.advance_unit(runner)

	assert_true(
		movement.remaining_route_distance(runner)
		< movement.remaining_route_distance(tank),
	)
	assert_equal(movement.remaining_route_distance(tank), tank_distance_before)
	assert_equal(runner.route_id, &"route.north")
	assert_equal(tank.route_id, &"route.north")
	assert_equal(runner.movement_speed_per_tick, 1)


func test_simultaneous_arrivals_leak_once_in_entity_id_order() -> void:
	var slow := _unit_definition(&"unit.test_slow", 979, 2)
	var fast := _unit_definition(&"unit.test_fast", 2610, 3)
	_catalog.add_definition(slow)
	_catalog.add_definition(fast)
	var entries: Array[WaveScheduleEntry] = [
		WaveScheduleEntry.new(slow.content_id, &"route.north", 0),
		WaveScheduleEntry.new(fast.content_id, &"route.south", 5),
	]
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(entries, _catalog, _map)
	var simulation := FixedDefenseSimulation.new(8801, _catalog, _rules, schedule)
	for tick_index: int in 12:
		simulation.advance_one_tick()

	var leak_events: Array[DomainEvent] = []
	for event: DomainEvent in simulation.get_events():
		if event.event_type == FixedDefenseSimulation.EVENT_UNIT_LEAKED:
			leak_events.append(event)
	assert_equal(leak_events.size(), 2)
	assert_equal(leak_events[0].tick, leak_events[1].tick)
	assert_equal(leak_events[0].data["entity_id"], 1)
	assert_equal(leak_events[1].data["entity_id"], 2)
	assert_equal(simulation.get_core_integrity(), 5)
	assert_true(simulation.get_units()[0].has_leaked)
	assert_true(simulation.get_units()[1].has_leaked)

	var digest_before: String = simulation.event_digest()
	for tick_index: int in 5:
		simulation.advance_one_tick()
	assert_equal(simulation.event_digest(), digest_before)
	assert_equal(simulation.get_core_integrity(), 5)


func test_same_schedule_produces_identical_events_and_logical_views() -> void:
	var entries: Array[WaveScheduleEntry] = [
		WaveScheduleEntry.new(&"unit.runner", &"route.north", 0),
		WaveScheduleEntry.new(&"unit.swarm", &"route.south", 5),
	]
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(entries, _catalog, _map)
	var first := FixedDefenseSimulation.new(4402, _catalog, _rules, schedule)
	var second := FixedDefenseSimulation.new(4402, _catalog, _rules, schedule)
	for tick_index: int in 10:
		first.advance_one_tick()
		second.advance_one_tick()

	assert_equal(first.event_digest(), second.event_digest())
	assert_equal(_view_dictionaries(first), _view_dictionaries(second))
	assert_equal(first.create_entity_views().size(), 2)


func _unit_definition(
	content_id: StringName,
	speed_per_tick: int,
	unit_leak_damage: int,
) -> UnitDefinition:
	var definition := UnitDefinition.new()
	definition.content_id = content_id
	definition.cost = 1
	definition.max_health = 1
	definition.speed_per_tick = speed_per_tick
	definition.leak_damage = unit_leak_damage
	definition.allowed_route_ids = [&"route.north", &"route.south"]
	return definition


func _view_dictionaries(simulation: FixedDefenseSimulation) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for view: EntityView in simulation.create_entity_views():
		result.append(view.to_dictionary())
	return result
