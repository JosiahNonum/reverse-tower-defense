class_name MatchResult
extends RefCounted


var outcome: StringName
var completed_rounds: int
var ending_tick: int
var event_digest: String


func _init(
	result_outcome: StringName,
	result_completed_rounds: int,
	result_ending_tick: int,
	result_event_digest: String,
) -> void:
	outcome = result_outcome
	completed_rounds = result_completed_rounds
	ending_tick = result_ending_tick
	event_digest = result_event_digest


func to_dictionary() -> Dictionary:
	return {
		"outcome": String(outcome),
		"completed_rounds": completed_rounds,
		"ending_tick": ending_tick,
		"event_digest": event_digest,
	}


func to_json() -> String:
	return JSON.stringify(to_dictionary())
