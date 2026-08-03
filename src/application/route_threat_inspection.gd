class_name RouteThreatInspection
extends RefCounted


const LEVEL_OPEN: StringName = &"open"
const LEVEL_GUARDED: StringName = &"guarded"
const LEVEL_FORTIFIED: StringName = &"fortified"

var _edge_id: StringName
var _display_name: String
var _from_position: Vector2i
var _to_position: Vector2i
var _route_ids: Array[StringName] = []
var _covering_slot_ids: Array[StringName] = []
var _threat_level: StringName


func _init(
	edge_id: StringName,
	display_name: String,
	from_position: Vector2i,
	to_position: Vector2i,
	route_ids: Array[StringName],
	covering_slot_ids: Array[StringName],
) -> void:
	_edge_id = edge_id
	_display_name = display_name
	_from_position = from_position
	_to_position = to_position
	_route_ids.assign(route_ids)
	_covering_slot_ids.assign(covering_slot_ids)
	_threat_level = _level_for_count(_covering_slot_ids.size())


func get_edge_id() -> StringName:
	return _edge_id


func get_display_name() -> String:
	return _display_name


func get_from_position() -> Vector2i:
	return _from_position


func get_to_position() -> Vector2i:
	return _to_position


func get_route_ids() -> Array[StringName]:
	return _route_ids.duplicate()


func get_covering_slot_ids() -> Array[StringName]:
	return _covering_slot_ids.duplicate()


func get_coverage_count() -> int:
	return _covering_slot_ids.size()


func get_threat_level() -> StringName:
	return _threat_level


func copy() -> RouteThreatInspection:
	return RouteThreatInspection.new(
		_edge_id,
		_display_name,
		_from_position,
		_to_position,
		_route_ids,
		_covering_slot_ids,
	)


func _level_for_count(count: int) -> StringName:
	if count >= 2:
		return LEVEL_FORTIFIED
	if count == 1:
		return LEVEL_GUARDED
	return LEVEL_OPEN
