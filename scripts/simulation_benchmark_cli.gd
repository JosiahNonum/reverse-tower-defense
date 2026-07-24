extends SceneTree


const UNIT_COUNT: int = 300
const TOWER_COUNT: int = 100
const TICK_COUNT: int = 20
const SAMPLE_COUNT: int = 3
const MAX_DIAGNOSTICS_OFF_MEDIAN_MS: float = 1000.0
const MAX_DIAGNOSTICS_ON_MEDIAN_MS: float = 1000.0
const BENCHMARK_MAP_ID: StringName = &"map.benchmark"
const BENCHMARK_RULES_ID: StringName = &"rules.benchmark"


func _initialize() -> void:
	var source_catalog := ContentCatalog.load_from_directory("res://content")
	var fixture: Dictionary = _build_fixture(source_catalog)
	var diagnostics_off: Dictionary = _measure(fixture, false)
	var diagnostics_on: Dictionary = _measure(fixture, true)
	var semantic_match: bool = (
		diagnostics_off["semantic_signature"]
		== diagnostics_on["semantic_signature"]
	)
	var passed: bool = (
		semantic_match
		and diagnostics_off["median_total_ms"] <= MAX_DIAGNOSTICS_OFF_MEDIAN_MS
		and diagnostics_on["median_total_ms"] <= MAX_DIAGNOSTICS_ON_MEDIAN_MS
	)
	var report: Dictionary = {
		"benchmark_id": "m2.fixed_defense_capacity",
		"unit_count": UNIT_COUNT,
		"tower_count": TOWER_COUNT,
		"tick_count": TICK_COUNT,
		"simulated_seconds": float(TICK_COUNT) / fixture["rules"].ticks_per_second,
		"sample_count": SAMPLE_COUNT,
		"diagnostics_off": diagnostics_off,
		"diagnostics_on": diagnostics_on,
		"semantic_match": semantic_match,
		"thresholds_ms": {
			"diagnostics_off_median": MAX_DIAGNOSTICS_OFF_MEDIAN_MS,
			"diagnostics_on_median": MAX_DIAGNOSTICS_ON_MEDIAN_MS,
		},
		"passed": passed,
	}
	print("SIMULATION BENCHMARK: %s" % JSON.stringify(report))
	if not passed:
		push_error("SIMULATION BENCHMARK FAIL: performance threshold or semantic parity failed")
		quit(1)
		return
	print("SIMULATION BENCHMARK PASS")
	quit(0)


func _measure(fixture: Dictionary, record_events: bool) -> Dictionary:
	_run_sample(fixture, record_events)
	var sample_microseconds: Array[int] = []
	var signature: Dictionary = {}
	var retained_event_count: int = 0
	for sample_index: int in SAMPLE_COUNT:
		var sample: Dictionary = _run_sample(fixture, record_events)
		sample_microseconds.append(sample["elapsed_microseconds"])
		signature = sample["semantic_signature"]
		retained_event_count = sample["retained_event_count"]
	sample_microseconds.sort()
	var median_microseconds: int = sample_microseconds[SAMPLE_COUNT / 2]
	return {
		"sample_total_ms": _milliseconds(sample_microseconds),
		"median_total_ms": snappedf(float(median_microseconds) / 1000.0, 0.001),
		"maximum_total_ms": snappedf(float(sample_microseconds[-1]) / 1000.0, 0.001),
		"median_average_tick_ms": snappedf(
			float(median_microseconds) / 1000.0 / TICK_COUNT,
			0.0001,
		),
		"retained_event_count": retained_event_count,
		"semantic_signature": signature,
	}


func _run_sample(fixture: Dictionary, record_events: bool) -> Dictionary:
	var simulation := FixedDefenseSimulation.new(
		9205,
		fixture["catalog"],
		fixture["rules"],
		fixture["schedule"],
		fixture["deployments"],
		record_events,
	)
	var started_microseconds: int = Time.get_ticks_usec()
	for tick_index: int in TICK_COUNT:
		simulation.advance_one_tick()
	var elapsed_microseconds: int = Time.get_ticks_usec() - started_microseconds
	return {
		"elapsed_microseconds": elapsed_microseconds,
		"retained_event_count": simulation.get_events().size(),
		"semantic_signature": _semantic_signature(simulation),
	}


func _build_fixture(source_catalog: ContentCatalog) -> Dictionary:
	var source_rules: MatchRulesDefinition = source_catalog.get_rules(&"rules.v0")
	var source_map: MapDefinition = source_catalog.get_map(source_rules.map_id)
	var benchmark_map := _benchmark_map(source_map)
	var benchmark_rules := _benchmark_rules(source_rules)
	var catalog := ContentCatalog.new()
	catalog.add_definition(benchmark_map)
	catalog.add_definition(source_catalog.get_unit(&"unit.swarm"))
	catalog.add_definition(source_catalog.get_tower(&"tower.control"))
	catalog.add_definition(benchmark_rules)

	var spawns: Array[ScheduledUnitSpawn] = []
	for unit_index: int in UNIT_COUNT:
		spawns.append(ScheduledUnitSpawn.new(
			unit_index,
			0,
			&"unit.swarm",
			&"route.north",
		))
	var deployments: Array[TowerDeployment] = []
	for tower_index: int in TOWER_COUNT:
		deployments.append(TowerDeployment.new(
			&"tower.control",
			StringName("slot.benchmark.%03d" % tower_index),
		))
	return {
		"catalog": catalog,
		"rules": benchmark_rules,
		"schedule": SpawnScheduleResult.accept(spawns),
		"deployments": deployments,
	}


func _benchmark_map(source: MapDefinition) -> MapDefinition:
	var map := MapDefinition.new()
	map.content_id = BENCHMARK_MAP_ID
	map.logical_width = source.logical_width
	map.logical_height = source.logical_height
	map.spawn_node_id = source.spawn_node_id
	map.core_node_id = source.core_node_id
	map.nodes.assign(source.nodes)
	map.edges.assign(source.edges)
	map.routes.assign(source.routes)
	for tower_index: int in TOWER_COUNT:
		var slot := BuildSlotDefinition.new()
		slot.slot_id = StringName("slot.benchmark.%03d" % tower_index)
		slot.logical_x = 0
		slot.logical_y = 2000
		map.build_slots.append(slot)
	return map


func _benchmark_rules(source: MatchRulesDefinition) -> MatchRulesDefinition:
	var rules := MatchRulesDefinition.new()
	rules.content_id = BENCHMARK_RULES_ID
	rules.rules_version = source.rules_version
	rules.map_id = BENCHMARK_MAP_ID
	rules.unit_ids = [&"unit.swarm"]
	rules.tower_ids = [&"tower.control"]
	rules.round_count = source.round_count
	rules.attack_budgets.assign(source.attack_budgets)
	rules.initial_defense_budget = source.initial_defense_budget
	rules.adaptation_grant = source.adaptation_grant
	rules.sale_refund_basis_points = source.sale_refund_basis_points
	rules.core_health = source.core_health
	rules.ticks_per_second = source.ticks_per_second
	return rules


func _semantic_signature(simulation: FixedDefenseSimulation) -> Dictionary:
	var active_count: int = 0
	var death_count: int = 0
	var leak_count: int = 0
	var total_health: int = 0
	var total_edge_index: int = 0
	var total_distance_on_edge: int = 0
	for unit: UnitState in simulation.get_units():
		active_count += 1 if unit.is_active() else 0
		death_count += 1 if unit.has_died else 0
		leak_count += 1 if unit.has_leaked else 0
		total_health += unit.health
		total_edge_index += unit.edge_index
		total_distance_on_edge += unit.distance_on_edge
	var total_attack_count: int = 0
	for tower: TowerState in simulation.get_towers():
		total_attack_count += tower.next_attack_ordinal
	return {
		"tick": simulation.get_tick(),
		"core_integrity": simulation.get_core_integrity(),
		"active_units": active_count,
		"deaths": death_count,
		"leaks": leak_count,
		"total_health": total_health,
		"total_edge_index": total_edge_index,
		"total_distance_on_edge": total_distance_on_edge,
		"total_attacks": total_attack_count,
	}


func _milliseconds(values: Array[int]) -> Array[float]:
	var result: Array[float] = []
	for value: int in values:
		result.append(snappedf(float(value) / 1000.0, 0.001))
	return result
