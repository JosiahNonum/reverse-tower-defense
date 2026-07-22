class_name IntegerMath
extends RefCounted


static func multiply_ratio_floor(value: int, numerator: int, denominator: int) -> int:
	assert(value >= 0, "value must be nonnegative")
	assert(numerator >= 0, "numerator must be nonnegative")
	assert(denominator > 0, "denominator must be positive")
	return (value * numerator) / denominator


static func squared_distance(
	left_x: int,
	left_y: int,
	right_x: int,
	right_y: int,
) -> int:
	var delta_x: int = left_x - right_x
	var delta_y: int = left_y - right_y
	return delta_x * delta_x + delta_y * delta_y


static func is_inside_inclusive_range(
	distance_squared: int,
	range_value: int,
) -> bool:
	assert(distance_squared >= 0, "distance squared must be nonnegative")
	assert(range_value >= 0, "range must be nonnegative")
	return distance_squared <= range_value * range_value
