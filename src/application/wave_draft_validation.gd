class_name WaveDraftValidation
extends RefCounted


var _is_valid: bool
var _total_cost: int
var _budget: int
var _messages: Array[String] = []


func _init(
	is_valid: bool,
	total_cost: int,
	budget: int,
	messages: Array[String],
) -> void:
	_is_valid = is_valid
	_total_cost = total_cost
	_budget = budget
	_messages.assign(messages)


func is_valid() -> bool:
	return _is_valid


func get_total_cost() -> int:
	return _total_cost


func get_budget() -> int:
	return _budget


func get_remaining_budget() -> int:
	return _budget - _total_cost


func get_messages() -> Array[String]:
	return _messages.duplicate()


func get_summary() -> String:
	return "Draft ready" if _is_valid else " · ".join(_messages)
