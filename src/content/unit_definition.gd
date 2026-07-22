class_name UnitDefinition
extends Resource


@export var content_id: StringName
@export var cost: int
@export var max_health: int
@export var armor: int
@export var speed_per_tick: int
@export var leak_damage: int
@export var allowed_route_ids: Array[StringName] = []
@export var rally_range: int = 0
@export var rally_numerator: int = 0
@export var rally_denominator: int = 1
@export_file("*.tscn") var presentation_scene_path: String


func to_dictionary() -> Dictionary:
	return {
		"kind": "unit",
		"id": String(content_id),
		"cost": cost,
		"health": max_health,
		"armor": armor,
		"speed": speed_per_tick,
		"leak": leak_damage,
		"routes": _strings(allowed_route_ids),
		"rally_range": rally_range,
		"rally_numerator": rally_numerator,
		"rally_denominator": rally_denominator,
		"presentation": presentation_scene_path,
	}


func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	result.sort()
	return result
