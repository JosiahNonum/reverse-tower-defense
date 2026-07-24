extends "res://tests/framework/test_case.gd"


var _catalog: ContentCatalog
var _map: MapDefinition
var _rules: MatchRulesDefinition
var _movement: LaneMovementSystem
var _targeting: TowerTargetingSystem


func before_each() -> void:
	_catalog = ContentCatalog.load_from_directory("res://content")
	_rules = _catalog.get_rules(&"rules.v0")
	_map = _catalog.get_map(_rules.map_id)
	_movement = LaneMovementSystem.new(_map)
	_targeting = TowerTargetingSystem.new(_movement)


func test_inclusive_range_boundary_and_no_target_behavior() -> void:
	var unit := _active_unit(_catalog.get_unit(&"unit.runner"), 1, 500)
	var definition := _tower_definition(&"tower.test_rapid", TowerDefinition.TARGET_RAPID)
	var tower := TowerState.new(definition, 10, &"slot.test", 0, 2000)
	var units: Array[UnitState] = [unit]

	tower.range = 500
	assert_equal(_targeting.select_target(tower, units).entity_id, 1)
	tower.range = 499
	assert_equal(_targeting.select_target(tower, units), null)
	unit.has_arrived = true
	tower.range = 500
	assert_equal(_targeting.select_target(tower, units), null)


func test_each_targeting_comparator_has_a_complete_stable_order() -> void:
	var runner := _active_unit(_catalog.get_unit(&"unit.runner"), 3, 300)
	var swarm := _active_unit(_catalog.get_unit(&"unit.swarm"), 2, 500)
	var tank := _active_unit(_catalog.get_unit(&"unit.tank"), 1, 100)
	var units: Array[UnitState] = [runner, swarm, tank]
	var tower_definition := _tower_definition(&"tower.test", TowerDefinition.TARGET_RAPID)
	var tower := TowerState.new(tower_definition, 10, &"slot.test", 0, 2000)
	tower.range = 1000

	tower.targeting_kind = TowerDefinition.TARGET_RAPID
	assert_equal(_targeting.select_target(tower, units).entity_id, 2)
	tower.targeting_kind = TowerDefinition.TARGET_ANTI_ARMOR
	assert_equal(_targeting.select_target(tower, units).entity_id, 1)
	tower.targeting_kind = TowerDefinition.TARGET_CONTROL
	assert_equal(_targeting.select_target(tower, units).entity_id, 3)
	runner.stage_control_slow(60, 100, 30)
	runner.begin_tick_status_stage()
	assert_equal(_targeting.select_target(tower, units).entity_id, 2)


func test_splash_prefers_density_and_orders_all_victims_by_entity_id() -> void:
	var left := _active_unit(_catalog.get_unit(&"unit.swarm"), 3, 100)
	var center := _active_unit(_catalog.get_unit(&"unit.swarm"), 2, 200)
	var far := _active_unit(_catalog.get_unit(&"unit.swarm"), 1, 800)
	var units: Array[UnitState] = [left, center, far]
	var definition := _tower_definition(&"tower.test_splash", TowerDefinition.TARGET_SPLASH)
	definition.splash_radius = 300
	var tower := TowerState.new(definition, 10, &"slot.test", 0, 2000)
	tower.range = 1000
	tower.splash_radius = 300

	var primary: UnitState = _targeting.select_target(tower, units)
	var victims: Array[UnitState] = _targeting.splash_victims(tower, primary, units)

	assert_equal(primary.entity_id, 2)
	assert_equal(_entity_ids(victims), [2, 3])


func test_all_ready_attacks_stage_before_damage_and_death_resolution() -> void:
	var unit := _unit_definition(&"unit.test_target", 1, 10, 0)
	var first_tower := _tower_definition(&"tower.test_first", TowerDefinition.TARGET_RAPID)
	var second_tower := _tower_definition(&"tower.test_second", TowerDefinition.TARGET_RAPID)
	first_tower.damage = 10
	second_tower.damage = 10
	first_tower.range = 10000
	second_tower.range = 10000
	_catalog.add_definition(unit)
	_catalog.add_definition(first_tower)
	_catalog.add_definition(second_tower)
	var simulation := _simulation(
		[WaveScheduleEntry.new(unit.content_id, &"route.north", 0)],
		[
			TowerDeployment.new(first_tower.content_id, &"slot.approach"),
			TowerDeployment.new(second_tower.content_id, &"slot.north_1"),
		],
	)

	simulation.advance_one_tick()
	var attacks: Array[DomainEvent] = _events_of_type(
		simulation,
		FixedDefenseSimulation.EVENT_TOWER_ATTACKED,
	)
	var damages: Array[DomainEvent] = _events_of_type(
		simulation,
		FixedDefenseSimulation.EVENT_UNIT_DAMAGED,
	)
	var deaths: Array[DomainEvent] = _events_of_type(
		simulation,
		FixedDefenseSimulation.EVENT_UNIT_DIED,
	)

	assert_equal(attacks.size(), 2)
	assert_equal(damages.size(), 2)
	assert_equal(damages[0].data["source_tower_id"], 1)
	assert_equal(damages[1].data["source_tower_id"], 2)
	assert_equal(damages[1].data["health_before"], 0)
	assert_equal(deaths.size(), 1)
	assert_true(simulation.get_units()[0].has_died)
	assert_equal(simulation.create_entity_views().size(), 2)


func test_normal_damage_uses_armor_and_penetration_ignores_it() -> void:
	var armored := _unit_definition(&"unit.test_armored", 1, 200, 6)
	var rapid := _tower_definition(&"tower.test_normal", TowerDefinition.TARGET_RAPID)
	var anti := _tower_definition(&"tower.test_penetrating", TowerDefinition.TARGET_ANTI_ARMOR)
	rapid.damage = 8
	anti.damage = 90
	anti.ignores_armor = true
	rapid.range = 10000
	anti.range = 10000
	_catalog.add_definition(armored)
	_catalog.add_definition(rapid)
	_catalog.add_definition(anti)
	var simulation := _simulation(
		[WaveScheduleEntry.new(armored.content_id, &"route.north", 0)],
		[
			TowerDeployment.new(rapid.content_id, &"slot.approach"),
			TowerDeployment.new(anti.content_id, &"slot.north_1"),
		],
	)

	simulation.advance_one_tick()
	var damages: Array[DomainEvent] = _events_of_type(
		simulation,
		FixedDefenseSimulation.EVENT_UNIT_DAMAGED,
	)
	assert_equal(damages[0].data["resolved_damage"], 2)
	assert_equal(damages[1].data["resolved_damage"], 90)
	assert_equal(simulation.get_units()[0].health, 108)


func test_cooldown_ticks_and_retargeting_are_deterministic() -> void:
	var durable := _unit_definition(&"unit.test_durable", 1, 100, 0)
	var rapid := _tower_definition(&"tower.test_cadence", TowerDefinition.TARGET_RAPID)
	rapid.damage = 1
	rapid.range = 10000
	rapid.cooldown_ticks = 2
	_catalog.add_definition(durable)
	_catalog.add_definition(rapid)
	var cadence_simulation := _simulation(
		[WaveScheduleEntry.new(durable.content_id, &"route.north", 0)],
		[TowerDeployment.new(rapid.content_id, &"slot.approach")],
	)
	for tick_index: int in 5:
		cadence_simulation.advance_one_tick()
	var cadence_attacks: Array[DomainEvent] = _events_of_type(
		cadence_simulation,
		FixedDefenseSimulation.EVENT_TOWER_ATTACKED,
	)
	assert_equal(_event_ticks(cadence_attacks), [0, 2, 4])

	var fragile := _unit_definition(&"unit.test_fragile", 1, 1, 0)
	var finisher := _tower_definition(&"tower.test_retarget", TowerDefinition.TARGET_RAPID)
	finisher.damage = 1
	finisher.range = 10000
	finisher.cooldown_ticks = 2
	_catalog.add_definition(fragile)
	_catalog.add_definition(finisher)
	var retarget_simulation := _simulation(
		[
			WaveScheduleEntry.new(fragile.content_id, &"route.north", 0),
			WaveScheduleEntry.new(fragile.content_id, &"route.north", 5),
		],
		[TowerDeployment.new(finisher.content_id, &"slot.approach")],
	)
	for tick_index: int in 7:
		retarget_simulation.advance_one_tick()
	var retarget_attacks: Array[DomainEvent] = _events_of_type(
		retarget_simulation,
		FixedDefenseSimulation.EVENT_TOWER_ATTACKED,
	)
	assert_equal(retarget_attacks.size(), 2)
	assert_equal(retarget_attacks[0].data["primary_target_id"], 2)
	assert_equal(retarget_attacks[1].data["primary_target_id"], 3)
	assert_equal(_event_ticks(retarget_attacks), [0, 5])


func test_control_slow_begins_next_tick_and_expires_after_its_duration() -> void:
	var runner := _unit_definition(&"unit.test_runner", 20, 100, 0)
	var control := _tower_definition(&"tower.test_control", TowerDefinition.TARGET_CONTROL)
	control.damage = 1
	control.range = 10000
	control.cooldown_ticks = 1000
	control.slow_numerator = 60
	control.slow_denominator = 100
	control.slow_duration_ticks = 3
	_catalog.add_definition(runner)
	_catalog.add_definition(control)
	var simulation := _simulation(
		[WaveScheduleEntry.new(runner.content_id, &"route.north", 0)],
		[TowerDeployment.new(control.content_id, &"slot.approach")],
	)

	simulation.advance_one_tick()
	assert_equal(simulation.get_units()[0].distance_on_edge, 20)
	assert_false(simulation.get_units()[0].has_control_slow())
	simulation.advance_one_tick()
	assert_equal(simulation.get_units()[0].distance_on_edge, 32)
	assert_equal(simulation.get_units()[0].slow_remaining_ticks, 3)
	simulation.advance_one_tick()
	simulation.advance_one_tick()
	assert_equal(simulation.get_units()[0].distance_on_edge, 56)
	simulation.advance_one_tick()
	assert_equal(simulation.get_units()[0].distance_on_edge, 76)
	assert_false(simulation.get_units()[0].has_control_slow())


func test_splash_attack_damages_every_attack_time_victim_once() -> void:
	var swarm := _unit_definition(&"unit.test_swarm", 1, 100, 0)
	var splash := _tower_definition(&"tower.test_splash_runtime", TowerDefinition.TARGET_SPLASH)
	splash.damage = 10
	splash.range = 600
	splash.splash_radius = 300
	splash.cooldown_ticks = 1000
	_catalog.add_definition(swarm)
	_catalog.add_definition(splash)
	var simulation := _simulation(
		[
			WaveScheduleEntry.new(swarm.content_id, &"route.north", 0),
			WaveScheduleEntry.new(swarm.content_id, &"route.north", 5),
			WaveScheduleEntry.new(swarm.content_id, &"route.north", 5),
		],
		[TowerDeployment.new(splash.content_id, &"slot.approach")],
	)
	for tick_index: int in 900:
		simulation.advance_one_tick()

	var attacks: Array[DomainEvent] = _events_of_type(
		simulation,
		FixedDefenseSimulation.EVENT_TOWER_ATTACKED,
	)
	var damages: Array[DomainEvent] = _events_of_type(
		simulation,
		FixedDefenseSimulation.EVENT_UNIT_DAMAGED,
	)
	assert_equal(attacks.size(), 1)
	assert_equal(attacks[0].data["victim_ids"], [2, 3, 4])
	assert_equal(damages.size(), 3)
	assert_equal(simulation.get_units()[0].health, 90)
	assert_equal(simulation.get_units()[1].health, 90)
	assert_equal(simulation.get_units()[2].health, 90)


func _simulation(
	entries: Array[WaveScheduleEntry],
	deployments: Array[TowerDeployment],
) -> FixedDefenseSimulation:
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(entries, _catalog, _map)
	assert(schedule.is_accepted)
	return FixedDefenseSimulation.new(4402, _catalog, _rules, schedule, deployments)


func _active_unit(
	definition: UnitDefinition,
	entity_id: int,
	distance_on_edge: int,
) -> UnitState:
	var unit := UnitState.new(definition, entity_id, &"route.north", 0)
	unit.spawn()
	unit.distance_on_edge = distance_on_edge
	return unit


func _unit_definition(
	content_id: StringName,
	speed: int,
 health: int,
	armor: int,
) -> UnitDefinition:
	var definition := UnitDefinition.new()
	definition.content_id = content_id
	definition.cost = 1
	definition.max_health = health
	definition.armor = armor
	definition.speed_per_tick = speed
	definition.leak_damage = 1
	definition.allowed_route_ids = [&"route.north", &"route.south"]
	return definition


func _tower_definition(
	content_id: StringName,
	targeting_kind: StringName,
) -> TowerDefinition:
	var definition := TowerDefinition.new()
	definition.content_id = content_id
	definition.cost = 1
	definition.range = 1000
	definition.damage = 1
	definition.cooldown_ticks = 1
	definition.targeting_kind = targeting_kind
	return definition


func _events_of_type(
	simulation: FixedDefenseSimulation,
	event_type: StringName,
) -> Array[DomainEvent]:
	var result: Array[DomainEvent] = []
	for event: DomainEvent in simulation.get_events():
		if event.event_type == event_type:
			result.append(event)
	return result


func _entity_ids(units: Array[UnitState]) -> Array[int]:
	var result: Array[int] = []
	for unit: UnitState in units:
		result.append(unit.entity_id)
	return result


func _event_ticks(events: Array[DomainEvent]) -> Array[int]:
	var result: Array[int] = []
	for event: DomainEvent in events:
		result.append(event.tick)
	return result
