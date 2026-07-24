extends "res://tests/framework/test_case.gd"


var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _map: MapDefinition


func before_each() -> void:
	_catalog = ContentCatalog.load_from_directory("res://content")
	_rules = _catalog.get_rules(&"rules.v0")
	_map = _catalog.get_map(_rules.map_id)


func test_diagnostics_toggle_preserves_semantic_combat_state() -> void:
	var entries: Array[WaveScheduleEntry] = [
		WaveScheduleEntry.new(&"unit.tank", &"route.north", 0),
		WaveScheduleEntry.new(&"unit.runner", &"route.north", 5),
		WaveScheduleEntry.new(&"unit.support", &"route.south", 15),
	]
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(entries, _catalog, _map)
	var deployments: Array[TowerDeployment] = [
		TowerDeployment.new(&"tower.rapid", &"slot.approach"),
		TowerDeployment.new(&"tower.control", &"slot.north_1"),
	]
	var diagnostics_on := FixedDefenseSimulation.new(
		9205,
		_catalog,
		_rules,
		schedule,
		deployments,
		true,
	)
	var diagnostics_off := FixedDefenseSimulation.new(
		9205,
		_catalog,
		_rules,
		schedule,
		deployments,
		false,
	)

	for tick_index: int in 200:
		diagnostics_on.advance_one_tick()
		diagnostics_off.advance_one_tick()

	assert_equal(_semantic_signature(diagnostics_off), _semantic_signature(diagnostics_on))
	assert_true(diagnostics_on.get_events().size() > 0)
	assert_equal(diagnostics_off.get_events().size(), 0)


func _semantic_signature(simulation: FixedDefenseSimulation) -> Dictionary:
	var units: Array[Dictionary] = []
	for unit: UnitState in simulation.get_units():
		units.append({
			"id": unit.entity_id,
			"health": unit.health,
			"edge": unit.edge_index,
			"distance": unit.distance_on_edge,
			"slow_ticks": unit.slow_remaining_ticks,
			"arrived": unit.has_arrived,
			"leaked": unit.has_leaked,
			"died": unit.has_died,
		})
	var towers: Array[Dictionary] = []
	for tower: TowerState in simulation.get_towers():
		towers.append({
			"id": tower.entity_id,
			"cooldown": tower.cooldown_remaining,
			"attacks": tower.next_attack_ordinal,
		})
	return {
		"tick": simulation.get_tick(),
		"core": simulation.get_core_integrity(),
		"units": units,
		"towers": towers,
	}
