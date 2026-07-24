class_name EntityView
extends RefCounted

var _entity_id: int
var _kind: StringName
var _logical_x: int
var _logical_y: int

func _init(entity_id: int, kind: StringName, logical_x: int, logical_y: int) -> void:
	_entity_id = entity_id
	_kind = kind
	_logical_x = logical_x
	_logical_y = logical_y

func get_entity_id() -> int:
	return _entity_id

func get_kind() -> StringName:
	return _kind

func get_logical_x() -> int:
	return _logical_x

func get_logical_y() -> int:
	return _logical_y

func copy() -> EntityView:
	return EntityView.new(_entity_id, _kind, _logical_x, _logical_y)

func to_dictionary() -> Dictionary:
	return {"entity_id": _entity_id, "kind": String(_kind), "logical_x": _logical_x, "logical_y": _logical_y}
