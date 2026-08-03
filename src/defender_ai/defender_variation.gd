class_name DefenderVariation
extends RefCounted

var _seed: MatchSeed
var _draw_ordinal: int = 0

func _init(root_seed: int) -> void:
	_seed = MatchSeed.new(root_seed)

func choose_index(maximum_index: int) -> Dictionary:
	var index: int = _seed.next_int(&"defender_variation", 0, maximum_index)
	var result := {"ordinal": _draw_ordinal, "index": index}
	_draw_ordinal += 1
	return result
