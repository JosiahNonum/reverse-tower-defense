class_name MainCompositionRoot
extends Control

const DEFAULT_ROOT_SEED: int = 1

var _is_composed: bool = false

func _ready() -> void:
	compose()

func compose() -> void:
	if _is_composed:
		return
	var coordinator := get_node("MatchCoordinator") as MatchCoordinator
	var battlefield_view := get_node("MatchScreen/BattlefieldView") as BattlefieldView
	var status := get_node("MatchScreen/Center/Status") as Label
	var catalog := ContentCatalog.load_from_directory("res://content")
	var validation: ContentValidationResult = catalog.validate()
	assert(validation.is_valid(), "Checked-in content must validate before Main composes a match")
	assert(catalog.rules.size() == 1, "v0 expects exactly one checked-in rules definition")
	coordinator.view_published.connect(battlefield_view.reconcile)
	coordinator.initialize(catalog, catalog.rules[0], DEFAULT_ROOT_SEED)
	status.text = "M1 FOUNDATION  /  %s  /  TICK %d" % [coordinator.get_rules_id(), coordinator.get_current_view().get_tick()]
	_is_composed = true
