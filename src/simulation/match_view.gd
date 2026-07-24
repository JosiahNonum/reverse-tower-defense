class_name MatchView
extends RefCounted


var _phase: StringName
var _tick: int
var _allocated_entity_count: int
var _entities: Array[EntityView] = []


func _init(view_phase: StringName, view_tick: int, entity_count: int, view_entities: Array[EntityView] = []) -> void:
	_phase = view_phase
	_tick = view_tick
	_allocated_entity_count = entity_count
	for entity: EntityView in view_entities:
		_entities.append(entity.copy())


func get_phase() -> StringName:
	return _phase


func get_tick() -> int:
	return _tick


func get_allocated_entity_count() -> int:
	return _allocated_entity_count

func get_entities() -> Array[EntityView]:
	var copy: Array[EntityView] = []
	for entity: EntityView in _entities:
		copy.append(entity.copy())
	return copy


func to_dictionary() -> Dictionary:
	return {
		"phase": String(_phase),
		"tick": _tick,
		"allocated_entity_count": _allocated_entity_count,
		"entities": _entity_dictionaries(),
	}

func _entity_dictionaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entity: EntityView in _entities:
		result.append(entity.to_dictionary())
	return result
