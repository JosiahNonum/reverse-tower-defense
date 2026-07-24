class_name UnitSpawnSchedule
extends RefCounted


const MAX_WAVE_ENTRIES: int = 300
const VALID_SPACING_TICKS: Array[int] = [5, 15, 30]


static func build(
	entries: Array[WaveScheduleEntry],
	catalog: ContentCatalog,
	map: MapDefinition,
) -> SpawnScheduleResult:
	if entries.is_empty():
		return SpawnScheduleResult.reject(
			SpawnScheduleResult.CODE_EMPTY_WAVE,
			"a wave requires at least one entry",
		)
	if entries.size() > MAX_WAVE_ENTRIES:
		return SpawnScheduleResult.reject(
			SpawnScheduleResult.CODE_TOO_MANY_ENTRIES,
			"a wave supports at most %d entries" % MAX_WAVE_ENTRIES,
		)

	var scheduled_spawns: Array[ScheduledUnitSpawn] = []
	var spawn_tick: int = 0
	for entry_index: int in entries.size():
		var entry: WaveScheduleEntry = entries[entry_index]
		if entry_index == 0:
			if entry.spacing_after_previous_ticks != 0:
				return SpawnScheduleResult.reject(
					SpawnScheduleResult.CODE_INVALID_SPACING,
					"the first entry must use zero spacing",
				)
		elif not VALID_SPACING_TICKS.has(entry.spacing_after_previous_ticks):
			return SpawnScheduleResult.reject(
				SpawnScheduleResult.CODE_INVALID_SPACING,
				"entry %d spacing must be 5, 15, or 30 ticks" % entry_index,
			)
		else:
			spawn_tick += entry.spacing_after_previous_ticks

		var definition: UnitDefinition = catalog.get_unit(entry.unit_id)
		if definition == null:
			return SpawnScheduleResult.reject(
				SpawnScheduleResult.CODE_UNKNOWN_UNIT,
				"entry %d references unknown unit '%s'" % [entry_index, entry.unit_id],
			)
		if _find_route(map, entry.route_id) == null:
			return SpawnScheduleResult.reject(
				SpawnScheduleResult.CODE_UNKNOWN_ROUTE,
				"entry %d references unknown route '%s'" % [entry_index, entry.route_id],
			)
		if not definition.allowed_route_ids.has(entry.route_id):
			return SpawnScheduleResult.reject(
				SpawnScheduleResult.CODE_FORBIDDEN_ROUTE,
				"unit '%s' cannot use route '%s'" % [entry.unit_id, entry.route_id],
			)
		scheduled_spawns.append(ScheduledUnitSpawn.new(
			entry_index,
			spawn_tick,
			entry.unit_id,
			entry.route_id,
		))
	return SpawnScheduleResult.accept(scheduled_spawns)


static func _find_route(map: MapDefinition, route_id: StringName) -> RouteDefinition:
	for route: RouteDefinition in map.routes:
		if route.route_id == route_id:
			return route
	return null
