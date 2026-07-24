class_name TowerTargetingSystem
extends RefCounted


var _movement: LaneMovementSystem


func _init(movement: LaneMovementSystem) -> void:
	_movement = movement


func create_frame(units: Array[UnitState]) -> TowerTargetingFrame:
	var frame := TowerTargetingFrame.new()
	for unit: UnitState in units:
		if not unit.is_active():
			continue
		frame.add(
			unit,
			_movement.logical_position(unit),
			_movement.remaining_route_distance(unit),
		)
	return frame


func select_target(
	tower: TowerState,
	units: Array[UnitState],
	frame: TowerTargetingFrame = null,
) -> UnitState:
	var targeting_frame: TowerTargetingFrame = (
		frame if frame != null else create_frame(units)
	)
	var candidates: Array[UnitState] = []
	var remaining_distances: Dictionary[int, int] = {}
	for unit: UnitState in targeting_frame.active_units:
		if _is_in_tower_range(tower, unit, targeting_frame):
			candidates.append(unit)
			remaining_distances[unit.entity_id] = (
				targeting_frame.remaining_route_distances[unit.entity_id]
			)
	if candidates.is_empty():
		return null
	var splash_counts: Dictionary[int, int] = {}
	if tower.targeting_kind == TowerDefinition.TARGET_SPLASH:
		for candidate: UnitState in candidates:
			splash_counts[candidate.entity_id] = _count_splash_victims(
				tower,
				candidate,
				targeting_frame,
			)
	var selected: UnitState = candidates[0]
	for candidate_index: int in range(1, candidates.size()):
		var candidate: UnitState = candidates[candidate_index]
		if _target_before(
			tower,
			candidate,
			selected,
			splash_counts,
			remaining_distances,
		):
			selected = candidate
	return selected


func splash_victims(
	tower: TowerState,
	primary: UnitState,
	units: Array[UnitState],
	frame: TowerTargetingFrame = null,
) -> Array[UnitState]:
	var targeting_frame: TowerTargetingFrame = (
		frame if frame != null else create_frame(units)
	)
	var victims: Array[UnitState] = []
	var primary_position: Vector2i = targeting_frame.positions[primary.entity_id]
	for unit: UnitState in targeting_frame.active_units:
		var position: Vector2i = targeting_frame.positions[unit.entity_id]
		var distance_squared: int = IntegerMath.squared_distance(
			primary_position.x,
			primary_position.y,
			position.x,
			position.y,
		)
		if IntegerMath.is_inside_inclusive_range(distance_squared, tower.splash_radius):
			victims.append(unit)
	victims.sort_custom(func(left: UnitState, right: UnitState) -> bool:
		return left.entity_id < right.entity_id
	)
	return victims


func _target_before(
	tower: TowerState,
	left: UnitState,
	right: UnitState,
	splash_counts: Dictionary[int, int],
	remaining_distances: Dictionary[int, int],
) -> bool:
	match tower.targeting_kind:
		TowerDefinition.TARGET_SPLASH:
			var left_count: int = splash_counts[left.entity_id]
			var right_count: int = splash_counts[right.entity_id]
			if left_count != right_count:
				return left_count > right_count
		TowerDefinition.TARGET_CONTROL:
			if left.has_control_slow() != right.has_control_slow():
				return not left.has_control_slow()
			if left.movement_speed_per_tick != right.movement_speed_per_tick:
				return left.movement_speed_per_tick > right.movement_speed_per_tick
		TowerDefinition.TARGET_ANTI_ARMOR:
			if left.armor != right.armor:
				return left.armor > right.armor
			if left.max_health != right.max_health:
				return left.max_health > right.max_health
	var left_remaining: int = remaining_distances[left.entity_id]
	var right_remaining: int = remaining_distances[right.entity_id]
	if left_remaining != right_remaining:
		return left_remaining < right_remaining
	return left.entity_id < right.entity_id


func _count_splash_victims(
	tower: TowerState,
	primary: UnitState,
	frame: TowerTargetingFrame,
) -> int:
	var count: int = 0
	var primary_position: Vector2i = frame.positions[primary.entity_id]
	for unit: UnitState in frame.active_units:
		var position: Vector2i = frame.positions[unit.entity_id]
		var distance_squared: int = IntegerMath.squared_distance(
			primary_position.x,
			primary_position.y,
			position.x,
			position.y,
		)
		if IntegerMath.is_inside_inclusive_range(distance_squared, tower.splash_radius):
			count += 1
	return count


func _is_in_tower_range(
	tower: TowerState,
	unit: UnitState,
	frame: TowerTargetingFrame,
) -> bool:
	var position: Vector2i = frame.positions[unit.entity_id]
	var distance_squared: int = IntegerMath.squared_distance(
		tower.logical_x,
		tower.logical_y,
		position.x,
		position.y,
	)
	return IntegerMath.is_inside_inclusive_range(distance_squared, tower.range)
