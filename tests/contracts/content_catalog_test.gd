extends "res://tests/framework/test_case.gd"


func test_all_checked_in_content_validates_and_has_stable_fingerprint() -> void:
	var first := ContentCatalog.load_from_directory("res://content")
	var second := ContentCatalog.load_from_directory("res://content")
	var result: ContentValidationResult = first.validate()

	assert_true(result.is_valid(), _issues_text(result))
	assert_equal(first.maps.size(), 1)
	assert_equal(first.units.size(), 4)
	assert_equal(first.towers.size(), 8)
	assert_equal(first.rules.size(), 1)
	assert_equal(first.defender_profiles.size(), 3)
	assert_equal(first.content_fingerprint().length(), 64)
	assert_equal(first.content_fingerprint(), second.content_fingerprint())


func test_duplicate_and_missing_stable_ids_are_rejected() -> void:
	var catalog := ContentCatalog.new()
	var first: UnitDefinition = _valid_unit(&"unit.duplicate")
	var second: UnitDefinition = _valid_unit(&"unit.duplicate")
	var missing: UnitDefinition = _valid_unit(&"")
	catalog.add_definition(first)
	catalog.add_definition(second)
	catalog.add_definition(missing)

	var result: ContentValidationResult = catalog.validate()
	assert_true(result.has_code(ContentCatalog.CODE_DUPLICATE_ID), _issues_text(result))
	assert_true(result.has_code(ContentCatalog.CODE_MISSING_ID), _issues_text(result))


func test_bad_references_negative_and_overflow_prone_values_are_rejected() -> void:
	var catalog := ContentCatalog.new()
	var missing_upgrade: TowerDefinition = _valid_tower(&"tower.bad_reference")
	missing_upgrade.upgrade_to_id = &"tower.missing"
	var negative: UnitDefinition = _valid_unit(&"unit.negative")
	negative.cost = -1
	var overflow: UnitDefinition = _valid_unit(&"unit.overflow")
	overflow.max_health = ContentCatalog.MAX_AUTHORITATIVE_VALUE + 1
	catalog.add_definition(missing_upgrade)
	catalog.add_definition(negative)
	catalog.add_definition(overflow)

	var result: ContentValidationResult = catalog.validate()
	assert_true(result.has_code(ContentCatalog.CODE_BAD_REFERENCE), _issues_text(result))
	assert_true(result.has_code(ContentCatalog.CODE_INVALID_VALUE), _issues_text(result))
	assert_true(result.has_code(ContentCatalog.CODE_OVERFLOW_RISK), _issues_text(result))


func test_disconnected_routes_and_out_of_bounds_slots_are_rejected() -> void:
	var map := MapDefinition.new()
	map.content_id = &"map.invalid"
	map.logical_width = 100
	map.logical_height = 100
	map.spawn_node_id = &"node.spawn"
	map.core_node_id = &"node.core"
	map.nodes = [
		_node(&"node.spawn", 0, 50),
		_node(&"node.middle", 50, 50),
		_node(&"node.core", 100, 50),
	]
	map.edges = [_edge(&"edge.partial", &"node.spawn", &"node.middle", 50)]
	map.routes = [_route(&"route.invalid", [&"edge.partial"])]
	var slot := BuildSlotDefinition.new()
	slot.slot_id = &"slot.outside"
	slot.logical_x = 101
	slot.logical_y = 50
	map.build_slots = [slot]
	var catalog := ContentCatalog.new()
	catalog.add_definition(map)

	var result: ContentValidationResult = catalog.validate()
	assert_true(result.has_code(ContentCatalog.CODE_UNREACHABLE_ROUTE), _issues_text(result))
	assert_true(result.has_code(ContentCatalog.CODE_INVALID_SLOT), _issues_text(result))


func test_tower_upgrade_cycles_are_rejected() -> void:
	var first: TowerDefinition = _valid_tower(&"tower.first")
	var second: TowerDefinition = _valid_tower(&"tower.second")
	first.upgrade_to_id = second.content_id
	second.upgrade_to_id = first.content_id
	var catalog := ContentCatalog.new()
	catalog.add_definition(first)
	catalog.add_definition(second)

	var result: ContentValidationResult = catalog.validate()
	assert_true(result.has_code(ContentCatalog.CODE_UPGRADE_CYCLE), _issues_text(result))


func test_cached_resource_definitions_are_not_mutated_by_runtime_state() -> void:
	var first_definition: UnitDefinition = ResourceLoader.load(
		"res://content/units/tank.tres",
		"",
		ResourceLoader.CACHE_MODE_REUSE,
	) as UnitDefinition
	var second_definition: UnitDefinition = ResourceLoader.load(
		"res://content/units/tank.tres",
		"",
		ResourceLoader.CACHE_MODE_REUSE,
	) as UnitDefinition
	var first_state := UnitState.new(first_definition)
	var second_state := UnitState.new(second_definition)

	first_state.apply_damage(90)

	assert_true(first_definition == second_definition, "expected Godot to reuse the cached definition")
	assert_equal(first_definition.max_health, 280)
	assert_equal(first_state.health, 190)
	assert_equal(second_state.health, 280)


func _valid_unit(content_id: StringName) -> UnitDefinition:
	var unit := UnitDefinition.new()
	unit.content_id = content_id
	unit.cost = 1
	unit.max_health = 1
	unit.speed_per_tick = 1
	unit.leak_damage = 1
	return unit


func _valid_tower(content_id: StringName) -> TowerDefinition:
	var tower := TowerDefinition.new()
	tower.content_id = content_id
	tower.cost = 1
	tower.range = 1
	tower.damage = 1
	tower.cooldown_ticks = 1
	tower.targeting_kind = TowerDefinition.TARGET_RAPID
	return tower


func _node(content_id: StringName, x: int, y: int) -> LaneNodeDefinition:
	var node := LaneNodeDefinition.new()
	node.node_id = content_id
	node.logical_x = x
	node.logical_y = y
	return node


func _edge(
	content_id: StringName,
	from_id: StringName,
	to_id: StringName,
	length: int,
) -> LaneEdgeDefinition:
	var edge := LaneEdgeDefinition.new()
	edge.edge_id = content_id
	edge.from_node_id = from_id
	edge.to_node_id = to_id
	edge.length = length
	return edge


func _route(content_id: StringName, edge_ids: Array[StringName]) -> RouteDefinition:
	var route := RouteDefinition.new()
	route.route_id = content_id
	route.edge_ids = edge_ids
	return route


func _issues_text(result: ContentValidationResult) -> String:
	var lines: PackedStringArray = []
	for issue: ContentValidationIssue in result.issues:
		lines.append(issue.format())
	return "\n".join(lines)
