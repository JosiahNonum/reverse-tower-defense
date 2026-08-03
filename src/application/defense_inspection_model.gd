class_name DefenseInspectionModel
extends RefCounted


var _map_id: StringName
var _logical_size: Vector2i
var _towers: Array[DefenseTowerInspection] = []
var _segments: Array[RouteThreatInspection] = []


func _init(
	map_id: StringName,
	logical_size: Vector2i,
	towers: Array[DefenseTowerInspection],
	segments: Array[RouteThreatInspection],
) -> void:
	_map_id = map_id
	_logical_size = logical_size
	for tower: DefenseTowerInspection in towers:
		_towers.append(tower.copy())
	for segment: RouteThreatInspection in segments:
		_segments.append(segment.copy())


func get_map_id() -> StringName:
	return _map_id


func get_logical_size() -> Vector2i:
	return _logical_size


func get_towers() -> Array[DefenseTowerInspection]:
	var result: Array[DefenseTowerInspection] = []
	for tower: DefenseTowerInspection in _towers:
		result.append(tower.copy())
	return result


func get_segments() -> Array[RouteThreatInspection]:
	var result: Array[RouteThreatInspection] = []
	for segment: RouteThreatInspection in _segments:
		result.append(segment.copy())
	return result


func get_tower(slot_id: StringName) -> DefenseTowerInspection:
	for tower: DefenseTowerInspection in _towers:
		if tower.get_slot_id() == slot_id:
			return tower.copy()
	return null


func get_segment(edge_id: StringName) -> RouteThreatInspection:
	for segment: RouteThreatInspection in _segments:
		if segment.get_edge_id() == edge_id:
			return segment.copy()
	return null


func get_most_defended_segments(limit: int) -> Array[RouteThreatInspection]:
	var ordered: Array[RouteThreatInspection] = get_segments()
	ordered.sort_custom(func(left: RouteThreatInspection, right: RouteThreatInspection) -> bool:
		if left.get_coverage_count() != right.get_coverage_count():
			return left.get_coverage_count() > right.get_coverage_count()
		if left.get_route_ids().size() != right.get_route_ids().size():
			return left.get_route_ids().size() > right.get_route_ids().size()
		return String(left.get_edge_id()) < String(right.get_edge_id())
	)
	var result: Array[RouteThreatInspection] = []
	for index: int in mini(limit, ordered.size()):
		result.append(ordered[index].copy())
	return result
