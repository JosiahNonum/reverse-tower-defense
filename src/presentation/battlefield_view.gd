class_name BattlefieldView
extends Control

const MAP_PADDING: float = 42.0
const DEFAULT_LOGICAL_SIZE := Vector2(8000.0, 4000.0)
const EntityVisualScript = preload("res://src/presentation/battlefield_entity_visual.gd")

var _entity_nodes: Dictionary[int, Node2D] = {}
var _last_tick: int = -1
var _consumed_event_count: int = 0
var _logical_size: Vector2 = DEFAULT_LOGICAL_SIZE
var _attack_lines: Array[Dictionary] = []
var _projectiles: Array[Dictionary] = []
var _last_positions_by_id: Dictionary[int, Vector2] = {}
var _attack_event_count: int = 0


func configure(logical_width: int, logical_height: int) -> void:
	_logical_size = Vector2(logical_width, logical_height)
	queue_redraw()

func reconcile(view: MatchView, events: Array[DomainEvent]) -> void:
	var desired_ids: Dictionary[int, bool] = {}
	var positions_by_id: Dictionary[int, Vector2] = {}
	if view.get_phase() != MatchPhase.WAVE_COMMITTED \
		and view.get_phase() != MatchPhase.RESOLVING \
		and view.get_phase() != MatchPhase.ANALYSIS:
		_projectiles.clear()
	for entity: EntityView in view.get_entities():
		var entity_id: int = entity.get_entity_id()
		desired_ids[entity_id] = true
		positions_by_id[entity_id] = _logical_to_screen(Vector2i(entity.get_logical_x(), entity.get_logical_y()))
		var visual: Node2D = _entity_nodes.get(entity_id)
		if visual == null:
			visual = _create_placeholder(entity)
			_entity_nodes[entity_id] = visual
		visual.position = positions_by_id[entity_id]
		if visual is BattlefieldEntityVisual:
			var entity_visual := visual as BattlefieldEntityVisual
			entity_visual.set_attack_flash(false)
			entity_visual.set_health(entity.get_health(), entity.get_max_health())

	_attack_lines.clear()
	for event: DomainEvent in events:
		if event.event_type != &"tower_attacked":
			continue
		_attack_event_count += 1
		var source_id: int = int(event.data.get("tower_entity_id", 0))
		var target_ids: Array = event.data.get("victim_ids", [])
		var source_position: Vector2 = positions_by_id.get(source_id, Vector2.ZERO)
		var source_visual: Node2D = _entity_nodes.get(source_id)
		if source_visual is BattlefieldEntityVisual:
			(source_visual as BattlefieldEntityVisual).set_attack_flash(true)
		for target_id_value: Variant in target_ids:
			var target_id: int = int(target_id_value)
			var target_position: Vector2 = positions_by_id.get(
				target_id,
				_last_positions_by_id.get(target_id, source_position),
			)
			if target_id == int(event.data.get("primary_target_id", -1)):
				if not positions_by_id.has(target_id) and event.data.has("target_logical_x"):
					target_position = _logical_to_screen(Vector2i(
						int(event.data["target_logical_x"]),
						int(event.data["target_logical_y"]),
					))
			_attack_lines.append({"from": source_position, "to": target_position})
			_projectiles.append({"from": source_position, "to": target_position, "progress": 0.0})

	var existing_ids: Array[int] = []
	existing_ids.assign(_entity_nodes.keys())
	existing_ids.sort()
	for entity_id: int in existing_ids:
		if desired_ids.has(entity_id):
			continue
		var visual: Node2D = _entity_nodes[entity_id]
		_entity_nodes.erase(entity_id)
		visual.free()

	_last_tick = view.get_tick()
	_consumed_event_count += events.size()
	_last_positions_by_id = positions_by_id.duplicate()
	queue_redraw()


func _process(delta: float) -> void:
	if _projectiles.is_empty():
		return
	for index in range(_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = _projectiles[index]
		projectile["progress"] = minf(1.0, float(projectile["progress"]) + delta * 7.0)
		if float(projectile["progress"]) >= 1.0:
			_projectiles.remove_at(index)
	queue_redraw()

func get_visual_count() -> int:
	return _entity_nodes.size()

func has_visual(entity_id: int) -> bool:
	return _entity_nodes.has(entity_id)

func get_visual_kind(entity_id: int) -> StringName:
	assert(_entity_nodes.has(entity_id), "No visual exists for entity %d" % entity_id)
	return StringName(_entity_nodes[entity_id].get_meta(&"entity_kind"))

func get_attack_feedback_count() -> int:
	return _attack_lines.size()

func get_attack_event_count() -> int:
	return _attack_event_count

func get_projectile_count() -> int:
	return _projectiles.size()

func get_visual_position(entity_id: int) -> Vector2:
	assert(_entity_nodes.has(entity_id), "No visual exists for entity %d" % entity_id)
	return _entity_nodes[entity_id].position

func get_last_tick() -> int:
	return _last_tick

func get_consumed_event_count() -> int:
	return _consumed_event_count

func _create_placeholder(entity: EntityView) -> Node2D:
	var visual: BattlefieldEntityVisual = EntityVisualScript.new()
	visual.name = "Entity_%d" % entity.get_entity_id()
	visual.set_meta(&"entity_id", entity.get_entity_id())
	visual.set_meta(&"entity_kind", entity.get_kind())
	visual.configure(entity.get_entity_id(), entity.get_kind())
	add_child(visual)
	return visual


func _draw() -> void:
	for line: Dictionary in _attack_lines:
		draw_line(line["from"], line["to"], Color(0.96, 0.97, 1.0, 0.82), 2.0, true)
		draw_circle(line["to"], 10.0, Color(0.96, 0.97, 1.0, 0.28))
	for projectile: Dictionary in _projectiles:
		var from_position: Vector2 = projectile["from"]
		var to_position: Vector2 = projectile["to"]
		var progress: float = projectile["progress"]
		var current_position: Vector2 = from_position.lerp(to_position, progress)
		draw_line(from_position, current_position, Color(0.96, 0.97, 1.0, 0.42), 2.0, true)
		draw_circle(current_position, 4.0, Color("f4f7ff"))


func _logical_to_screen(logical_position: Vector2i) -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(logical_position) * 0.1
	var scale: float = _map_scale()
	var scaled_size: Vector2 = _logical_size * scale
	var frame_position: Vector2 = (size - scaled_size) * 0.5
	return frame_position + Vector2(logical_position) * scale


func _map_scale() -> float:
	var available: Vector2 = Vector2(
		maxf(1.0, size.x - MAP_PADDING * 2.0),
		maxf(1.0, size.y - MAP_PADDING * 2.0),
	)
	return minf(available.x / _logical_size.x, available.y / _logical_size.y)
