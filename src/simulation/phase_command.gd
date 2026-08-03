class_name PhaseCommand
extends RefCounted


const COMPLETE_INITIAL_DEFENSE: StringName = &"complete_initial_defense"
const BEGIN_WAVE_AUTHORING: StringName = &"begin_wave_authoring"
const COMMIT_WAVE: StringName = &"commit_wave"
const BEGIN_RESOLUTION: StringName = &"begin_resolution"
const COMPLETE_RESOLUTION: StringName = &"complete_resolution"
const BEGIN_ANALYSIS: StringName = &"begin_analysis"
const BEGIN_NEXT_ROUND: StringName = &"begin_next_round"
const END_MATCH: StringName = &"end_match"

const ACTOR_SYSTEM: StringName = &"system"
const ACTOR_PLAYER: StringName = &"player"
const ACTOR_DEFENDER: StringName = &"defender"

var command_type: StringName
var actor: StringName
var command_id: int
var expected_phase: StringName


func _init(
	requested_id: int,
	requested_type: StringName,
	requested_phase: StringName,
	requested_actor: StringName,
) -> void:
	command_id = requested_id
	command_type = requested_type
	expected_phase = requested_phase
	actor = requested_actor


func copy() -> PhaseCommand:
	return PhaseCommand.new(command_id, command_type, expected_phase, actor)


func to_dictionary() -> Dictionary:
	return {
		"command_id": command_id,
		"command_type": String(command_type),
		"expected_phase": String(expected_phase),
		"actor": String(actor),
	}
