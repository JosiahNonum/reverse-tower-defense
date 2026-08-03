extends "res://tests/framework/test_case.gd"


const INITIAL_DEFENSE: Array = [
	[&"tower.rapid", &"slot.approach"],
	[&"tower.splash", &"slot.north_2"],
	[&"tower.control", &"slot.south_2"],
	[&"tower.anti_armor", &"slot.chokepoint_1"],
	[&"tower.rapid", &"slot.chokepoint_2"],
]


func test_inspection_model_exposes_factual_tower_contracts() -> void:
	var model: DefenseInspectionModel = _build_model()
	var splash: DefenseTowerInspection = model.get_tower(&"slot.north_2")

	assert_equal(model.get_map_id(), &"map.v0")
	assert_equal(model.get_logical_size(), Vector2i(8000, 4000))
	assert_equal(model.get_towers().size(), 5)
	assert_equal(model.get_segments().size(), 10)
	assert_equal(splash.get_tower_id(), &"tower.splash")
	assert_equal(splash.get_range(), 950)
	assert_equal(splash.get_targeting_kind(), TowerDefinition.TARGET_SPLASH)
	assert_true(splash.get_targeting_summary().contains("Densest"))
	assert_equal(splash.get_upgrade_id(), &"tower.splash.upgrade")
	assert_true(splash.get_upgrade_summary().contains("Splash Upgrade"))
	assert_true(splash.get_route_ids().has(&"route.north"))
	assert_false(splash.get_covered_edge_ids().is_empty())


func test_threat_bands_are_qualitative_range_overlap_with_stable_priority() -> void:
	var model: DefenseInspectionModel = _build_model()
	var priority: Array[RouteThreatInspection] = model.get_most_defended_segments(2)

	assert_equal(priority.size(), 2)
	assert_equal(priority[0].get_edge_id(), &"edge.chokepoint_core")
	assert_equal(priority[1].get_edge_id(), &"edge.merge_chokepoint")
	for segment: RouteThreatInspection in priority:
		assert_equal(segment.get_threat_level(), RouteThreatInspection.LEVEL_FORTIFIED)
		assert_equal(segment.get_coverage_count(), 2)
		assert_equal(segment.get_route_ids().size(), 2)

	var open_segment: RouteThreatInspection = model.get_segment(&"edge.spawn_approach")
	assert_equal(open_segment.get_threat_level(), RouteThreatInspection.LEVEL_GUARDED)
	assert_equal(open_segment.get_coverage_count(), 1)


func test_model_returns_copies_instead_of_mutable_internal_arrays() -> void:
	var model: DefenseInspectionModel = _build_model()
	var towers: Array[DefenseTowerInspection] = model.get_towers()
	var routes: Array[StringName] = towers[0].get_route_ids()
	towers.clear()
	routes.clear()

	assert_equal(model.get_towers().size(), 5)
	assert_false(model.get_towers()[0].get_route_ids().is_empty())


func test_map_selection_updates_tower_details_and_priority_reads() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	var map_view: DefenseMapView = main.get_defense_map_view()
	var panel: DefenseInspectionPanel = main.get_defense_inspection_panel()

	assert_equal(panel.get_selected_tower_id(), &"tower.rapid")
	assert_true(map_view.select_tower(&"slot.north_2"))
	assert_equal(map_view.get_selected_slot_id(), &"slot.north_2")
	assert_equal(panel.get_selected_tower_id(), &"tower.splash")
	assert_true(panel.get_policy_text().contains("Densest"))
	assert_true(panel.get_routes_text().contains("North"))
	assert_true(panel.get_threat_summary_text().contains("Chokepoint"))
	map_view.size = Vector2(760, 500)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map_view.get_tower_screen_position(&"slot.chokepoint_1")
	map_view._gui_input(click)
	assert_equal(panel.get_selected_tower_id(), &"tower.anti_armor")
	map_view.select_relative_tower(1)
	assert_equal(panel.get_selected_tower_id(), &"tower.rapid")
	assert_false(map_view.select_tower(&"slot.missing"))
	main.free()


func test_scene_minimum_layout_fits_supported_base_and_four_three_checks() -> void:
	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	main.compose()
	var minimum: Vector2 = main.get_combined_minimum_size()
	var map_view: DefenseMapView = main.get_defense_map_view()
	var panel: DefenseInspectionPanel = main.get_defense_inspection_panel()

	assert_true(minimum.x <= 1024.0, "minimum width must fit the 1024x768 check")
	assert_true(minimum.y <= 720.0, "minimum height must fit the 1280x720 base")
	assert_true(map_view.custom_minimum_size.x < 620.0)
	assert_true(map_view.custom_minimum_size.y >= 390.0)
	assert_true(panel.custom_minimum_size.x >= 330.0)
	assert_true(
		panel.get_node("Scroll") is ScrollContainer,
		"narrow-height layouts must retain scrollable inspection details",
	)
	main.free()


func _build_model() -> DefenseInspectionModel:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var rules: MatchRulesDefinition = catalog.rules[0]
	var deployments: Array[TowerDeployment] = []
	for values: Array in INITIAL_DEFENSE:
		deployments.append(TowerDeployment.new(values[0], values[1]))
	return DefenseInspectionBuilder.new().build(
		catalog,
		catalog.get_map(rules.map_id),
		deployments,
	)
