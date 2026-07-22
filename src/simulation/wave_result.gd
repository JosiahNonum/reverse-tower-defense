class_name WaveResult
extends RefCounted


var round_index: int
var ending_tick: int
var events_emitted: int
var event_digest: String


func _init(
	result_round_index: int,
	result_ending_tick: int,
	result_events_emitted: int,
	result_event_digest: String,
) -> void:
	round_index = result_round_index
	ending_tick = result_ending_tick
	events_emitted = result_events_emitted
	event_digest = result_event_digest


func to_dictionary() -> Dictionary:
	return {
		"round_index": round_index,
		"ending_tick": ending_tick,
		"events_emitted": events_emitted,
		"event_digest": event_digest,
	}


func to_json() -> String:
	return JSON.stringify(to_dictionary())
