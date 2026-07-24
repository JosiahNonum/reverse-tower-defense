class_name SemanticResultDiff
extends RefCounted


static func compare(expected: Variant, actual: Variant) -> Array[String]:
	var differences: Array[String] = []
	_compare_value(expected, actual, "$", differences)
	return differences


static func format(expected: Variant, actual: Variant) -> String:
	return "\n".join(compare(expected, actual))


static func _compare_value(
	expected: Variant,
	actual: Variant,
	path: String,
	differences: Array[String],
) -> void:
	if (
		(typeof(expected) == TYPE_INT or typeof(expected) == TYPE_FLOAT)
		and (typeof(actual) == TYPE_INT or typeof(actual) == TYPE_FLOAT)
		and expected == actual
	):
		return
	if typeof(expected) != typeof(actual):
		differences.append(
			"%s: expected type %s, received %s" % [
				path,
				type_string(typeof(expected)),
				type_string(typeof(actual)),
			],
		)
		return
	match typeof(expected):
		TYPE_DICTIONARY:
			_compare_dictionary(expected, actual, path, differences)
		TYPE_ARRAY:
			_compare_array(expected, actual, path, differences)
		_:
			if expected != actual:
				differences.append("%s: expected %s, received %s" % [
					path,
					JSON.stringify(expected),
					JSON.stringify(actual),
				])


static func _compare_dictionary(
	expected: Dictionary,
	actual: Dictionary,
	path: String,
	differences: Array[String],
) -> void:
	var keys: Array[String] = []
	for key: Variant in expected.keys():
		keys.append(String(key))
	for key: Variant in actual.keys():
		var text_key := String(key)
		if not keys.has(text_key):
			keys.append(text_key)
	keys.sort()
	for key: String in keys:
		var child_path := "%s.%s" % [path, key]
		if not expected.has(key):
			differences.append("%s: unexpected value %s" % [
				child_path,
				JSON.stringify(actual[key]),
			])
		elif not actual.has(key):
			differences.append("%s: missing; expected %s" % [
				child_path,
				JSON.stringify(expected[key]),
			])
		else:
			_compare_value(expected[key], actual[key], child_path, differences)


static func _compare_array(
	expected: Array,
	actual: Array,
	path: String,
	differences: Array[String],
) -> void:
	if expected.size() != actual.size():
		differences.append("%s: expected %d entries, received %d" % [
			path,
			expected.size(),
			actual.size(),
		])
	var shared_size: int = mini(expected.size(), actual.size())
	for index: int in shared_size:
		_compare_value(
			expected[index],
			actual[index],
			"%s[%d]" % [path, index],
			differences,
		)
