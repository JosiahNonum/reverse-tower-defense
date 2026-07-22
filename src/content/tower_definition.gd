class_name TowerDefinition
extends Resource


const TARGET_RAPID: StringName = &"rapid"
const TARGET_SPLASH: StringName = &"splash"
const TARGET_CONTROL: StringName = &"control"
const TARGET_ANTI_ARMOR: StringName = &"anti_armor"

@export var content_id: StringName
@export var tags: Array[StringName] = []
@export var cost: int
@export var range: int
@export var damage: int
@export var cooldown_ticks: int
@export var targeting_kind: StringName
@export var splash_radius: int = 0
@export var ignores_armor: bool = false
@export var slow_numerator: int = 0
@export var slow_denominator: int = 1
@export var slow_duration_ticks: int = 0
@export var upgrade_to_id: StringName
@export_file("*.tscn") var presentation_scene_path: String


func to_dictionary() -> Dictionary:
	return {
		"kind": "tower",
		"id": String(content_id),
		"tags": _strings(tags),
		"cost": cost,
		"range": range,
		"damage": damage,
		"cooldown": cooldown_ticks,
		"targeting": String(targeting_kind),
		"splash_radius": splash_radius,
		"ignores_armor": ignores_armor,
		"slow_numerator": slow_numerator,
		"slow_denominator": slow_denominator,
		"slow_duration": slow_duration_ticks,
		"upgrade_to": String(upgrade_to_id),
		"presentation": presentation_scene_path,
	}


func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	result.sort()
	return result
