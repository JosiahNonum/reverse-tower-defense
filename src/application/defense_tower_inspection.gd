class_name DefenseTowerInspection
extends RefCounted


var _tower_id: StringName
var _tower_name: String
var _slot_id: StringName
var _logical_position: Vector2i
var _range: int
var _targeting_kind: StringName
var _targeting_summary: String
var _upgrade_id: StringName
var _upgrade_summary: String
var _route_ids: Array[StringName] = []
var _covered_edge_ids: Array[StringName] = []


func _init(
	tower_id: StringName,
	tower_name: String,
	slot_id: StringName,
	logical_position: Vector2i,
	tower_range: int,
	targeting_kind: StringName,
	targeting_summary: String,
	upgrade_id: StringName,
	upgrade_summary: String,
	route_ids: Array[StringName],
	covered_edge_ids: Array[StringName],
) -> void:
	_tower_id = tower_id
	_tower_name = tower_name
	_slot_id = slot_id
	_logical_position = logical_position
	_range = tower_range
	_targeting_kind = targeting_kind
	_targeting_summary = targeting_summary
	_upgrade_id = upgrade_id
	_upgrade_summary = upgrade_summary
	_route_ids.assign(route_ids)
	_covered_edge_ids.assign(covered_edge_ids)


func get_tower_id() -> StringName:
	return _tower_id


func get_tower_name() -> String:
	return _tower_name


func get_slot_id() -> StringName:
	return _slot_id


func get_logical_position() -> Vector2i:
	return _logical_position


func get_range() -> int:
	return _range


func get_targeting_kind() -> StringName:
	return _targeting_kind


func get_targeting_summary() -> String:
	return _targeting_summary


func get_upgrade_id() -> StringName:
	return _upgrade_id


func get_upgrade_summary() -> String:
	return _upgrade_summary


func get_route_ids() -> Array[StringName]:
	return _route_ids.duplicate()


func get_covered_edge_ids() -> Array[StringName]:
	return _covered_edge_ids.duplicate()


func copy() -> DefenseTowerInspection:
	return DefenseTowerInspection.new(
		_tower_id,
		_tower_name,
		_slot_id,
		_logical_position,
		_range,
		_targeting_kind,
		_targeting_summary,
		_upgrade_id,
		_upgrade_summary,
		_route_ids,
		_covered_edge_ids,
	)
