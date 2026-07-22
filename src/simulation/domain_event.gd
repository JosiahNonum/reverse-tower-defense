class_name DomainEvent
extends RefCounted


var tick: int
var ordinal: int
var event_type: StringName
var data: Dictionary


func _init(
	event_tick: int,
	event_ordinal: int,
	type: StringName,
	event_data: Dictionary = {},
) -> void:
	tick = event_tick
	ordinal = event_ordinal
	event_type = type
	data = event_data.duplicate(true)


func copy() -> DomainEvent:
	return DomainEvent.new(tick, ordinal, event_type, data)


func to_dictionary() -> Dictionary:
	return {
		"tick": tick,
		"ordinal": ordinal,
		"event_type": String(event_type),
		"data": data.duplicate(true),
	}
