class_name MainCompositionRoot
extends Control

const DEFAULT_ROOT_SEED: int = 1
const SettingsStoreScript = preload("res://src/application/settings_store.gd")
var _is_composed: bool = false
var _inspection_model: DefenseInspectionModel
var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _next_command_id: int = 1
var _playback := PlaybackController.new()
var _settings = SettingsStoreScript.new()

func _ready() -> void:
	compose()


func _process(delta: float) -> void:
	if not _is_composed:
		return
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	if coordinator.get_current_view().get_phase() != MatchPhase.RESOLVING:
		return
	for tick: int in _playback.consume_ticks(delta, _rules.ticks_per_second):
		if coordinator.advance_resolution_tick():
			_finish_resolution()
			return

func compose() -> void:
	if _is_composed:
		return
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	var battlefield_view := get_node(
		"MatchScreen/SafeArea/RootLayout/Body/BattlefieldPanel/MapLayout/DefenseMapView/BattlefieldView",
	) as BattlefieldView
	var map_view := %DefenseMapView as DefenseMapView
	var inspection_panel := %DefenseInspectionPanel as DefenseInspectionPanel
	var composer_panel := %WaveComposerPanel as WaveComposerPanel
	_catalog = ContentCatalog.load_from_directory("res://content")
	var validation: ContentValidationResult = _catalog.validate()
	assert(validation.is_valid(), "Checked-in content must validate before Main composes a match")
	assert(_catalog.rules.size() == 1, "v0 expects exactly one checked-in rules definition")
	_rules = _catalog.rules[0]
	var map: MapDefinition = _catalog.get_map(_rules.map_id)
	battlefield_view.configure(map.logical_width, map.logical_height)
	coordinator.view_published.connect(battlefield_view.reconcile)
	map_view.tower_selected.connect(inspection_panel.show_tower)
	composer_panel.configure(_catalog, _rules)
	coordinator.initialize(_catalog, _rules, DEFAULT_ROOT_SEED)
	_playback.set_speed(_settings.load_playback_speed())
	_inspection_model = DefenseInspectionBuilder.new().build(_catalog, map, coordinator.get_defender_deployments())
	map_view.configure(_inspection_model)
	inspection_panel.configure(_inspection_model)
	var reveal_result: CommandResult = coordinator.apply_phase_command(PhaseCommand.new(
		_next_command_id,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))
	assert(reveal_result.is_accepted, "initial scripted defense must reach defense reveal")
	_next_command_id += 1
	%PhaseValue.text = "DEFENSE REVEAL · ROUND %d" % coordinator.get_round_index()
	%MapHint.text = coordinator.get_latest_defense_explanation()
	%BeginAuthoringButton.pressed.connect(_begin_authoring)
	composer_panel.commit_requested.connect(_commit_wave)
	_is_composed = true


func _finish_resolution() -> void:
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	var result: CommandResult = coordinator.apply_phase_command(PhaseCommand.new(
		_next_command_id, PhaseCommand.COMPLETE_RESOLUTION, MatchPhase.RESOLVING, PhaseCommand.ACTOR_SYSTEM,
	))
	if result.is_accepted:
		_next_command_id += 1
		%PlaybackControls.hide()
		var analysis = coordinator.get_post_wave_analysis()
		%PhaseValue.text = "ANALYSIS · %d leaks · core %d" % [analysis.get_leak_count(), analysis.get_core_integrity()]
		var is_terminal_analysis: bool = analysis.get_core_integrity() <= 0 or coordinator.get_round_index() >= _rules.round_count
		if is_terminal_analysis:
			%PhaseValue.text = "FINAL ANALYSIS - %d leaks - core %d" % [
				analysis.get_leak_count(), analysis.get_core_integrity(),
			]
		var damage_by_tower: Dictionary = analysis.get_damage_by_tower()
		var damage_total: int = 0
		for amount: int in damage_by_tower.values():
			damage_total += amount
		%MapHint.text = "ANALYSIS  ·  %d leaks  ·  %d survivors  ·  %d effective damage  ·  core %d" % [
			analysis.get_leak_count(), analysis.get_survivor_count(), damage_total, analysis.get_core_integrity(),
		]
		%ContinueButton.text = "VIEW RESULT" if is_terminal_analysis else "NEXT ROUND"
		%ContinueButton.show()


func _on_pause_button_pressed() -> void:
	_playback.set_paused(not _playback.is_paused())
	%PauseButton.text = "RESUME" if _playback.is_paused() else "PAUSE"


func _on_speed_1_button_pressed() -> void:
	_set_playback_speed(1)


func _on_speed_2_button_pressed() -> void:
	_set_playback_speed(2)


func _on_speed_4_button_pressed() -> void:
	_set_playback_speed(4)


func _on_continue_button_pressed() -> void:
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	if coordinator.get_current_view().get_phase() == MatchPhase.MATCH_END:
		coordinator.restart()
		var reveal_result: CommandResult = coordinator.apply_phase_command(PhaseCommand.new(
			_next_command_id, PhaseCommand.COMPLETE_INITIAL_DEFENSE, MatchPhase.INITIAL_DEFENSE, PhaseCommand.ACTOR_SYSTEM,
		))
		assert(reveal_result.is_accepted, "restart must return to defense reveal")
		_next_command_id += 1
	else:
		var result: CommandResult = coordinator.complete_analysis(_next_command_id)
		assert(result.is_accepted, "analysis must advance through the scripted match")
		_next_command_id += 2
	%ContinueButton.hide()
	if coordinator.get_current_view().get_phase() == MatchPhase.MATCH_END:
		%BeginAuthoringButton.hide()
		%DefenseInspectionPanel.show()
		%WaveComposerPanel.hide()
		%PlaybackControls.hide()
		%ContinueButton.text = "RESTART"
		var outcome_label: String = "PLAYER WIN" if coordinator.get_match_outcome() == &"player_win" else "DEFENDER WIN"
		%PhaseValue.text = "MATCH COMPLETE - %s" % outcome_label
		%MapHint.text = "Final analysis is complete. Restart to try a new five-round counter-plan."
		%ContinueButton.show()
		return
	%DefenseInspectionPanel.show()
	%BeginAuthoringButton.show()
	%MapHint.text = "Numbers count overlapping tower ranges. Colors are qualitative coverage—not a damage forecast. Use ← / → after selecting the map."
	get_wave_composer_panel().configure(_catalog, _rules, coordinator.get_round_index())
	var map: MapDefinition = _catalog.get_map(_rules.map_id)
	_inspection_model = DefenseInspectionBuilder.new().build(_catalog, map, coordinator.get_defender_deployments())
	%DefenseMapView.configure(_inspection_model)
	%DefenseInspectionPanel.configure(_inspection_model)
	%MapHint.text = coordinator.get_latest_defense_explanation()
	%PhaseValue.text = "DEFENSE REVEAL · ROUND %d" % coordinator.get_round_index()
	_is_composed = true


func get_defense_inspection_model() -> DefenseInspectionModel:
	assert(_inspection_model != null, "Main must be composed before inspection")
	return _inspection_model


func get_defense_map_view() -> DefenseMapView:
	return %DefenseMapView as DefenseMapView


func get_defense_inspection_panel() -> DefenseInspectionPanel:
	return %DefenseInspectionPanel as DefenseInspectionPanel


func get_wave_composer_panel() -> WaveComposerPanel:
	return %WaveComposerPanel as WaveComposerPanel


func begin_authoring_for_visual_check() -> void:
	_begin_authoring()


func _begin_authoring() -> void:
	if not _is_composed:
		return
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	if coordinator.get_current_view().get_phase() != MatchPhase.DEFENSE_REVEAL:
		return
	var result: CommandResult = coordinator.apply_phase_command(PhaseCommand.new(
		_next_command_id,
		PhaseCommand.BEGIN_WAVE_AUTHORING,
		MatchPhase.DEFENSE_REVEAL,
		PhaseCommand.ACTOR_PLAYER,
	))
	if not result.is_accepted:
		return
	_next_command_id += 1
	%DefenseInspectionPanel.hide()
	%WaveComposerPanel.show()
	%BeginAuthoringButton.hide()
	%PhaseValue.text = "WAVE AUTHORING  ·  ROUND %d" % coordinator.get_round_index()


func _set_playback_speed(speed: int) -> void:
	if _playback.set_speed(speed):
		_settings.save_playback_speed(speed)


func _commit_wave(entries: Array[WaveDraftEntry]) -> void:
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	var result: CommandResult = coordinator.commit_wave(PhaseCommand.new(
		_next_command_id,
		PhaseCommand.COMMIT_WAVE,
		MatchPhase.WAVE_AUTHORING,
		PhaseCommand.ACTOR_PLAYER,
	), entries)
	if not result.is_accepted:
		return
	_next_command_id += 1
	var begin_result: CommandResult = coordinator.begin_resolution(PhaseCommand.new(
		_next_command_id,
		PhaseCommand.BEGIN_RESOLUTION,
		MatchPhase.WAVE_COMMITTED,
		PhaseCommand.ACTOR_SYSTEM,
	))
	assert(begin_result.is_accepted, "accepted wave must begin resolution")
	_next_command_id += 1
	%WaveComposerPanel.hide()
	%PlaybackControls.show()
