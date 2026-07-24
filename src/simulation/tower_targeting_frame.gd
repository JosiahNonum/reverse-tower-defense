class_name TowerTargetingFrame
extends RefCounted


var active_units: Array[UnitState] = []
var positions: Dictionary[int, Vector2i] = {}
var remaining_route_distances: Dictionary[int, int] = {}


func add(
	unit: UnitState,
	position: Vector2i,
	remaining_route_distance: int,
) -> void:
	active_units.append(unit)
	positions[unit.entity_id] = position
	remaining_route_distances[unit.entity_id] = remaining_route_distance
