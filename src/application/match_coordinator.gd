class_name MatchCoordinator
extends Node

signal view_published(view: MatchView, events: Array[DomainEvent])

var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _state: MatchState
var _published_event_count: int = 0

func initialize(catalog: ContentCatalog, rules: MatchRulesDefinition, root_seed: int) -> void:
	assert(_state == null, "MatchCoordinator may only be initialized once")
	var validation: ContentValidationResult = catalog.validate()
	assert(validation.is_valid(), "Match content must validate before composition")
	_catalog = catalog
	_rules = rules
	_state = MatchState.new(root_seed)
	publish_current_view()

func is_initialized() -> bool:
	return _state != null

func apply_phase_command(command: PhaseCommand) -> CommandResult:
	_assert_initialized()
	var result: CommandResult = _state.apply_phase_command(command)
	if result.is_accepted:
		publish_current_view()
	return result

func advance_one_tick() -> void:
	_assert_initialized()
	_state.advance_one_tick()
	publish_current_view()

func get_current_view() -> MatchView:
	_assert_initialized()
	return _state.create_view()

func get_rules_id() -> StringName:
	_assert_initialized()
	return _rules.content_id

func get_content_fingerprint() -> String:
	_assert_initialized()
	return _catalog.content_fingerprint()

func publish_current_view() -> void:
	_assert_initialized()
	var all_events: Array[DomainEvent] = _state.get_events()
	var new_events: Array[DomainEvent] = []
	for index: int in range(_published_event_count, all_events.size()):
		new_events.append(all_events[index])
	_published_event_count = all_events.size()
	view_published.emit(_state.create_view(), new_events)

func _assert_initialized() -> void:
	assert(_state != null, "MatchCoordinator must be initialized by the composition root")
