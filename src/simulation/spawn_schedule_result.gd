class_name SpawnScheduleResult
extends RefCounted


const CODE_ACCEPTED: StringName = &"accepted"
const CODE_EMPTY_WAVE: StringName = &"empty_wave"
const CODE_TOO_MANY_ENTRIES: StringName = &"too_many_entries"
const CODE_INVALID_SPACING: StringName = &"invalid_spacing"
const CODE_UNKNOWN_UNIT: StringName = &"unknown_unit"
const CODE_UNKNOWN_ROUTE: StringName = &"unknown_route"
const CODE_FORBIDDEN_ROUTE: StringName = &"forbidden_route"

var is_accepted: bool
var code: StringName
var message: String
var spawns: Array[ScheduledUnitSpawn] = []


func _init(
	accepted: bool,
	result_code: StringName,
	detail: String,
	scheduled_spawns: Array[ScheduledUnitSpawn] = [],
) -> void:
	is_accepted = accepted
	code = result_code
	message = detail
	for spawn: ScheduledUnitSpawn in scheduled_spawns:
		spawns.append(spawn.copy())


static func accept(scheduled_spawns: Array[ScheduledUnitSpawn]) -> SpawnScheduleResult:
	return SpawnScheduleResult.new(true, CODE_ACCEPTED, "", scheduled_spawns)


static func reject(result_code: StringName, detail: String) -> SpawnScheduleResult:
	return SpawnScheduleResult.new(false, result_code, detail)
