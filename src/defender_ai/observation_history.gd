class_name ObservationHistory
extends RefCounted

var _rows: Array[Dictionary] = []

func append_finalized(round_index: int, analysis) -> void:
	_rows.append({"round":round_index,"core":analysis.get_core_integrity(),"leaks":analysis.get_leak_count(),"survivors":analysis.get_survivor_count(),"damage_by_location":analysis.get_damage_by_location()})

func visible(delay_rounds: int) -> Array[Dictionary]:
	var maximum_round: int = _rows.size() - delay_rounds
	var result: Array[Dictionary] = []
	for row: Dictionary in _rows:
		if int(row["round"]) <= maximum_round: result.append(row.duplicate(true))
	return result

func clear() -> void:
	_rows.clear()
