class_name WaveDraftEntry
extends RefCounted


var _entry_id: int
var _unit_id: StringName
var _route_id: StringName
var _spacing_after_previous: int


func _init(
	entry_id: int,
	unit_id: StringName,
	route_id: StringName,
	spacing_after_previous: int,
) -> void:
	_entry_id = entry_id
	_unit_id = unit_id
	_route_id = route_id
	_spacing_after_previous = spacing_after_previous


func get_entry_id() -> int:
	return _entry_id


func get_unit_id() -> StringName:
	return _unit_id


func get_route_id() -> StringName:
	return _route_id


func set_route_id(route_id: StringName) -> void:
	_route_id = route_id


func get_spacing_after_previous() -> int:
	return _spacing_after_previous


func set_spacing_after_previous(value: int) -> void:
	_spacing_after_previous = value


func copy() -> WaveDraftEntry:
	return WaveDraftEntry.new(
		_entry_id,
		_unit_id,
		_route_id,
		_spacing_after_previous,
	)
