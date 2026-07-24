class_name WaveScheduleEntry
extends RefCounted


var unit_id: StringName
var route_id: StringName
var spacing_after_previous_ticks: int


func _init(
	entry_unit_id: StringName,
	entry_route_id: StringName,
	entry_spacing_ticks: int,
) -> void:
	unit_id = entry_unit_id
	route_id = entry_route_id
	spacing_after_previous_ticks = entry_spacing_ticks


func copy() -> WaveScheduleEntry:
	return WaveScheduleEntry.new(unit_id, route_id, spacing_after_previous_ticks)
