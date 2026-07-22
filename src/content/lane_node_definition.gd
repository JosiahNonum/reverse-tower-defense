class_name LaneNodeDefinition
extends Resource


@export var node_id: StringName
@export var logical_x: int
@export var logical_y: int


func to_dictionary() -> Dictionary:
	return {"id": String(node_id), "x": logical_x, "y": logical_y}
