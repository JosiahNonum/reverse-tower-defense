class_name MatchView
extends RefCounted


var _phase: StringName
var _tick: int
var _allocated_entity_count: int


func _init(view_phase: StringName, view_tick: int, entity_count: int) -> void:
	_phase = view_phase
	_tick = view_tick
	_allocated_entity_count = entity_count


func get_phase() -> StringName:
	return _phase


func get_tick() -> int:
	return _tick


func get_allocated_entity_count() -> int:
	return _allocated_entity_count


func to_dictionary() -> Dictionary:
	return {
		"phase": String(_phase),
		"tick": _tick,
		"allocated_entity_count": _allocated_entity_count,
	}
