class_name PostWaveAnalysis
extends RefCounted


var _core_integrity: int
var _survivor_count: int
var _leak_count: int
var _damage_by_tower: Dictionary[String, int]
var _deaths_by_location: Dictionary[String, int]
var _damage_by_location: Dictionary[String, int]


func _init(simulation: FixedDefenseSimulation) -> void:
	_core_integrity = simulation.get_core_integrity()
	_damage_by_tower = {}
	_deaths_by_location = {}
	_damage_by_location = {}
	for unit: UnitState in simulation.get_units():
		if unit.is_active():
			_survivor_count += 1
	for event: DomainEvent in simulation.get_events():
		match event.event_type:
			FixedDefenseSimulation.EVENT_UNIT_LEAKED:
				_leak_count += 1
			FixedDefenseSimulation.EVENT_UNIT_DAMAGED:
				var tower_key: String = "%s@%s" % [event.data["source_tower_definition_id"], event.data["source_slot_id"]]
				var location_key: String = "%s/%s" % [event.data["route_id"], event.data["edge_id"]]
				_increment(_damage_by_tower, tower_key, int(event.data["health_before"]) - int(event.data["health_after"]))
				_increment(_damage_by_location, location_key, int(event.data["health_before"]) - int(event.data["health_after"]))
			FixedDefenseSimulation.EVENT_UNIT_DIED:
				_increment(_deaths_by_location, "%s/edge_%d" % [event.data["route_id"], event.data["edge_index"]], 1)


func get_core_integrity() -> int:
	return _core_integrity


func get_survivor_count() -> int:
	return _survivor_count


func get_leak_count() -> int:
	return _leak_count


func get_damage_by_tower() -> Dictionary[String, int]:
	return _damage_by_tower.duplicate()


func get_deaths_by_location() -> Dictionary[String, int]:
	return _deaths_by_location.duplicate()


func get_damage_by_location() -> Dictionary[String, int]:
	return _damage_by_location.duplicate()


func _increment(values: Dictionary[String, int], key: String, amount: int) -> void:
	values[key] = values.get(key, 0) + amount
