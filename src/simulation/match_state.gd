class_name MatchState
extends RefCounted


const EVENT_PHASE_CHANGED: StringName = &"phase_changed"
const EVENT_TICK_ADVANCED: StringName = &"tick_advanced"

var _root_seed: int
var _phase: StringName = MatchPhase.INITIAL_DEFENSE
var _tick: int = 0

var _next_event_ordinal: int = 0
var _next_entity_id: int = 1
var _events: Array[DomainEvent] = []
var _accepted_command_ids: Dictionary[int, bool] = {}


func _init(match_seed: int) -> void:
	_root_seed = match_seed


func apply_phase_command(command: PhaseCommand) -> CommandResult:
	if command.command_id <= 0:
		return CommandResult.reject(
			CommandResult.CODE_INVALID_COMMAND_ID,
			"Command IDs must be positive",
		)
	if _accepted_command_ids.has(command.command_id):
		return CommandResult.reject(
			CommandResult.CODE_DUPLICATE_COMMAND,
			"Command ID %d was already accepted" % command.command_id,
		)
	if command.expected_phase != _phase:
		return CommandResult.reject(
			CommandResult.CODE_EXPECTED_PHASE_MISMATCH,
			"Command expected phase %s, current phase is %s" % [
				command.expected_phase,
				_phase,
			],
		)

	var required_phase: StringName = _required_phase(command.command_type)
	if required_phase == &"":
		return CommandResult.reject(
			CommandResult.CODE_UNKNOWN_COMMAND,
			"Unknown phase command: %s" % command.command_type,
		)
	if _phase != required_phase:
		return CommandResult.reject(
			CommandResult.CODE_WRONG_PHASE,
			"Command %s requires phase %s, current phase is %s" % [
				command.command_type,
				required_phase,
				_phase,
			],
		)

	var required_actor: StringName = _required_actor(command.command_type)
	if command.actor != required_actor:
		return CommandResult.reject(
			CommandResult.CODE_FORBIDDEN_ACTOR,
			"Command %s requires actor %s" % [command.command_type, required_actor],
		)

	var previous_phase: StringName = _phase
	_phase = _destination_phase(command.command_type)
	_accepted_command_ids[command.command_id] = true
	_emit_event(EVENT_PHASE_CHANGED, {
		"from": String(previous_phase),
		"to": String(_phase),
		"command": String(command.command_type),
		"command_id": command.command_id,
	})
	return CommandResult.accept()


func advance_one_tick() -> void:
	_tick += 1
	_next_event_ordinal = 0
	_emit_event(EVENT_TICK_ADVANCED, {"tick": _tick})


func allocate_entity_id() -> int:
	var allocated_id: int = _next_entity_id
	_next_entity_id += 1
	return allocated_id


func get_root_seed() -> int:
	return _root_seed


func get_phase() -> StringName:
	return _phase


func get_tick() -> int:
	return _tick


func get_events() -> Array[DomainEvent]:
	var copy: Array[DomainEvent] = []
	for event: DomainEvent in _events:
		copy.append(event.copy())
	return copy


func create_view() -> MatchView:
	return MatchView.new(_phase, _tick, _next_entity_id - 1)


func create_wave_result(round_index: int) -> WaveResult:
	return WaveResult.new(round_index, _tick, _events.size(), event_digest())


func create_match_result(outcome: StringName, completed_rounds: int) -> MatchResult:
	return MatchResult.new(outcome, completed_rounds, _tick, event_digest())


func event_digest() -> String:
	var serialized_events: PackedStringArray = []
	for event: DomainEvent in _events:
		serialized_events.append(JSON.stringify(event.to_dictionary()))
	return "\n".join(serialized_events).sha256_text()


func _emit_event(event_type: StringName, event_data: Dictionary) -> void:
	_events.append(DomainEvent.new(_tick, _next_event_ordinal, event_type, event_data))
	_next_event_ordinal += 1


func _required_phase(command_type: StringName) -> StringName:
	match command_type:
		PhaseCommand.COMPLETE_INITIAL_DEFENSE:
			return MatchPhase.INITIAL_DEFENSE
		PhaseCommand.BEGIN_WAVE_AUTHORING:
			return MatchPhase.DEFENSE_REVEAL
		_:
			return &""


func _required_actor(command_type: StringName) -> StringName:
	match command_type:
		PhaseCommand.COMPLETE_INITIAL_DEFENSE:
			return PhaseCommand.ACTOR_SYSTEM
		PhaseCommand.BEGIN_WAVE_AUTHORING:
			return PhaseCommand.ACTOR_PLAYER
		_:
			return &""


func _destination_phase(command_type: StringName) -> StringName:
	match command_type:
		PhaseCommand.COMPLETE_INITIAL_DEFENSE:
			return MatchPhase.DEFENSE_REVEAL
		PhaseCommand.BEGIN_WAVE_AUTHORING:
			return MatchPhase.WAVE_AUTHORING
		_:
			return _phase
