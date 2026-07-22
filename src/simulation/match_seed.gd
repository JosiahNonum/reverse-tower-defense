class_name MatchSeed
extends RefCounted


var root_seed: int
var _streams: Dictionary[StringName, RandomNumberGenerator] = {}


func _init(seed_value: int) -> void:
	root_seed = seed_value


func stream_seed(stream_name: StringName) -> int:
	var text: String = "%d:%s" % [root_seed, String(stream_name)]
	var derived_seed: int = 2166136261
	for index: int in text.length():
		derived_seed = (derived_seed ^ text.unicode_at(index)) * 16777619
		derived_seed &= 0x7fffffff
	return derived_seed if derived_seed != 0 else 1


func next_int(stream_name: StringName, minimum: int, maximum: int) -> int:
	assert(minimum <= maximum, "minimum must not exceed maximum")
	var random: RandomNumberGenerator = _stream(stream_name)
	return random.randi_range(minimum, maximum)


func _stream(stream_name: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var random := RandomNumberGenerator.new()
		random.seed = stream_seed(stream_name)
		_streams[stream_name] = random
	return _streams[stream_name]
