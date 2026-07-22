class_name ContentCatalog
extends RefCounted


const MAX_AUTHORITATIVE_VALUE: int = 1_000_000_000
const CODE_MISSING_ID: StringName = &"missing_id"
const CODE_DUPLICATE_ID: StringName = &"duplicate_id"
const CODE_BAD_REFERENCE: StringName = &"bad_reference"
const CODE_INVALID_VALUE: StringName = &"invalid_value"
const CODE_OVERFLOW_RISK: StringName = &"overflow_risk"
const CODE_UNREACHABLE_ROUTE: StringName = &"unreachable_route"
const CODE_INVALID_SLOT: StringName = &"invalid_slot"
const CODE_UPGRADE_CYCLE: StringName = &"upgrade_cycle"
const CODE_UNSUPPORTED_COMBINATION: StringName = &"unsupported_combination"

var maps: Array[MapDefinition] = []
var units: Array[UnitDefinition] = []
var towers: Array[TowerDefinition] = []
var rules: Array[MatchRulesDefinition] = []
var defender_profiles: Array[DefenderProfileDefinition] = []


static func load_from_directory(root_path: String) -> ContentCatalog:
	var catalog := ContentCatalog.new()
	var paths: Array[String] = []
	_collect_resource_paths(root_path, paths)
	paths.sort()
	for path: String in paths:
		var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		assert(resource != null, "Could not load content resource: %s" % path)
		catalog.add_definition(resource)
	return catalog


func add_definition(definition: Resource) -> void:
	if definition is MapDefinition:
		maps.append(definition)
	elif definition is UnitDefinition:
		units.append(definition)
	elif definition is TowerDefinition:
		towers.append(definition)
	elif definition is MatchRulesDefinition:
		rules.append(definition)
	elif definition is DefenderProfileDefinition:
		defender_profiles.append(definition)
	else:
		assert(false, "Unsupported content definition: %s" % definition.get_class())


func validate() -> ContentValidationResult:
	var result := ContentValidationResult.new()
	var definitions_by_id: Dictionary[StringName, Resource] = {}
	for definition: Resource in _all_definitions():
		var content_id: StringName = definition.get("content_id")
		_validate_id(content_id, definition.get_class(), result)
		if content_id == &"":
			continue
		if definitions_by_id.has(content_id):
			result.add(CODE_DUPLICATE_ID, String(content_id), "stable content ID is duplicated")
		else:
			definitions_by_id[content_id] = definition

	for map: MapDefinition in maps:
		_validate_map(map, result)
	for unit: UnitDefinition in units:
		_validate_unit(unit, result)
	for tower: TowerDefinition in towers:
		_validate_tower(tower, result)
	for profile: DefenderProfileDefinition in defender_profiles:
		_validate_profile(profile, result)
	_validate_references(result)
	_validate_upgrade_cycles(result)
	return result


func content_fingerprint() -> String:
	var serialized_definitions: Array[String] = []
	for definition: Resource in _all_definitions():
		serialized_definitions.append(JSON.stringify(definition.call("to_dictionary")))
	serialized_definitions.sort()
	return "\n".join(serialized_definitions).sha256_text()


func get_unit(unit_id: StringName) -> UnitDefinition:
	for unit: UnitDefinition in units:
		if unit.content_id == unit_id:
			return unit
	return null


func _all_definitions() -> Array[Resource]:
	var definitions: Array[Resource] = []
	definitions.append_array(maps)
	definitions.append_array(units)
	definitions.append_array(towers)
	definitions.append_array(rules)
	definitions.append_array(defender_profiles)
	return definitions


func _validate_map(map: MapDefinition, result: ContentValidationResult) -> void:
	_validate_positive(map.logical_width, "%s.logical_width" % map.content_id, result)
	_validate_positive(map.logical_height, "%s.logical_height" % map.content_id, result)
	var nodes_by_id: Dictionary[StringName, LaneNodeDefinition] = {}
	var edges_by_id: Dictionary[StringName, LaneEdgeDefinition] = {}
	var local_ids: Dictionary[StringName, bool] = {}

	for node: LaneNodeDefinition in map.nodes:
		_validate_local_id(node.node_id, "%s.nodes" % map.content_id, local_ids, result)
		nodes_by_id[node.node_id] = node
		_validate_coordinate(node.logical_x, map.logical_width, "%s.%s.x" % [map.content_id, node.node_id], result)
		_validate_coordinate(node.logical_y, map.logical_height, "%s.%s.y" % [map.content_id, node.node_id], result)
	for edge: LaneEdgeDefinition in map.edges:
		_validate_local_id(edge.edge_id, "%s.edges" % map.content_id, local_ids, result)
		edges_by_id[edge.edge_id] = edge
		_validate_positive(edge.length, "%s.%s.length" % [map.content_id, edge.edge_id], result)
		if not nodes_by_id.has(edge.from_node_id) or not nodes_by_id.has(edge.to_node_id):
			result.add(CODE_BAD_REFERENCE, "%s.%s" % [map.content_id, edge.edge_id], "edge references a missing node")
	for route: RouteDefinition in map.routes:
		_validate_local_id(route.route_id, "%s.routes" % map.content_id, local_ids, result)
		_validate_route(map, route, edges_by_id, result)
	for slot: BuildSlotDefinition in map.build_slots:
		_validate_local_id(slot.slot_id, "%s.build_slots" % map.content_id, local_ids, result)
		if slot.logical_x < 0 or slot.logical_x > map.logical_width or slot.logical_y < 0 or slot.logical_y > map.logical_height:
			result.add(CODE_INVALID_SLOT, "%s.%s" % [map.content_id, slot.slot_id], "slot is outside logical bounds")
		for tag: StringName in slot.allowed_tower_tags:
			if slot.forbidden_tower_tags.has(tag):
				result.add(CODE_INVALID_SLOT, "%s.%s" % [map.content_id, slot.slot_id], "tower tag is both allowed and forbidden")
	if not nodes_by_id.has(map.spawn_node_id) or not nodes_by_id.has(map.core_node_id):
		result.add(CODE_BAD_REFERENCE, String(map.content_id), "spawn or core node is missing")


func _validate_route(
	map: MapDefinition,
	route: RouteDefinition,
	edges_by_id: Dictionary[StringName, LaneEdgeDefinition],
	result: ContentValidationResult,
) -> void:
	if route.edge_ids.is_empty():
		result.add(CODE_UNREACHABLE_ROUTE, "%s.%s" % [map.content_id, route.route_id], "route has no edges")
		return
	var expected_node: StringName = map.spawn_node_id
	var visited_nodes: Dictionary[StringName, bool] = {expected_node: true}
	for edge_id: StringName in route.edge_ids:
		if not edges_by_id.has(edge_id):
			result.add(CODE_BAD_REFERENCE, "%s.%s" % [map.content_id, route.route_id], "route references missing edge %s" % edge_id)
			return
		var edge: LaneEdgeDefinition = edges_by_id[edge_id]
		if edge.from_node_id != expected_node:
			result.add(CODE_UNREACHABLE_ROUTE, "%s.%s" % [map.content_id, route.route_id], "route edges are disconnected")
			return
		if visited_nodes.has(edge.to_node_id):
			result.add(CODE_UNREACHABLE_ROUTE, "%s.%s" % [map.content_id, route.route_id], "route contains a cycle")
			return
		visited_nodes[edge.to_node_id] = true
		expected_node = edge.to_node_id
	if expected_node != map.core_node_id:
		result.add(CODE_UNREACHABLE_ROUTE, "%s.%s" % [map.content_id, route.route_id], "route does not end at the core")


func _validate_unit(unit: UnitDefinition, result: ContentValidationResult) -> void:
	_validate_nonnegative(unit.cost, "%s.cost" % unit.content_id, result)
	_validate_positive(unit.max_health, "%s.max_health" % unit.content_id, result)
	_validate_nonnegative(unit.armor, "%s.armor" % unit.content_id, result)
	_validate_positive(unit.speed_per_tick, "%s.speed_per_tick" % unit.content_id, result)
	_validate_positive(unit.leak_damage, "%s.leak_damage" % unit.content_id, result)
	_validate_nonnegative(unit.rally_range, "%s.rally_range" % unit.content_id, result)
	if unit.rally_range > 0 and (unit.rally_numerator <= 0 or unit.rally_denominator <= 0):
		result.add(CODE_UNSUPPORTED_COMBINATION, String(unit.content_id), "Rally requires a positive ratio")


func _validate_tower(tower: TowerDefinition, result: ContentValidationResult) -> void:
	_validate_nonnegative(tower.cost, "%s.cost" % tower.content_id, result)
	_validate_positive(tower.range, "%s.range" % tower.content_id, result)
	_validate_nonnegative(tower.damage, "%s.damage" % tower.content_id, result)
	_validate_positive(tower.cooldown_ticks, "%s.cooldown_ticks" % tower.content_id, result)
	_validate_nonnegative(tower.splash_radius, "%s.splash_radius" % tower.content_id, result)
	_validate_nonnegative(tower.slow_numerator, "%s.slow_numerator" % tower.content_id, result)
	_validate_positive(tower.slow_denominator, "%s.slow_denominator" % tower.content_id, result)
	_validate_nonnegative(tower.slow_duration_ticks, "%s.slow_duration_ticks" % tower.content_id, result)
	var kinds: Array[StringName] = [TowerDefinition.TARGET_RAPID, TowerDefinition.TARGET_SPLASH, TowerDefinition.TARGET_CONTROL, TowerDefinition.TARGET_ANTI_ARMOR]
	if not kinds.has(tower.targeting_kind):
		result.add(CODE_UNSUPPORTED_COMBINATION, String(tower.content_id), "unknown targeting comparator")
	if tower.targeting_kind == TowerDefinition.TARGET_SPLASH and tower.splash_radius <= 0:
		result.add(CODE_UNSUPPORTED_COMBINATION, String(tower.content_id), "Splash targeting requires a positive radius")
	if tower.targeting_kind == TowerDefinition.TARGET_CONTROL and (tower.slow_numerator <= 0 or tower.slow_denominator <= 0 or tower.slow_duration_ticks <= 0):
		result.add(CODE_UNSUPPORTED_COMBINATION, String(tower.content_id), "Control targeting requires a positive Slow")
	if tower.targeting_kind != TowerDefinition.TARGET_SPLASH and tower.splash_radius != 0:
		result.add(CODE_UNSUPPORTED_COMBINATION, String(tower.content_id), "only Splash towers may define a splash radius")
	if tower.targeting_kind != TowerDefinition.TARGET_CONTROL and (tower.slow_numerator != 0 or tower.slow_duration_ticks != 0):
		result.add(CODE_UNSUPPORTED_COMBINATION, String(tower.content_id), "only Control towers may define Slow")


func _validate_profile(profile: DefenderProfileDefinition, result: ContentValidationResult) -> void:
	_validate_nonnegative(profile.history_delay_rounds, "%s.history_delay" % profile.content_id, result)
	_validate_positive(profile.candidate_cap, "%s.candidate_cap" % profile.content_id, result)
	_validate_positive(profile.action_cap, "%s.action_cap" % profile.content_id, result)
	if profile.reserve_basis_points < 0 or profile.reserve_basis_points > 10000:
		result.add(CODE_INVALID_VALUE, "%s.reserve_basis_points" % profile.content_id, "basis points must be between 0 and 10000")
	if profile.variation_basis_points < 0 or profile.variation_basis_points > 10000:
		result.add(CODE_INVALID_VALUE, "%s.variation_basis_points" % profile.content_id, "basis points must be between 0 and 10000")
	for weight: int in profile.scoring_weights.values():
		_validate_nonnegative(weight, "%s.scoring_weights" % profile.content_id, result)


func _validate_references(result: ContentValidationResult) -> void:
	var map_ids: Dictionary[StringName, bool] = {}
	var route_ids: Dictionary[StringName, bool] = {}
	var unit_ids: Dictionary[StringName, bool] = {}
	var tower_ids: Dictionary[StringName, bool] = {}
	var profile_ids: Dictionary[StringName, bool] = {}
	for map: MapDefinition in maps:
		map_ids[map.content_id] = true
		for route: RouteDefinition in map.routes:
			route_ids[route.route_id] = true
	for unit: UnitDefinition in units:
		unit_ids[unit.content_id] = true
		for route_id: StringName in unit.allowed_route_ids:
			if not route_ids.has(route_id):
				result.add(CODE_BAD_REFERENCE, String(unit.content_id), "unit references missing route %s" % route_id)
	for tower: TowerDefinition in towers:
		tower_ids[tower.content_id] = true
	for profile: DefenderProfileDefinition in defender_profiles:
		profile_ids[profile.content_id] = true
	for tower: TowerDefinition in towers:
		if tower.upgrade_to_id != &"" and not tower_ids.has(tower.upgrade_to_id):
			result.add(CODE_BAD_REFERENCE, String(tower.content_id), "tower references missing upgrade %s" % tower.upgrade_to_id)
	for match_rules: MatchRulesDefinition in rules:
		_validate_rules(match_rules, map_ids, unit_ids, tower_ids, profile_ids, result)


func _validate_rules(
	match_rules: MatchRulesDefinition,
	map_ids: Dictionary[StringName, bool],
	unit_ids: Dictionary[StringName, bool],
	tower_ids: Dictionary[StringName, bool],
	profile_ids: Dictionary[StringName, bool],
	result: ContentValidationResult,
) -> void:
	if match_rules.rules_version.is_empty():
		result.add(CODE_INVALID_VALUE, String(match_rules.content_id), "rules version is required")
	if not map_ids.has(match_rules.map_id):
		result.add(CODE_BAD_REFERENCE, String(match_rules.content_id), "rules reference a missing map")
	_validate_reference_list(match_rules.content_id, "unit", match_rules.unit_ids, unit_ids, result)
	_validate_reference_list(match_rules.content_id, "tower", match_rules.tower_ids, tower_ids, result)
	_validate_reference_list(match_rules.content_id, "profile", match_rules.defender_profile_ids, profile_ids, result)
	_validate_positive(match_rules.round_count, "%s.round_count" % match_rules.content_id, result)
	if match_rules.attack_budgets.size() != match_rules.round_count:
		result.add(CODE_INVALID_VALUE, String(match_rules.content_id), "attack budget count must equal round count")
	for budget: int in match_rules.attack_budgets:
		_validate_nonnegative(budget, "%s.attack_budgets" % match_rules.content_id, result)
	_validate_nonnegative(match_rules.initial_defense_budget, "%s.initial_defense_budget" % match_rules.content_id, result)
	_validate_nonnegative(match_rules.adaptation_grant, "%s.adaptation_grant" % match_rules.content_id, result)
	if match_rules.sale_refund_basis_points < 0 or match_rules.sale_refund_basis_points > 10000:
		result.add(CODE_INVALID_VALUE, "%s.sale_refund_basis_points" % match_rules.content_id, "basis points must be between 0 and 10000")
	_validate_positive(match_rules.core_health, "%s.core_health" % match_rules.content_id, result)
	_validate_positive(match_rules.ticks_per_second, "%s.ticks_per_second" % match_rules.content_id, result)


func _validate_reference_list(
	owner_id: StringName,
	kind: String,
	ids: Array[StringName],
	known_ids: Dictionary[StringName, bool],
	result: ContentValidationResult,
) -> void:
	for referenced_id: StringName in ids:
		if not known_ids.has(referenced_id):
			result.add(CODE_BAD_REFERENCE, String(owner_id), "%s reference is missing: %s" % [kind, referenced_id])


func _validate_upgrade_cycles(result: ContentValidationResult) -> void:
	var towers_by_id: Dictionary[StringName, TowerDefinition] = {}
	for tower: TowerDefinition in towers:
		towers_by_id[tower.content_id] = tower
	for start: TowerDefinition in towers:
		if start.upgrade_to_id != &"" and towers_by_id.has(start.upgrade_to_id):
			var upgrade: TowerDefinition = towers_by_id[start.upgrade_to_id]
			if upgrade.upgrade_to_id != &"":
				result.add(CODE_UNSUPPORTED_COMBINATION, String(start.content_id), "v0 towers support at most one upgrade")
		var visited: Dictionary[StringName, bool] = {}
		var current_id: StringName = start.content_id
		while current_id != &"" and towers_by_id.has(current_id):
			if visited.has(current_id):
				result.add(CODE_UPGRADE_CYCLE, String(start.content_id), "tower upgrade chain contains a cycle")
				break
			visited[current_id] = true
			current_id = towers_by_id[current_id].upgrade_to_id


func _validate_id(content_id: StringName, location: String, result: ContentValidationResult) -> void:
	if content_id == &"":
		result.add(CODE_MISSING_ID, location, "stable content ID is required")
		return
	var value: String = String(content_id)
	for index: int in value.length():
		var character: String = value.substr(index, 1)
		if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character not in [".", "_", "-"]:
			result.add(CODE_INVALID_VALUE, value, "stable IDs use lowercase ASCII letters, digits, dot, underscore, or dash")
			return


func _validate_local_id(
	content_id: StringName,
	location: String,
	known_ids: Dictionary[StringName, bool],
	result: ContentValidationResult,
) -> void:
	_validate_id(content_id, location, result)
	if content_id == &"":
		return
	if known_ids.has(content_id):
		result.add(CODE_DUPLICATE_ID, location, "map-local stable ID is duplicated: %s" % content_id)
	known_ids[content_id] = true


func _validate_coordinate(value: int, maximum: int, location: String, result: ContentValidationResult) -> void:
	if value < 0 or value > maximum:
		result.add(CODE_INVALID_VALUE, location, "coordinate is outside map bounds")


func _validate_positive(value: int, location: String, result: ContentValidationResult) -> void:
	if value <= 0:
		result.add(CODE_INVALID_VALUE, location, "value must be positive")
	elif value > MAX_AUTHORITATIVE_VALUE:
		result.add(CODE_OVERFLOW_RISK, location, "value exceeds the authoritative safety limit")


func _validate_nonnegative(value: int, location: String, result: ContentValidationResult) -> void:
	if value < 0:
		result.add(CODE_INVALID_VALUE, location, "value must be nonnegative")
	elif value > MAX_AUTHORITATIVE_VALUE:
		result.add(CODE_OVERFLOW_RISK, location, "value exceeds the authoritative safety limit")


static func _collect_resource_paths(directory_path: String, paths: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if file_name.ends_with(".tres"):
			paths.append(directory_path.path_join(file_name))
	for child_name: String in directory.get_directories():
		_collect_resource_paths(directory_path.path_join(child_name), paths)
