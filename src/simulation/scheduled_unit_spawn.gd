class_name ScheduledUnitSpawn
extends RefCounted


var wave_entry_index: int
var spawn_tick: int
var unit_id: StringName
var route_id: StringName


func _init(
	entry_index: int,
	entry_spawn_tick: int,
	entry_unit_id: StringName,
	entry_route_id: StringName,
) -> void:
	wave_entry_index = entry_index
	spawn_tick = entry_spawn_tick
	unit_id = entry_unit_id
	route_id = entry_route_id


func copy() -> ScheduledUnitSpawn:
	return ScheduledUnitSpawn.new(wave_entry_index, spawn_tick, unit_id, route_id)
