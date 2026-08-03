class_name PlaybackController
extends RefCounted


const SPEEDS: Array[int] = [1, 2, 4]

var _paused: bool = false
var _speed: int = 1
var _tick_credit: float = 0.0


func set_paused(value: bool) -> void:
	_paused = value


func is_paused() -> bool:
	return _paused


func set_speed(value: int) -> bool:
	if not SPEEDS.has(value):
		return false
	_speed = value
	return true


func get_speed() -> int:
	return _speed


func consume_ticks(delta_seconds: float, ticks_per_second: int) -> int:
	if _paused or delta_seconds <= 0.0:
		return 0
	_tick_credit += delta_seconds * float(ticks_per_second * _speed)
	var ticks: int = int(floor(_tick_credit))
	_tick_credit -= float(ticks)
	return ticks
