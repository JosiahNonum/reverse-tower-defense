class_name RouteDefinition
extends Resource


@export var route_id: StringName
@export var edge_ids: Array[StringName] = []


func to_dictionary() -> Dictionary:
	var serialized_edges: Array[String] = []
	for edge_id: StringName in edge_ids:
		serialized_edges.append(String(edge_id))
	return {"id": String(route_id), "edges": serialized_edges}
