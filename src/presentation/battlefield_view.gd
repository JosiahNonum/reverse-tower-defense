class_name BattlefieldView
extends Node2D

const LOGICAL_TO_SCREEN_SCALE: float = 0.1

var _entity_nodes: Dictionary[int, Node2D] = {}
var _last_tick: int = -1
var _consumed_event_count: int = 0

func reconcile(view: MatchView, events: Array[DomainEvent]) -> void:
	var desired_ids: Dictionary[int, bool] = {}
	for entity: EntityView in view.get_entities():
		var entity_id: int = entity.get_entity_id()
		desired_ids[entity_id] = true
		var visual: Node2D = _entity_nodes.get(entity_id)
		if visual == null:
			visual = _create_placeholder(entity)
			_entity_nodes[entity_id] = visual
		visual.position = Vector2(entity.get_logical_x(), entity.get_logical_y()) * LOGICAL_TO_SCREEN_SCALE

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

func get_visual_count() -> int:
	return _entity_nodes.size()

func has_visual(entity_id: int) -> bool:
	return _entity_nodes.has(entity_id)

func get_visual_position(entity_id: int) -> Vector2:
	assert(_entity_nodes.has(entity_id), "No visual exists for entity %d" % entity_id)
	return _entity_nodes[entity_id].position

func get_last_tick() -> int:
	return _last_tick

func get_consumed_event_count() -> int:
	return _consumed_event_count

func _create_placeholder(entity: EntityView) -> Node2D:
	var visual := Node2D.new()
	visual.name = "Entity_%d" % entity.get_entity_id()
	visual.set_meta(&"entity_id", entity.get_entity_id())
	visual.set_meta(&"entity_kind", entity.get_kind())
	add_child(visual)
	return visual
