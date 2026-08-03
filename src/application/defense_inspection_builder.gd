class_name DefenseInspectionBuilder
extends RefCounted


func build(
	catalog: ContentCatalog,
	map: MapDefinition,
	deployments: Array[TowerDeployment],
) -> DefenseInspectionModel:
	var route_ids_by_edge: Dictionary[StringName, Array] = _route_ids_by_edge(map)
	var slot_by_id: Dictionary[StringName, BuildSlotDefinition] = {}
	for slot: BuildSlotDefinition in map.build_slots:
		slot_by_id[slot.slot_id] = slot

	var covered_edges_by_slot: Dictionary[StringName, Array] = {}
	var covering_slots_by_edge: Dictionary[StringName, Array] = {}
	for edge: LaneEdgeDefinition in map.edges:
		covering_slots_by_edge[edge.edge_id] = []

	var occupied_slots: Dictionary[StringName, bool] = {}
	for deployment: TowerDeployment in deployments:
		assert(slot_by_id.has(deployment.slot_id), "inspection deployment slot must exist")
		assert(
			not occupied_slots.has(deployment.slot_id),
			"inspection deployment slots may only be occupied once",
		)
		var tower: TowerDefinition = catalog.get_tower(deployment.tower_id)
		assert(tower != null, "inspection deployment tower must exist")
		var slot: BuildSlotDefinition = slot_by_id[deployment.slot_id]
		occupied_slots[deployment.slot_id] = true
		var covered_edges: Array[StringName] = []
		for edge: LaneEdgeDefinition in map.edges:
			if _tower_covers_edge(tower, slot, edge, map):
				covered_edges.append(edge.edge_id)
				covering_slots_by_edge[edge.edge_id].append(slot.slot_id)
		covered_edges.sort()
		covered_edges_by_slot[slot.slot_id] = covered_edges

	var tower_inspections: Array[DefenseTowerInspection] = []
	for deployment: TowerDeployment in deployments:
		var tower: TowerDefinition = catalog.get_tower(deployment.tower_id)
		var slot: BuildSlotDefinition = slot_by_id[deployment.slot_id]
		var covered_edges: Array[StringName] = []
		covered_edges.assign(covered_edges_by_slot[slot.slot_id])
		var covered_routes: Array[StringName] = _routes_for_edges(
			covered_edges,
			route_ids_by_edge,
		)
		tower_inspections.append(DefenseTowerInspection.new(
			tower.content_id,
			_humanize_id(tower.content_id),
			slot.slot_id,
			Vector2i(slot.logical_x, slot.logical_y),
			tower.range,
			tower.targeting_kind,
			_targeting_summary(tower.targeting_kind),
			tower.upgrade_to_id,
			_upgrade_summary(catalog, tower),
			covered_routes,
			covered_edges,
		))

	var segment_inspections: Array[RouteThreatInspection] = []
	for edge: LaneEdgeDefinition in map.edges:
		var from_node: LaneNodeDefinition = _find_node(map, edge.from_node_id)
		var to_node: LaneNodeDefinition = _find_node(map, edge.to_node_id)
		var route_ids: Array[StringName] = []
		route_ids.assign(route_ids_by_edge[edge.edge_id])
		var covering_slots: Array[StringName] = []
		covering_slots.assign(covering_slots_by_edge[edge.edge_id])
		covering_slots.sort()
		segment_inspections.append(RouteThreatInspection.new(
			edge.edge_id,
			"%s → %s" % [
				_humanize_id(edge.from_node_id),
				_humanize_id(edge.to_node_id),
			],
			Vector2i(from_node.logical_x, from_node.logical_y),
			Vector2i(to_node.logical_x, to_node.logical_y),
			route_ids,
			covering_slots,
		))

	return DefenseInspectionModel.new(
		map.content_id,
		Vector2i(map.logical_width, map.logical_height),
		tower_inspections,
		segment_inspections,
	)


func _route_ids_by_edge(map: MapDefinition) -> Dictionary[StringName, Array]:
	var result: Dictionary[StringName, Array] = {}
	for edge: LaneEdgeDefinition in map.edges:
		result[edge.edge_id] = []
	for route: RouteDefinition in map.routes:
		for edge_id: StringName in route.edge_ids:
			result[edge_id].append(route.route_id)
	for route_ids: Array in result.values():
		route_ids.sort()
	return result


func _routes_for_edges(
	edge_ids: Array[StringName],
	route_ids_by_edge: Dictionary[StringName, Array],
) -> Array[StringName]:
	var known: Dictionary[StringName, bool] = {}
	for edge_id: StringName in edge_ids:
		for route_id: StringName in route_ids_by_edge[edge_id]:
			known[route_id] = true
	var result: Array[StringName] = []
	result.assign(known.keys())
	result.sort()
	return result


func _tower_covers_edge(
	tower: TowerDefinition,
	slot: BuildSlotDefinition,
	edge: LaneEdgeDefinition,
	map: MapDefinition,
) -> bool:
	var from_node: LaneNodeDefinition = _find_node(map, edge.from_node_id)
	var to_node: LaneNodeDefinition = _find_node(map, edge.to_node_id)
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
		Vector2(slot.logical_x, slot.logical_y),
		Vector2(from_node.logical_x, from_node.logical_y),
		Vector2(to_node.logical_x, to_node.logical_y),
	)
	var distance_squared: float = Vector2(
		slot.logical_x,
		slot.logical_y,
	).distance_squared_to(closest)
	return distance_squared <= float(tower.range) * float(tower.range)


func _find_node(map: MapDefinition, node_id: StringName) -> LaneNodeDefinition:
	for node: LaneNodeDefinition in map.nodes:
		if node.node_id == node_id:
			return node
	assert(false, "validated map edge must reference an existing node")
	return null


func _targeting_summary(targeting_kind: StringName) -> String:
	match targeting_kind:
		TowerDefinition.TARGET_SPLASH:
			return "Densest in-range cluster, then frontmost progress and stable ID."
		TowerDefinition.TARGET_CONTROL:
			return "Unslowed and faster units first, then frontmost progress and stable ID."
		TowerDefinition.TARGET_ANTI_ARMOR:
			return "Highest armor and health first, then frontmost progress and stable ID."
		_:
			return "Frontmost route progress first; stable ID breaks exact ties."


func _upgrade_summary(
	catalog: ContentCatalog,
	tower: TowerDefinition,
) -> String:
	if tower.upgrade_to_id == &"":
		return "No further v0 upgrade."
	var upgrade: TowerDefinition = catalog.get_tower(tower.upgrade_to_id)
	assert(upgrade != null, "validated upgrade definition must exist")
	return "%s · %d damage · %.2f range · every %d ticks" % [
		_humanize_id(upgrade.content_id),
		upgrade.damage,
		float(upgrade.range) / 1000.0,
		upgrade.cooldown_ticks,
	]


func _humanize_id(content_id: StringName) -> String:
	var pieces: PackedStringArray = String(content_id).split(".")
	var meaningful: PackedStringArray = pieces.slice(1) if pieces.size() > 1 else pieces
	var words: PackedStringArray = "_".join(meaningful).split("_")
	for index: int in words.size():
		words[index] = words[index].capitalize()
	return " ".join(words)
