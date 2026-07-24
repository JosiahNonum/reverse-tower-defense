class_name DiagnosticReplaySummary
extends RefCounted


var phase: StringName
var tick: int
var event_count: int
var event_digest: String


func _init(
	summary_phase: StringName,
	summary_tick: int,
	summary_event_count: int,
	summary_event_digest: String,
) -> void:
	phase = summary_phase
	tick = summary_tick
	event_count = summary_event_count
	event_digest = summary_event_digest


static func from_state(state: MatchState) -> DiagnosticReplaySummary:
	return DiagnosticReplaySummary.new(
		state.get_phase(),
		state.get_tick(),
		state.get_events().size(),
		state.event_digest(),
	)


func copy() -> DiagnosticReplaySummary:
	return DiagnosticReplaySummary.new(phase, tick, event_count, event_digest)


func to_dictionary() -> Dictionary:
	return {
		"phase": String(phase),
		"tick": tick,
		"event_count": event_count,
		"event_digest": event_digest,
	}
