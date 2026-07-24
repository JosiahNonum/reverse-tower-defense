class_name TowerDeployment
extends RefCounted


var tower_id: StringName
var slot_id: StringName


func _init(deployment_tower_id: StringName, deployment_slot_id: StringName) -> void:
	tower_id = deployment_tower_id
	slot_id = deployment_slot_id


func copy() -> TowerDeployment:
	return TowerDeployment.new(tower_id, slot_id)
