extends "res://tests/framework/test_case.gd"


var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _map: MapDefinition


func before_each() -> void:
	_catalog = ContentCatalog.load_from_directory("res://content")
	_rules = _catalog.get_rules(&"rules.v0")
	_map = _catalog.get_map(_rules.map_id)


func test_checked_content_is_the_complete_supported_v0_archetype_set() -> void:
	var unit_ids: Array[String] = _strings(_rules.unit_ids)
	var tower_ids: Array[String] = _strings(_rules.tower_ids)
	unit_ids.sort()
	tower_ids.sort()
	assert_equal(unit_ids, [
		"unit.runner",
		"unit.support",
		"unit.swarm",
		"unit.tank",
	])
	assert_equal(tower_ids, [
		"tower.anti_armor",
		"tower.control",
		"tower.rapid",
		"tower.splash",
	])

	for unit_id: StringName in _rules.unit_ids:
		var unit: UnitDefinition = _catalog.get_unit(unit_id)
		assert_equal(unit.rally_range > 0, unit_id == &"unit.support")
	for tower_id: StringName in _rules.tower_ids:
		var tower: TowerDefinition = _catalog.get_tower(tower_id)
		assert_equal(tower.splash_radius > 0, tower_id == &"tower.splash")
		assert_equal(tower.slow_duration_ticks > 0, tower_id == &"tower.control")
		assert_equal(tower.ignores_armor, tower_id == &"tower.anti_armor")
		_assert_upgrade_shape(tower)


func test_rapid_damage_exposes_tank_armor_strength_and_rapid_weakness() -> void:
	var swarm_damage: DomainEvent = _first_damage(
		&"unit.swarm",
		&"tower.rapid",
	)
	var tank_damage: DomainEvent = _first_damage(
		&"unit.tank",
		&"tower.rapid",
	)

	assert_equal(swarm_damage.data["raw_damage"], 8)
	assert_equal(swarm_damage.data["resolved_damage"], 8)
	assert_equal(tank_damage.data["raw_damage"], 8)
	assert_equal(tank_damage.data["resolved_damage"], 2)


func test_splash_rewards_tight_swarm_density_and_loses_value_to_spacing() -> void:
	var tight_victims: Array = _first_attack_victims([
		WaveScheduleEntry.new(&"unit.swarm", &"route.north", 0),
		WaveScheduleEntry.new(&"unit.swarm", &"route.north", 5),
		WaveScheduleEntry.new(&"unit.swarm", &"route.north", 5),
	])
	var wide_victims: Array = _first_attack_victims([
		WaveScheduleEntry.new(&"unit.swarm", &"route.north", 0),
		WaveScheduleEntry.new(&"unit.swarm", &"route.north", 30),
		WaveScheduleEntry.new(&"unit.swarm", &"route.north", 30),
	])

	assert_equal(tight_victims.size(), 3)
	assert_equal(wide_victims.size(), 1)


func test_control_checks_runner_speed_and_anti_armor_checks_tank_durability() -> void:
	var control_simulation := _simulation(
		[WaveScheduleEntry.new(&"unit.runner", &"route.north", 0)],
		[TowerDeployment.new(&"tower.control", &"slot.approach")],
	)
	var slow_event: DomainEvent = _advance_until_event(
		control_simulation,
		FixedDefenseSimulation.EVENT_SLOW_STAGED,
		200,
	)
	var runner_before: UnitState = control_simulation.get_units()[0]
	control_simulation.advance_one_tick()
	var runner_after: UnitState = control_simulation.get_units()[0]
	assert_true(slow_event != null)
	assert_equal(runner_after.distance_on_edge - runner_before.distance_on_edge, 12)

	var targeting := TowerTargetingSystem.new(LaneMovementSystem.new(_map))
	var anti_definition: TowerDefinition = _catalog.get_tower(&"tower.anti_armor")
	var anti := TowerState.new(anti_definition, 10, &"slot.test", 0, 2000)
	var runner := _active_unit(&"unit.runner", 2, 500)
	var tank := _active_unit(&"unit.tank", 1, 500)
	var targets: Array[UnitState] = [runner, tank]
	assert_equal(targeting.select_target(anti, targets).entity_id, tank.entity_id)
	assert_equal(
		_first_damage(&"unit.tank", &"tower.anti_armor").data["resolved_damage"],
		90,
	)


func test_support_rally_is_proximity_bound_excludes_source_and_does_not_stack() -> void:
	var paired := _simulation(
		[
			WaveScheduleEntry.new(&"unit.support", &"route.north", 0),
			WaveScheduleEntry.new(&"unit.runner", &"route.north", 5),
		],
		[],
	)
	for tick_index: int in 6:
		paired.advance_one_tick()
	var paired_units: Array[UnitState] = paired.get_units()
	assert_equal(paired_units[0].distance_on_edge, 54)
	assert_equal(paired_units[1].distance_on_edge, 25)
	var movement := LaneMovementSystem.new(_map)
	var previous_remaining: int = movement.remaining_route_distance(paired_units[1])
	var saw_proximity_break: bool = false
	for tick_index: int in 80:
		paired.advance_one_tick()
		var runner: UnitState = paired.get_units()[1]
		var remaining: int = movement.remaining_route_distance(runner)
		if previous_remaining - remaining == 20:
			saw_proximity_break = true
			break
		previous_remaining = remaining
	assert_true(saw_proximity_break)

	var doubled := _simulation(
		[
			WaveScheduleEntry.new(&"unit.support", &"route.north", 0),
			WaveScheduleEntry.new(&"unit.support", &"route.north", 5),
			WaveScheduleEntry.new(&"unit.runner", &"route.north", 5),
		],
		[],
	)
	for tick_index: int in 11:
		doubled.advance_one_tick()
	assert_equal(doubled.get_units()[2].distance_on_edge, 25)
	var runner_rally: DomainEvent = _event_for_target(
		doubled,
		FixedDefenseSimulation.EVENT_RALLY_APPLIED,
		3,
	)
	assert_true(runner_rally != null)
	assert_equal(runner_rally.data["source_unit_ids"], [1, 2])


func test_rally_then_slow_uses_the_contract_order_and_floor_rounding() -> void:
	var runner := UnitState.new(_catalog.get_unit(&"unit.runner"))
	runner.stage_control_slow(60, 100, 30)
	runner.begin_tick_status_stage()
	runner.apply_rally_for_tick(125, 100)
	runner.apply_active_slow_for_tick()

	assert_equal(runner.movement_speed_per_tick, 15)


func _assert_upgrade_shape(base: TowerDefinition) -> void:
	var upgrade: TowerDefinition = _catalog.get_tower(base.upgrade_to_id)
	assert_true(upgrade != null)
	assert_equal(upgrade.cost, int((base.cost * 60 + 99) / 100))
	assert_equal(upgrade.damage, int((base.damage * 125) / 100))
	assert_equal(upgrade.range, int((base.range * 110) / 100))
	assert_equal(upgrade.cooldown_ticks, base.cooldown_ticks)
	assert_equal(upgrade.targeting_kind, base.targeting_kind)
	assert_equal(upgrade.splash_radius, base.splash_radius)
	assert_equal(upgrade.ignores_armor, base.ignores_armor)
	assert_equal(upgrade.slow_numerator, base.slow_numerator)
	assert_equal(upgrade.slow_denominator, base.slow_denominator)
	assert_equal(upgrade.slow_duration_ticks, base.slow_duration_ticks)


func _first_damage(unit_id: StringName, tower_id: StringName) -> DomainEvent:
	var simulation := _simulation(
		[WaveScheduleEntry.new(unit_id, &"route.north", 0)],
		[TowerDeployment.new(tower_id, &"slot.approach")],
	)
	return _advance_until_event(
		simulation,
		FixedDefenseSimulation.EVENT_UNIT_DAMAGED,
		500,
	)


func _first_attack_victims(entries: Array[WaveScheduleEntry]) -> Array:
	var simulation := _simulation(
		entries,
		[TowerDeployment.new(&"tower.splash", &"slot.approach")],
	)
	var attack: DomainEvent = _advance_until_event(
		simulation,
		FixedDefenseSimulation.EVENT_TOWER_ATTACKED,
		200,
	)
	return attack.data["victim_ids"] if attack != null else []


func _advance_until_event(
	simulation: FixedDefenseSimulation,
	event_type: StringName,
	maximum_ticks: int,
) -> DomainEvent:
	for tick_index: int in maximum_ticks:
		simulation.advance_one_tick()
		var events: Array[DomainEvent] = simulation.get_events()
		if not events.is_empty() and events[-1].event_type == event_type:
			return events[-1]
		for event: DomainEvent in events:
			if event.event_type == event_type:
				return event
	return null


func _event_for_target(
	simulation: FixedDefenseSimulation,
	event_type: StringName,
	target_unit_id: int,
) -> DomainEvent:
	for event: DomainEvent in simulation.get_events():
		if (
			event.event_type == event_type
			and event.data.get("target_unit_id", 0) == target_unit_id
		):
			return event
	return null


func _simulation(
	entries: Array[WaveScheduleEntry],
	deployments: Array[TowerDeployment],
) -> FixedDefenseSimulation:
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(entries, _catalog, _map)
	assert(schedule.is_accepted)
	return FixedDefenseSimulation.new(4402, _catalog, _rules, schedule, deployments)


func _active_unit(
	unit_id: StringName,
	entity_id: int,
	distance_on_edge: int,
) -> UnitState:
	var unit := UnitState.new(
		_catalog.get_unit(unit_id),
		entity_id,
		&"route.north",
		0,
	)
	unit.spawn()
	unit.distance_on_edge = distance_on_edge
	return unit


func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result
