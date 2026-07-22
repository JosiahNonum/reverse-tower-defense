class_name TargetCandidate
extends RefCounted


var entity_id: int
var remaining_route_distance: int


func _init(candidate_entity_id: int, candidate_remaining_distance: int) -> void:
	entity_id = candidate_entity_id
	remaining_route_distance = candidate_remaining_distance
