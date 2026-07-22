class_name MapDefinition
extends Resource


@export var content_id: StringName
@export var logical_width: int
@export var logical_height: int
@export var spawn_node_id: StringName
@export var core_node_id: StringName
@export var nodes: Array[LaneNodeDefinition] = []
@export var edges: Array[LaneEdgeDefinition] = []
@export var routes: Array[RouteDefinition] = []
@export var build_slots: Array[BuildSlotDefinition] = []
@export_file("*.tscn") var presentation_scene_path: String


func to_dictionary() -> Dictionary:
	return {
		"kind": "map",
		"id": String(content_id),
		"width": logical_width,
		"height": logical_height,
		"spawn": String(spawn_node_id),
		"core": String(core_node_id),
		"nodes": _resource_dictionaries(nodes),
		"edges": _resource_dictionaries(edges),
		"routes": _resource_dictionaries(routes),
		"build_slots": _resource_dictionaries(build_slots),
		"presentation": presentation_scene_path,
	}


func _resource_dictionaries(resources: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for resource: Resource in resources:
		result.append(resource.call("to_dictionary"))
	return result
