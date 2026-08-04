class_name BattlefieldEntityVisual
extends Node2D

const UNIT_COLOR := Color("f3b56b")
const TOWER_COLOR := Color("72e0b8")
const OUTLINE_COLOR := Color("102033")
const ATTACK_COLOR := Color("f4f7ff")

var _entity_kind: StringName = &""
var _entity_id: int = 0
var _attack_flash: bool = false
var _health: int = 0
var _max_health: int = 0


func configure(entity_id: int, entity_kind: StringName) -> void:
	_entity_id = entity_id
	_entity_kind = entity_kind
	queue_redraw()


func set_health(health: int, max_health: int) -> void:
	_health = health
	_max_health = max_health
	queue_redraw()


func set_attack_flash(enabled: bool) -> void:
	_attack_flash = enabled
	queue_redraw()


func _draw() -> void:
	if _entity_kind == &"tower":
		_draw_tower()
	else:
		_draw_unit()
	if _attack_flash:
		draw_circle(Vector2.ZERO, 18.0, Color(0.96, 0.97, 1.0, 0.18))
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, ATTACK_COLOR, 2.0, true)


func _draw_unit() -> void:
	draw_circle(Vector2.ZERO, 8.0, UNIT_COLOR)
	draw_circle(Vector2.ZERO, 8.0, OUTLINE_COLOR, false, 2.0)
	if _max_health <= 0:
		return
	var ratio: float = clampf(float(_health) / float(_max_health), 0.0, 1.0)
	draw_rect(Rect2(-13.0, -15.0, 26.0, 4.0), Color("172336"), true)
	draw_rect(Rect2(-12.0, -14.0, 24.0 * ratio, 2.0), Color("72e0b8"), true)


func _draw_tower() -> void:
	draw_rect(Rect2(-9.0, -9.0, 18.0, 18.0), TOWER_COLOR, true)
	draw_rect(Rect2(-9.0, -9.0, 18.0, 18.0), OUTLINE_COLOR, false, 2.0)
	draw_line(Vector2(-4.0, 0.0), Vector2(4.0, 0.0), OUTLINE_COLOR, 2.0)
	draw_line(Vector2(0.0, -4.0), Vector2(0.0, 4.0), OUTLINE_COLOR, 2.0)
