class_name LaneMovementSystem
extends RefCounted


var _map: MapDefinition


func _init(map: MapDefinition) -> void:
	_map = map


func advance_unit(unit: UnitState) -> LaneMovementResult:
	if not unit.is_active() or unit.movement_speed_per_tick <= 0:
		return LaneMovementResult.new()
	var route: RouteDefinition = _find_route(unit.route_id)
	assert(route != null, "unit route must be validated before movement")

	var budget: int = unit.movement_speed_per_tick
	var moved: int = 0
	var entered_edges: Array[StringName] = []
	while budget > 0:
		var edge: LaneEdgeDefinition = _edge_for_unit(unit, route)
		var remaining_on_edge: int = edge.length - unit.distance_on_edge
		if budget < remaining_on_edge:
			unit.distance_on_edge += budget
			moved += budget
			budget = 0
			break

		budget -= remaining_on_edge
		moved += remaining_on_edge
		unit.distance_on_edge = edge.length
		if unit.edge_index == route.edge_ids.size() - 1:
			unit.mark_arrived()
			return LaneMovementResult.new(moved, entered_edges, true)
		unit.edge_index += 1
		unit.distance_on_edge = 0
		entered_edges.append(route.edge_ids[unit.edge_index])
	return LaneMovementResult.new(moved, entered_edges, false)


func remaining_route_distance(unit: UnitState) -> int:
	if unit.has_arrived:
		return 0
	var route: RouteDefinition = _find_route(unit.route_id)
	assert(route != null, "unit route must be validated before distance lookup")
	var remaining: int = 0
	for edge_index: int in range(unit.edge_index, route.edge_ids.size()):
		var edge: LaneEdgeDefinition = _find_edge(route.edge_ids[edge_index])
		remaining += edge.length
		if edge_index == unit.edge_index:
			remaining -= unit.distance_on_edge
	return remaining


func logical_position(unit: UnitState) -> Vector2i:
	var route: RouteDefinition = _find_route(unit.route_id)
	assert(route != null, "unit route must be validated before position lookup")
	var edge: LaneEdgeDefinition = _edge_for_unit(unit, route)
	var from_node: LaneNodeDefinition = _find_node(edge.from_node_id)
	var to_node: LaneNodeDefinition = _find_node(edge.to_node_id)
	return Vector2i(
		IntegerMath.interpolate_floor(
			from_node.logical_x,
			to_node.logical_x,
			unit.distance_on_edge,
			edge.length,
		),
		IntegerMath.interpolate_floor(
			from_node.logical_y,
			to_node.logical_y,
			unit.distance_on_edge,
			edge.length,
		),
	)


func current_edge_id(unit: UnitState) -> StringName:
	var route: RouteDefinition = _find_route(unit.route_id)
	assert(route != null, "unit route must be validated before edge lookup")
	return route.edge_ids[unit.edge_index]


func _edge_for_unit(unit: UnitState, route: RouteDefinition) -> LaneEdgeDefinition:
	assert(unit.edge_index >= 0 and unit.edge_index < route.edge_ids.size())
	var edge: LaneEdgeDefinition = _find_edge(route.edge_ids[unit.edge_index])
	assert(edge != null, "validated route edges must exist")
	return edge


func _find_route(route_id: StringName) -> RouteDefinition:
	for route: RouteDefinition in _map.routes:
		if route.route_id == route_id:
			return route
	return null


func _find_edge(edge_id: StringName) -> LaneEdgeDefinition:
	for edge: LaneEdgeDefinition in _map.edges:
		if edge.edge_id == edge_id:
			return edge
	return null


func _find_node(node_id: StringName) -> LaneNodeDefinition:
	for node: LaneNodeDefinition in _map.nodes:
		if node.node_id == node_id:
			return node
	return null
