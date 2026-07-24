class_name LaneMovementResult
extends RefCounted


var moved_distance: int
var entered_edge_ids: Array[StringName]
var arrived_now: bool


func _init(
	distance_moved: int = 0,
	entered_edges: Array[StringName] = [],
	did_arrive: bool = false,
) -> void:
	moved_distance = distance_moved
	entered_edge_ids = entered_edges.duplicate()
	arrived_now = did_arrive
