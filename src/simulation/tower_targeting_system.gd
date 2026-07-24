class_name TowerTargetingSystem
extends RefCounted


var _movement: LaneMovementSystem


func _init(movement: LaneMovementSystem) -> void:
	_movement = movement


func select_target(tower: TowerState, units: Array[UnitState]) -> UnitState:
	var candidates: Array[UnitState] = []
	for unit: UnitState in units:
		if unit.is_active() and _is_in_tower_range(tower, unit):
			candidates.append(unit)
	if candidates.is_empty():
		return null
	var splash_counts: Dictionary[int, int] = {}
	if tower.targeting_kind == TowerDefinition.TARGET_SPLASH:
		for candidate: UnitState in candidates:
			splash_counts[candidate.entity_id] = _count_splash_victims(
				tower,
				candidate,
				units,
			)
	candidates.sort_custom(func(left: UnitState, right: UnitState) -> bool:
		return _target_before(tower, left, right, splash_counts)
	)
	return candidates[0]


func splash_victims(
	tower: TowerState,
	primary: UnitState,
	units: Array[UnitState],
) -> Array[UnitState]:
	var victims: Array[UnitState] = []
	var primary_position: Vector2i = _movement.logical_position(primary)
	for unit: UnitState in units:
		if not unit.is_active():
			continue
		var position: Vector2i = _movement.logical_position(unit)
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
	var left_remaining: int = _movement.remaining_route_distance(left)
	var right_remaining: int = _movement.remaining_route_distance(right)
	if left_remaining != right_remaining:
		return left_remaining < right_remaining
	return left.entity_id < right.entity_id


func _count_splash_victims(
	tower: TowerState,
	primary: UnitState,
	units: Array[UnitState],
) -> int:
	var count: int = 0
	var primary_position: Vector2i = _movement.logical_position(primary)
	for unit: UnitState in units:
		if not unit.is_active():
			continue
		var position: Vector2i = _movement.logical_position(unit)
		var distance_squared: int = IntegerMath.squared_distance(
			primary_position.x,
			primary_position.y,
			position.x,
			position.y,
		)
		if IntegerMath.is_inside_inclusive_range(distance_squared, tower.splash_radius):
			count += 1
	return count


func _is_in_tower_range(tower: TowerState, unit: UnitState) -> bool:
	var position: Vector2i = _movement.logical_position(unit)
	var distance_squared: int = IntegerMath.squared_distance(
		tower.logical_x,
		tower.logical_y,
		position.x,
		position.y,
	)
	return IntegerMath.is_inside_inclusive_range(distance_squared, tower.range)
