class_name AttackIntent
extends RefCounted


var source_tower_id: int
var attack_ordinal: int
var target_unit_id: int
var raw_damage: int
var ignores_armor: bool
var slow_numerator: int
var slow_denominator: int
var slow_duration_ticks: int


func _init(
	source_id: int,
	source_attack_ordinal: int,
	target_id: int,
	intent_raw_damage: int,
	intent_ignores_armor: bool,
	intent_slow_numerator: int = 0,
	intent_slow_denominator: int = 1,
	intent_slow_duration_ticks: int = 0,
) -> void:
	source_tower_id = source_id
	attack_ordinal = source_attack_ordinal
	target_unit_id = target_id
	raw_damage = intent_raw_damage
	ignores_armor = intent_ignores_armor
	slow_numerator = intent_slow_numerator
	slow_denominator = intent_slow_denominator
	slow_duration_ticks = intent_slow_duration_ticks
