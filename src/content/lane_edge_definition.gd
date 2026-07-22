class_name LaneEdgeDefinition
extends Resource


@export var edge_id: StringName
@export var from_node_id: StringName
@export var to_node_id: StringName
@export var length: int


func to_dictionary() -> Dictionary:
	return {
		"id": String(edge_id),
		"from": String(from_node_id),
		"to": String(to_node_id),
		"length": length,
	}
