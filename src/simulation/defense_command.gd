class_name DefenseCommand
extends RefCounted

const PLACE_TOWER: StringName = &"place_tower"
const UPGRADE_TOWER: StringName = &"upgrade_tower"
const SELL_TOWER: StringName = &"sell_tower"
const RESERVE_BUDGET: StringName = &"reserve_budget"

var command_type: StringName
var tower_id: StringName
var slot_id: StringName
var command_id: int

func _init(requested_id: int, requested_type: StringName, requested_tower_id: StringName = &"", requested_slot_id: StringName = &"") -> void:
	command_id = requested_id
	command_type = requested_type
	tower_id = requested_tower_id
	slot_id = requested_slot_id

func copy():
	return get_script().new(command_id, command_type, tower_id, slot_id)

func to_dictionary() -> Dictionary:
	return {"id": command_id, "type": String(command_type), "tower_id": String(tower_id), "slot_id": String(slot_id)}
