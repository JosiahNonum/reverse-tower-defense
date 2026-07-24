class_name CombatTelemetrySummary
extends RefCounted


var scenario_id: StringName
var root_seed: int
var ending_tick: int
var core_integrity: int
var event_counts: Dictionary[String, int]
var spawns_by_unit: Dictionary[String, int]
var deaths_by_unit: Dictionary[String, int]
var leaks_by_unit: Dictionary[String, int]
var attacks_by_source: Dictionary[String, int]
var effects_by_type: Dictionary[String, int]
var effective_damage_by_source: Dictionary[String, int]
var effective_damage_by_location: Dictionary[String, int]
var total_effective_damage: int
var total_overkill_damage: int


func _init(
	summary_scenario_id: StringName,
	summary_root_seed: int,
	summary_ending_tick: int,
	summary_core_integrity: int,
) -> void:
	scenario_id = summary_scenario_id
	root_seed = summary_root_seed
	ending_tick = summary_ending_tick
	core_integrity = summary_core_integrity
	event_counts = {}
	spawns_by_unit = {}
	deaths_by_unit = {}
	leaks_by_unit = {}
	attacks_by_source = {}
	effects_by_type = {}
	effective_damage_by_source = {}
	effective_damage_by_location = {}


static func from_simulation(
	summary_scenario_id: StringName,
	simulation: FixedDefenseSimulation,
) -> CombatTelemetrySummary:
	var summary := CombatTelemetrySummary.new(
		summary_scenario_id,
		simulation.get_root_seed(),
		simulation.get_tick(),
		simulation.get_core_integrity(),
	)
	for event: DomainEvent in simulation.get_events():
		_increment(summary.event_counts, String(event.event_type))
		match event.event_type:
			FixedDefenseSimulation.EVENT_UNIT_SPAWNED:
				_increment(summary.spawns_by_unit, event.data["unit_id"])
			FixedDefenseSimulation.EVENT_TOWER_ATTACKED:
				_increment(
					summary.attacks_by_source,
					_source_key(event.data["tower_id"], event.data["slot_id"]),
				)
			FixedDefenseSimulation.EVENT_UNIT_DAMAGED:
				var effective_damage: int = (
					int(event.data["health_before"]) - int(event.data["health_after"])
				)
				var overkill_damage: int = (
					int(event.data["resolved_damage"]) - effective_damage
				)
				summary.total_effective_damage += effective_damage
				summary.total_overkill_damage += overkill_damage
				_increment(
					summary.effective_damage_by_source,
					_source_key(
						event.data["source_tower_definition_id"],
						event.data["source_slot_id"],
					),
					effective_damage,
				)
				_increment(
					summary.effective_damage_by_location,
					_location_key(event.data["route_id"], event.data["edge_id"]),
					effective_damage,
				)
			FixedDefenseSimulation.EVENT_SLOW_STAGED:
				_increment(summary.effects_by_type, String(event.event_type))
			FixedDefenseSimulation.EVENT_RALLY_APPLIED:
				_increment(summary.effects_by_type, String(event.event_type))
			FixedDefenseSimulation.EVENT_UNIT_DIED:
				_increment(summary.deaths_by_unit, event.data["unit_id"])
			FixedDefenseSimulation.EVENT_UNIT_LEAKED:
				_increment(summary.leaks_by_unit, event.data["unit_id"])
	return summary


func to_dictionary() -> Dictionary:
	return {
		"scenario_id": String(scenario_id),
		"root_seed": str(root_seed),
		"ending_tick": ending_tick,
		"core_integrity": core_integrity,
		"event_counts": _sorted_dictionary(event_counts),
		"spawns_by_unit": _sorted_dictionary(spawns_by_unit),
		"deaths_by_unit": _sorted_dictionary(deaths_by_unit),
		"leaks_by_unit": _sorted_dictionary(leaks_by_unit),
		"attacks_by_source": _sorted_dictionary(attacks_by_source),
		"effects_by_type": _sorted_dictionary(effects_by_type),
		"effective_damage_by_source": _sorted_dictionary(effective_damage_by_source),
		"effective_damage_by_location": _sorted_dictionary(effective_damage_by_location),
		"total_effective_damage": total_effective_damage,
		"total_overkill_damage": total_overkill_damage,
	}


func copy() -> CombatTelemetrySummary:
	var duplicate := CombatTelemetrySummary.new(
		scenario_id,
		root_seed,
		ending_tick,
		core_integrity,
	)
	duplicate.event_counts = event_counts.duplicate()
	duplicate.spawns_by_unit = spawns_by_unit.duplicate()
	duplicate.deaths_by_unit = deaths_by_unit.duplicate()
	duplicate.leaks_by_unit = leaks_by_unit.duplicate()
	duplicate.attacks_by_source = attacks_by_source.duplicate()
	duplicate.effects_by_type = effects_by_type.duplicate()
	duplicate.effective_damage_by_source = effective_damage_by_source.duplicate()
	duplicate.effective_damage_by_location = effective_damage_by_location.duplicate()
	duplicate.total_effective_damage = total_effective_damage
	duplicate.total_overkill_damage = total_overkill_damage
	return duplicate


func to_json() -> String:
	return JSON.stringify(to_dictionary(), "\t") + "\n"


func semantic_digest() -> String:
	return JSON.stringify(to_dictionary()).sha256_text()


static func _increment(
	values: Dictionary[String, int],
	key: String,
	amount: int = 1,
) -> void:
	values[key] = values.get(key, 0) + amount


static func _source_key(definition_id: String, slot_id: String) -> String:
	return "%s@%s" % [definition_id, slot_id]


static func _location_key(route_id: String, edge_id: String) -> String:
	return "%s/%s" % [route_id, edge_id]


static func _sorted_dictionary(values: Dictionary[String, int]) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array[String] = values.keys()
	keys.sort()
	for key: String in keys:
		result[key] = values[key]
	return result
