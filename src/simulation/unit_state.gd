class_name UnitState
extends RefCounted


var definition_id: StringName
var entity_id: int
var max_health: int
var health: int
var armor: int
var base_speed_per_tick: int
var movement_speed_per_tick: int
var leak_damage: int
var rally_range: int
var rally_numerator: int
var rally_denominator: int
var route_id: StringName:
	get:
		return _route_id
	set(value):
		assert(
			_route_id == &"" or _route_id == value,
			"a committed unit cannot change routes",
		)
		_route_id = value
var edge_index: int = 0
var distance_on_edge: int = 0
var scheduled_spawn_tick: int
var is_spawned: bool = false
var has_arrived: bool = false
var has_leaked: bool = false
var has_died: bool = false
var slow_numerator: int = 0
var slow_denominator: int = 1
var slow_remaining_ticks: int = 0
var _pending_slow_numerator: int = 0
var _pending_slow_denominator: int = 1
var _pending_slow_duration_ticks: int = 0
var _definition: UnitDefinition
var _route_id: StringName = &""


func _init(
	definition: UnitDefinition,
	runtime_entity_id: int = 0,
	assigned_route_id: StringName = &"",
	spawn_tick: int = 0,
) -> void:
	_definition = definition
	definition_id = definition.content_id
	entity_id = runtime_entity_id
	max_health = definition.max_health
	health = definition.max_health
	armor = definition.armor
	base_speed_per_tick = definition.speed_per_tick
	movement_speed_per_tick = definition.speed_per_tick
	leak_damage = definition.leak_damage
	rally_range = definition.rally_range
	rally_numerator = definition.rally_numerator
	rally_denominator = definition.rally_denominator
	route_id = assigned_route_id
	scheduled_spawn_tick = spawn_tick


func apply_damage(amount: int) -> void:
	assert(amount >= 0, "damage must be nonnegative")
	health = maxi(0, health - amount)


func spawn() -> void:
	assert(not is_spawned, "unit may only spawn once")
	assert(entity_id > 0, "spawned units require a positive entity ID")
	assert(route_id != &"", "spawned units require an assigned route")
	is_spawned = true


func set_movement_speed_for_tick(speed: int) -> void:
	assert(speed >= 0, "movement speed must be nonnegative")
	movement_speed_per_tick = maxi(1, speed) if health > 0 else 0


func reset_movement_speed() -> void:
	movement_speed_per_tick = base_speed_per_tick


func begin_tick_status_stage() -> void:
	reset_movement_speed()
	if _pending_slow_duration_ticks > 0:
		slow_numerator = _pending_slow_numerator
		slow_denominator = _pending_slow_denominator
		slow_remaining_ticks = _pending_slow_duration_ticks
		_pending_slow_duration_ticks = 0
	elif slow_remaining_ticks > 0:
		slow_remaining_ticks -= 1


func has_rally_aura() -> bool:
	return rally_range > 0 and rally_numerator > 0 and rally_denominator > 0


func apply_rally_for_tick(numerator: int, denominator: int) -> void:
	assert(numerator > 0, "rally numerator must be positive")
	assert(denominator > 0, "rally denominator must be positive")
	set_movement_speed_for_tick(IntegerMath.multiply_ratio_floor(
		movement_speed_per_tick,
		numerator,
		denominator,
	))


func apply_active_slow_for_tick() -> void:
	if slow_remaining_ticks > 0:
		set_movement_speed_for_tick(IntegerMath.multiply_ratio_floor(
			movement_speed_per_tick,
			slow_numerator,
			slow_denominator,
		))


func stage_control_slow(
	numerator: int,
	denominator: int,
	duration_ticks: int,
) -> void:
	assert(numerator > 0, "slow numerator must be positive")
	assert(denominator > 0, "slow denominator must be positive")
	assert(duration_ticks > 0, "slow duration must be positive")
	_pending_slow_numerator = numerator
	_pending_slow_denominator = denominator
	_pending_slow_duration_ticks = duration_ticks


func has_control_slow() -> bool:
	return slow_remaining_ticks > 0


func mark_arrived() -> void:
	assert(is_active(), "only an active unit may arrive")
	has_arrived = true


func mark_leaked() -> void:
	assert(has_arrived and not has_leaked, "only a newly arrived unit may leak")
	has_leaked = true


func mark_died() -> void:
	assert(health == 0 and not has_died, "only a newly defeated unit may die")
	has_died = true
	slow_remaining_ticks = 0
	_pending_slow_duration_ticks = 0
	movement_speed_per_tick = 0


func is_active() -> bool:
	return is_spawned and health > 0 and not has_arrived and not has_died


func copy() -> UnitState:
	var duplicate := UnitState.new(_definition, entity_id, route_id, scheduled_spawn_tick)
	duplicate.health = health
	duplicate.movement_speed_per_tick = movement_speed_per_tick
	duplicate.edge_index = edge_index
	duplicate.distance_on_edge = distance_on_edge
	duplicate.is_spawned = is_spawned
	duplicate.has_arrived = has_arrived
	duplicate.has_leaked = has_leaked
	duplicate.has_died = has_died
	duplicate.slow_numerator = slow_numerator
	duplicate.slow_denominator = slow_denominator
	duplicate.slow_remaining_ticks = slow_remaining_ticks
	duplicate._pending_slow_numerator = _pending_slow_numerator
	duplicate._pending_slow_denominator = _pending_slow_denominator
	duplicate._pending_slow_duration_ticks = _pending_slow_duration_ticks
	return duplicate
