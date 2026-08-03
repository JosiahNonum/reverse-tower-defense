class_name DefenseCommandGateway
extends RefCounted

const DefenseCommandScript = preload("res://src/simulation/defense_command.gd")

var _catalog: ContentCatalog
var _map: MapDefinition
var _rules: MatchRulesDefinition
var _refund_basis_points: int
var _budget: int
var _deployments: Array[TowerDeployment] = []

func _init(catalog: ContentCatalog, rules: MatchRulesDefinition, budget: int, deployments: Array[TowerDeployment] = []) -> void:
	_catalog = catalog
	_rules = rules
	_map = catalog.get_map(rules.map_id)
	_refund_basis_points = rules.sale_refund_basis_points
	_budget = budget
	for deployment: TowerDeployment in deployments:
		_deployments.append(deployment.copy())

func apply(command) -> CommandResult:
	match command.command_type:
		DefenseCommandScript.PLACE_TOWER:
			return _place(command)
		DefenseCommandScript.UPGRADE_TOWER:
			return _upgrade(command)
		DefenseCommandScript.SELL_TOWER:
			return _sell(command)
		DefenseCommandScript.RESERVE_BUDGET:
			return CommandResult.accept()
	return CommandResult.reject(CommandResult.CODE_UNKNOWN_COMMAND, "Unknown defense command.")

func get_budget() -> int:
	return _budget

func get_deployments() -> Array[TowerDeployment]:
	var result: Array[TowerDeployment] = []
	for deployment: TowerDeployment in _deployments:
		result.append(deployment.copy())
	return result

func is_legal(command) -> bool:
	var preview = get_script().new(_catalog, _rules, _budget, _deployments)
	return preview.apply(command).is_accepted

func _place(command) -> CommandResult:
	var tower: TowerDefinition = _catalog.get_tower(command.tower_id)
	var slot: BuildSlotDefinition = _slot(command.slot_id)
	if tower == null or slot == null or _occupied(command.slot_id) or not _allowed(tower, slot):
		return CommandResult.reject(CommandResult.CODE_INVALID_WAVE, "Illegal tower placement.")
	if tower.cost > _budget:
		return CommandResult.reject(CommandResult.CODE_INVALID_WAVE, "Insufficient defender budget.")
	_budget -= tower.cost
	_deployments.append(TowerDeployment.new(tower.content_id, slot.slot_id))
	return CommandResult.accept()

func _upgrade(command) -> CommandResult:
	var index: int = _deployment_index(command.slot_id)
	if index < 0:
		return CommandResult.reject(CommandResult.CODE_INVALID_WAVE, "No tower occupies that slot.")
	var current: TowerDefinition = _catalog.get_tower(_deployments[index].tower_id)
	var upgrade: TowerDefinition = _catalog.get_tower(current.upgrade_to_id)
	if upgrade == null or upgrade.cost > _budget:
		return CommandResult.reject(CommandResult.CODE_INVALID_WAVE, "Illegal or unaffordable upgrade.")
	_budget -= upgrade.cost
	_deployments[index] = TowerDeployment.new(upgrade.content_id, command.slot_id)
	return CommandResult.accept()

func _sell(command) -> CommandResult:
	var index: int = _deployment_index(command.slot_id)
	if index < 0:
		return CommandResult.reject(CommandResult.CODE_INVALID_WAVE, "No tower occupies that slot.")
	var tower: TowerDefinition = _catalog.get_tower(_deployments[index].tower_id)
	_budget += tower.cost * _refund_basis_points / 10000
	_deployments.remove_at(index)
	return CommandResult.accept()

func _slot(slot_id: StringName) -> BuildSlotDefinition:
	for slot: BuildSlotDefinition in _map.build_slots:
		if slot.slot_id == slot_id: return slot
	return null

func _occupied(slot_id: StringName) -> bool:
	return _deployment_index(slot_id) >= 0

func _deployment_index(slot_id: StringName) -> int:
	for index: int in _deployments.size():
		if _deployments[index].slot_id == slot_id: return index
	return -1

func _allowed(tower: TowerDefinition, slot: BuildSlotDefinition) -> bool:
	for tag: StringName in tower.tags:
		if slot.forbidden_tower_tags.has(tag): return false
	if slot.allowed_tower_tags.is_empty(): return true
	for tag: StringName in tower.tags:
		if slot.allowed_tower_tags.has(tag): return true
	return false
