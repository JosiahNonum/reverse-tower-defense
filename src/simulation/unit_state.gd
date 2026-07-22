class_name UnitState
extends RefCounted


var definition_id: StringName
var health: int
var armor: int
var speed_per_tick: int


func _init(definition: UnitDefinition) -> void:
	definition_id = definition.content_id
	health = definition.max_health
	armor = definition.armor
	speed_per_tick = definition.speed_per_tick


func apply_damage(amount: int) -> void:
	assert(amount >= 0, "damage must be nonnegative")
	health = maxi(0, health - amount)
