class_name StableOrder
extends RefCounted


static func first_target(candidates: Array[TargetCandidate]) -> TargetCandidate:
	assert(not candidates.is_empty(), "Target selection requires at least one candidate")
	var ordered: Array[TargetCandidate] = []
	ordered.append_array(candidates)
	ordered.sort_custom(_target_precedes)
	return ordered[0]


static func _target_precedes(left: TargetCandidate, right: TargetCandidate) -> bool:
	if left.remaining_route_distance != right.remaining_route_distance:
		return left.remaining_route_distance < right.remaining_route_distance
	return left.entity_id < right.entity_id
