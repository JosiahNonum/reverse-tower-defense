class_name MatchCoordinator
extends Node

const PostWaveAnalysisScript = preload("res://src/application/post_wave_analysis.gd")
const ObservationHistoryScript = preload("res://src/defender_ai/observation_history.gd")
const ObservationProjectorScript = preload("res://src/defender_ai/observation_projector.gd")
const DefenderPlannerScript = preload("res://src/defender_ai/defender_planner.gd")
const DefenseCommandGatewayScript = preload("res://src/simulation/defense_command_gateway.gd")
const DefenderVariationScript = preload("res://src/defender_ai/defender_variation.gd")
signal view_published(view: MatchView, events: Array[DomainEvent])

var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _state: MatchState
var _published_event_count: int = 0
var _tower_deployments: Array[TowerDeployment] = []
var _active_simulation: FixedDefenseSimulation
var _core_integrity: int = -1
var _root_seed: int = 0
var _observation_history
var _decision_traces: Array = []
var _defender_profile: DefenderProfileDefinition
var _defender_budget: int = 0
var _next_decision_id: int = 1
var _adaptive_defender_enabled: bool = true
var _defender_variation

func initialize(catalog: ContentCatalog, rules: MatchRulesDefinition, root_seed: int) -> void:
	assert(_state == null, "MatchCoordinator may only be initialized once")
	var validation: ContentValidationResult = catalog.validate()
	assert(validation.is_valid(), "Match content must validate before composition")
	_catalog = catalog
	_rules = rules
	_root_seed = root_seed
	_core_integrity = rules.core_health
	_state = MatchState.new(root_seed)
	_observation_history = ObservationHistoryScript.new()
	_defender_profile = catalog.get_defender_profile(&"profile.normal")
	_defender_budget = rules.initial_defense_budget
	_defender_variation = DefenderVariationScript.new(root_seed)
	_run_defender_planning(MatchPhase.INITIAL_DEFENSE)
	publish_current_view()


func configure_fixed_defense(deployments: Array[TowerDeployment]) -> void:
	_assert_initialized()
	_tower_deployments.clear()
	for deployment: TowerDeployment in deployments:
		_tower_deployments.append(deployment.copy())


func commit_wave(
	command: PhaseCommand,
	entries: Array[WaveDraftEntry],
) -> CommandResult:
	_assert_initialized()
	if command.command_type != PhaseCommand.COMMIT_WAVE:
		return CommandResult.reject(CommandResult.CODE_UNKNOWN_COMMAND, "Commit requires a commit_wave command.")
	var schedule_entries: Array[WaveScheduleEntry] = []
	for index: int in entries.size():
		var entry: WaveDraftEntry = entries[index]
		schedule_entries.append(WaveScheduleEntry.new(
			entry.get_unit_id(),
			entry.get_route_id(),
			0 if index == 0 else entry.get_spacing_after_previous(),
		))
	var schedule: SpawnScheduleResult = UnitSpawnSchedule.build(
		schedule_entries,
		_catalog,
		_catalog.get_map(_rules.map_id),
	)
	if not schedule.is_accepted:
		return CommandResult.reject(CommandResult.CODE_INVALID_WAVE, schedule.message)
	var phase_result: CommandResult = _state.apply_phase_command(command)
	if not phase_result.is_accepted:
		return phase_result
	_active_simulation = FixedDefenseSimulation.new(
		_state.get_root_seed(), _catalog, _rules, schedule, _tower_deployments, true, _core_integrity,
	)
	publish_current_view()
	return phase_result


func begin_resolution(command: PhaseCommand) -> CommandResult:
	return apply_phase_command(command)


func advance_resolution_tick() -> bool:
	_assert_initialized()
	if _active_simulation == null or _state.get_phase() != MatchPhase.RESOLVING:
		return false
	_active_simulation.advance_one_tick()
	_core_integrity = _active_simulation.get_core_integrity()
	publish_current_view()
	return _active_simulation.is_resolved()


func get_active_simulation() -> FixedDefenseSimulation:
	return _active_simulation


func get_post_wave_analysis():
	_assert_initialized()
	assert(_active_simulation != null and _active_simulation.is_resolved(), "analysis requires a resolved wave")
	return PostWaveAnalysisScript.new(_active_simulation)


func complete_analysis(command_id: int) -> CommandResult:
	_assert_initialized()
	if _state.get_phase() != MatchPhase.ANALYSIS:
		return CommandResult.reject(CommandResult.CODE_WRONG_PHASE, "Analysis is not active.")
	if _core_integrity <= 0 or _state.get_round_index() >= _rules.round_count:
		return apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.END_MATCH, MatchPhase.ANALYSIS, PhaseCommand.ACTOR_SYSTEM))
	if _adaptive_defender_enabled:
		_observation_history.append_finalized(_state.get_round_index(), get_post_wave_analysis())
		_defender_budget += _rules.adaptation_grant
	var transition: CommandResult = apply_phase_command(PhaseCommand.new(command_id, PhaseCommand.BEGIN_ANALYSIS, MatchPhase.ANALYSIS, PhaseCommand.ACTOR_SYSTEM))
	if not transition.is_accepted:
		return transition
	if _adaptive_defender_enabled:
		_run_defender_planning(MatchPhase.DEFENDER_ADAPTATION)
	return apply_phase_command(PhaseCommand.new(command_id + 1, PhaseCommand.BEGIN_NEXT_ROUND, MatchPhase.DEFENDER_ADAPTATION, PhaseCommand.ACTOR_SYSTEM))


func get_match_outcome() -> StringName:
	_assert_initialized()
	if _state.get_phase() != MatchPhase.MATCH_END:
		return &""
	return &"player_win" if _core_integrity <= 0 else &"defender_win"


func get_round_index() -> int:
	_assert_initialized()
	return _state.get_round_index()


func restart() -> void:
	_assert_initialized()
	_state = MatchState.new(_root_seed)
	_active_simulation = null
	_core_integrity = _rules.core_health
	_published_event_count = 0
	_observation_history = ObservationHistoryScript.new()
	_decision_traces.clear()
	_defender_budget = _rules.initial_defense_budget
	_next_decision_id = 1
	_defender_variation = DefenderVariationScript.new(_root_seed)
	if _adaptive_defender_enabled:
		_run_defender_planning(MatchPhase.INITIAL_DEFENSE)
	publish_current_view()

func get_decision_traces() -> Array:
	return _decision_traces.duplicate()

func get_defender_deployments() -> Array[TowerDeployment]:
	var result: Array[TowerDeployment] = []
	for deployment: TowerDeployment in _tower_deployments:
		result.append(deployment.copy())
	return result

func get_latest_defense_explanation() -> String:
	if _decision_traces.is_empty(): return "Defense retained its public layout."
	var trace = _decision_traces.back()
	var leaks: int = int(trace.features.get(&"leaks", 0))
	if leaks > 0: return "Defense adapted after %d observed prior leaks." % leaks
	return "Defense strengthened public coverage between rounds."

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
	return _create_current_view()

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
	view_published.emit(_create_current_view(), new_events)


func _create_current_view() -> MatchView:
	var state_view: MatchView = _state.create_view()
	if _active_simulation == null:
		return state_view
	return MatchView.new(
		state_view.get_phase(),
		_active_simulation.get_tick(),
		state_view.get_allocated_entity_count(),
		_active_simulation.create_entity_views(),
	)

func _assert_initialized() -> void:
	assert(_state != null, "MatchCoordinator must be initialized by the composition root")

func _run_defender_planning(phase: StringName) -> void:
	var gateway = DefenseCommandGatewayScript.new(_catalog, _rules, _defender_budget, _tower_deployments)
	var observation = ObservationProjectorScript.project(_state.get_round_index(), phase, _defender_profile, _core_integrity, _defender_budget, _tower_deployments, _observation_history, _rules, _catalog.content_fingerprint())
	var planner := DefenderPlannerScript.new()
	var trace = planner.plan(observation, _defender_profile, _catalog, _rules, gateway, _defender_variation, _next_decision_id)
	_next_decision_id += 1
	_defender_budget = gateway.get_budget()
	_tower_deployments = gateway.get_deployments()
	_decision_traces.append(trace)
