class_name TowerState
extends RefCounted


var entity_id: int
var definition_id: StringName
var slot_id: StringName
var logical_x: int
var logical_y: int
var range: int
var damage: int
var cooldown_ticks: int
var cooldown_remaining: int = 0
var targeting_kind: StringName
var splash_radius: int
var ignores_armor: bool
var slow_numerator: int
var slow_denominator: int
var slow_duration_ticks: int
var next_attack_ordinal: int = 0
var _definition: TowerDefinition


func _init(
	definition: TowerDefinition,
	runtime_entity_id: int,
	deployment_slot_id: StringName,
	x: int,
	y: int,
) -> void:
	_definition = definition
	entity_id = runtime_entity_id
	definition_id = definition.content_id
	slot_id = deployment_slot_id
	logical_x = x
	logical_y = y
	range = definition.range
	damage = definition.damage
	cooldown_ticks = definition.cooldown_ticks
	targeting_kind = definition.targeting_kind
	splash_radius = definition.splash_radius
	ignores_armor = definition.ignores_armor
	slow_numerator = definition.slow_numerator
	slow_denominator = definition.slow_denominator
	slow_duration_ticks = definition.slow_duration_ticks


func begin_tick() -> void:
	if cooldown_remaining > 0:
		cooldown_remaining -= 1


func is_ready() -> bool:
	return cooldown_remaining == 0


func record_attack() -> int:
	assert(is_ready(), "only a ready tower may attack")
	var attack_ordinal: int = next_attack_ordinal
	next_attack_ordinal += 1
	cooldown_remaining = cooldown_ticks
	return attack_ordinal


func copy() -> TowerState:
	var duplicate := TowerState.new(
		_definition,
		entity_id,
		slot_id,
		logical_x,
		logical_y,
	)
	duplicate.cooldown_remaining = cooldown_remaining
	duplicate.next_attack_ordinal = next_attack_ordinal
	return duplicate
