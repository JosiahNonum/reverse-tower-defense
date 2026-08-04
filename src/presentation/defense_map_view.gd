class_name DefenseMapView
extends Control


signal tower_selected(slot_id: StringName)

const MAP_PADDING: float = 42.0
const TOWER_HIT_RADIUS: float = 22.0
const COLOR_OPEN := Color("3d5267")
const COLOR_GUARDED := Color("e7a84b")
const COLOR_FORTIFIED := Color("ef5b5b")
const COLOR_ROUTE := Color("223247")
const COLOR_TOWER := Color("72e0b8")
const COLOR_SELECTED := Color("f4f7ff")

var _model: DefenseInspectionModel
var _selected_slot_id: StringName


func configure(model: DefenseInspectionModel) -> void:
	_model = model
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var towers: Array[DefenseTowerInspection] = _model.get_towers()
	if not towers.is_empty():
		_selected_slot_id = towers[0].get_slot_id()
	queue_redraw()


func select_tower(slot_id: StringName) -> bool:
	if _model == null or _model.get_tower(slot_id) == null:
		return false
	_selected_slot_id = slot_id
	queue_redraw()
	tower_selected.emit(slot_id)
	return true


func get_selected_slot_id() -> StringName:
	return _selected_slot_id


func get_tower_screen_position(slot_id: StringName) -> Vector2:
	assert(_model != null, "map view must be configured")
	var tower: DefenseTowerInspection = _model.get_tower(slot_id)
	assert(tower != null, "requested tower slot must exist")
	return _logical_to_screen(tower.get_logical_position())


func _draw() -> void:
	if _model == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1624"), true)
	_draw_map_frame()
	_draw_segments()
	_draw_towers()
	_draw_route_labels()


func _gui_input(event: InputEvent) -> void:
	if _model == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var slot_id: StringName = _tower_at(mouse_event.position)
			if slot_id != &"":
				if is_inside_tree():
					grab_focus()
				select_tower(slot_id)
				accept_event()
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.is_action_pressed("ui_left"):
			select_relative_tower(-1)
			accept_event()
		elif key_event.is_action_pressed("ui_right"):
			select_relative_tower(1)
			accept_event()


func _draw_map_frame() -> void:
	var frame: Rect2 = _map_rect()
	draw_rect(frame.grow(10.0), Color("172336"), true)
	draw_rect(frame.grow(10.0), Color("31445d"), false, 2.0)


func _draw_segments() -> void:
	var selected: DefenseTowerInspection = _model.get_tower(_selected_slot_id)
	var selected_edges: Array[StringName] = []
	if selected != null:
		selected_edges = selected.get_covered_edge_ids()
	for segment: RouteThreatInspection in _model.get_segments():
		var start: Vector2 = _logical_to_screen(segment.get_from_position())
		var finish: Vector2 = _logical_to_screen(segment.get_to_position())
		draw_line(start, finish, COLOR_ROUTE, 13.0, true)
		var color: Color = _color_for_level(segment.get_threat_level())
		var width: float = 7.0
		if selected_edges.has(segment.get_edge_id()):
			draw_line(start, finish, COLOR_SELECTED, 12.0, true)
			width = 8.0
		draw_line(start, finish, color, width, true)
		var midpoint: Vector2 = start.lerp(finish, 0.5)
		draw_circle(midpoint, 10.0, color)
		draw_string(
			get_theme_default_font(),
			midpoint + Vector2(-3.5, 4.0),
			str(segment.get_coverage_count()),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			Color("0b1018"),
		)


func _draw_towers() -> void:
	for tower: DefenseTowerInspection in _model.get_towers():
		var position: Vector2 = _logical_to_screen(tower.get_logical_position())
		var is_selected: bool = tower.get_slot_id() == _selected_slot_id
		if is_selected:
			var range_radius: float = (
				float(tower.get_range())
				* _map_scale()
			)
			draw_circle(position, range_radius, Color(0.45, 0.88, 0.72, 0.12))
			draw_arc(
				position,
				range_radius,
				0.0,
				TAU,
				64,
				Color(0.55, 0.96, 0.78, 0.78),
				2.0,
				true,
			)
			draw_circle(position, 16.0, COLOR_SELECTED)
		draw_circle(position, 12.0, COLOR_TOWER)
		draw_circle(position, 12.0, Color("143426"), false, 2.0)
		var initial: String = tower.get_tower_name().substr(0, 1)
		draw_string(
			get_theme_default_font(),
			position + Vector2(-4.5, 4.5),
			initial,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			13,
			Color("0a1511"),
		)


func _draw_route_labels() -> void:
	var frame: Rect2 = _map_rect()
	draw_string(
		get_theme_default_font(),
		Vector2(frame.position.x + frame.size.x * 0.43, frame.position.y - 12.0),
		"NORTH ROUTE",
		HORIZONTAL_ALIGNMENT_CENTER,
		140.0,
		13,
		Color("9eb3cc"),
	)
	draw_string(
		get_theme_default_font(),
		Vector2(frame.position.x + frame.size.x * 0.43, frame.end.y + 24.0),
		"SOUTH ROUTE",
		HORIZONTAL_ALIGNMENT_CENTER,
		140.0,
		13,
		Color("9eb3cc"),
	)


func _tower_at(screen_position: Vector2) -> StringName:
	var best_slot: StringName = &""
	var best_distance: float = TOWER_HIT_RADIUS * TOWER_HIT_RADIUS
	for tower: DefenseTowerInspection in _model.get_towers():
		var tower_position: Vector2 = _logical_to_screen(tower.get_logical_position())
		var distance: float = screen_position.distance_squared_to(tower_position)
		if distance <= best_distance:
			best_distance = distance
			best_slot = tower.get_slot_id()
	return best_slot


func select_relative_tower(offset: int) -> void:
	var towers: Array[DefenseTowerInspection] = _model.get_towers()
	if towers.is_empty():
		return
	var current_index: int = 0
	for index: int in towers.size():
		if towers[index].get_slot_id() == _selected_slot_id:
			current_index = index
			break
	var next_index: int = posmod(current_index + offset, towers.size())
	select_tower(towers[next_index].get_slot_id())


func _logical_to_screen(logical_position: Vector2i) -> Vector2:
	var frame: Rect2 = _map_rect()
	var scale: float = _map_scale()
	return frame.position + Vector2(logical_position) * scale


func _map_rect() -> Rect2:
	var logical_size: Vector2 = Vector2(_model.get_logical_size())
	var scale: float = _map_scale()
	var scaled_size: Vector2 = logical_size * scale
	return Rect2((size - scaled_size) * 0.5, scaled_size)


func _map_scale() -> float:
	var logical_size: Vector2 = Vector2(_model.get_logical_size())
	var available: Vector2 = Vector2(
		maxf(1.0, size.x - MAP_PADDING * 2.0),
		maxf(1.0, size.y - MAP_PADDING * 2.0),
	)
	return minf(available.x / logical_size.x, available.y / logical_size.y)


func _color_for_level(level: StringName) -> Color:
	match level:
		RouteThreatInspection.LEVEL_FORTIFIED:
			return COLOR_FORTIFIED
		RouteThreatInspection.LEVEL_GUARDED:
			return COLOR_GUARDED
		_:
			return COLOR_OPEN
