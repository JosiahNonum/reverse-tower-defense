class_name MainCompositionRoot
extends Control

const DEFAULT_ROOT_SEED: int = 1
const INITIAL_DEFENSE: Array[Array] = [
	[&"tower.rapid", &"slot.approach"],
	[&"tower.splash", &"slot.north_2"],
	[&"tower.control", &"slot.south_2"],
	[&"tower.anti_armor", &"slot.chokepoint_1"],
	[&"tower.rapid", &"slot.chokepoint_2"],
]

var _is_composed: bool = false
var _inspection_model: DefenseInspectionModel
var _catalog: ContentCatalog
var _rules: MatchRulesDefinition
var _next_command_id: int = 1

func _ready() -> void:
	compose()

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
	_inspection_model = DefenseInspectionBuilder.new().build(
		_catalog,
		map,
		_initial_defense_deployments(),
	)
	coordinator.view_published.connect(battlefield_view.reconcile)
	map_view.tower_selected.connect(inspection_panel.show_tower)
	map_view.configure(_inspection_model)
	inspection_panel.configure(_inspection_model)
	composer_panel.configure(_catalog, _rules)
	coordinator.initialize(_catalog, _rules, DEFAULT_ROOT_SEED)
	var reveal_result: CommandResult = coordinator.apply_phase_command(PhaseCommand.new(
		_next_command_id,
		PhaseCommand.COMPLETE_INITIAL_DEFENSE,
		MatchPhase.INITIAL_DEFENSE,
		PhaseCommand.ACTOR_SYSTEM,
	))
	assert(reveal_result.is_accepted, "initial scripted defense must reach defense reveal")
	_next_command_id += 1
	%BeginAuthoringButton.pressed.connect(_begin_authoring)
	%PhaseValue.text = "DEFENSE REVEAL  ·  ROUND 1"
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
	%PhaseValue.text = "WAVE AUTHORING  ·  ROUND 1"


func _initial_defense_deployments() -> Array[TowerDeployment]:
	var deployments: Array[TowerDeployment] = []
	for values: Array in INITIAL_DEFENSE:
		deployments.append(TowerDeployment.new(values[0], values[1]))
	return deployments
