class_name BuildSlotDefinition
extends Resource


@export var slot_id: StringName
@export var logical_x: int
@export var logical_y: int
@export var allowed_tower_tags: Array[StringName] = []
@export var forbidden_tower_tags: Array[StringName] = []


func to_dictionary() -> Dictionary:
	return {
		"id": String(slot_id),
		"x": logical_x,
		"y": logical_y,
		"allowed_tags": _strings(allowed_tower_tags),
		"forbidden_tags": _strings(forbidden_tower_tags),
	}


func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	result.sort()
	return result
