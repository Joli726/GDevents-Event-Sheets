## Поведение «Вращение».
##
## @behavior Rotate
## @title Вращение
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @description Вращение с разгоном, качанием туда-сюда, прилипанием к шагу и доворотом до цели.
## @icon rotate
@tool
extends GdeBehavior

## Довернулся до заданного угла.
signal reached_target

@export_group("Вращение")
## Скорость вращения, градусов в секунду.
@export_range(-1440.0, 1440.0, 5.0) var degrees_per_second: float = 90.0
## Разгон вращения, градусов в секунду за секунду.
@export_range(0.0, 2000.0, 5.0) var acceleration: float = 0.0
## Вращение включено.
@export var running: bool = true

@export_group("Качание")
## Качание туда-сюда вместо полного оборота.
@export var swing: bool = false
## Размах качания, в градусах.
@export_range(1.0, 180.0, 1.0) var swing_degrees: float = 30.0

@export_group("Прилипание")
## Прилипание к шагу — округлять угол до шага в градусах. 0 — без прилипания.
@export_range(0.0, 180.0, 1.0) var snap_step: float = 0.0

var _speed: float = 0.0
var _has_speed: bool = false
var _base: float = 0.0
var _has_base: bool = false
var _swing_time: float = 0.0
var _target: float = NAN
var _target_speed: float = 0.0


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _has_base:
		_base = o.global_rotation_degrees
		_has_base = true
	if not _has_speed:
		_speed = degrees_per_second
		_has_speed = true

	# Доворот до цели важнее обычного вращения.
	if not is_nan(_target):
		var cur := o.global_rotation
		var want := deg_to_rad(_target)
		o.global_rotation = rotate_toward(cur, want, deg_to_rad(_target_speed) * delta)
		if absf(angle_difference(o.global_rotation, want)) < 0.01:
			o.global_rotation = want
			_target = NAN
			reached_target.emit()
		return

	if not running:
		return

	if swing:
		_swing_time += delta
		var hz := absf(_speed) / maxf(1.0, swing_degrees * 4.0)
		o.global_rotation_degrees = _base + sin(_swing_time * TAU * hz) * swing_degrees
		return

	if not is_zero_approx(acceleration):
		_speed += signf(_speed if not is_zero_approx(_speed) else 1.0) * acceleration * delta
	o.global_rotation_degrees += _speed * delta

	if snap_step > 0.0:
		o.global_rotation_degrees = roundf(o.global_rotation_degrees / snap_step) * snap_step


## @action Задать скорость вращения _PARAM0_: _PARAM1_ градусов в секунду
func set_rotation_speed(dps: float) -> void:
	_speed = dps
	degrees_per_second = dps
	_has_speed = true


## @action Развернуть вращение _PARAM0_ в другую сторону
func reverse() -> void:
	_speed = -_speed
	degrees_per_second = _speed


## @action Повернуть _PARAM0_ к углу _PARAM1_ со скоростью _PARAM2_ градусов в секунду
func turn_to(target_degrees: float, dps: float) -> void:
	_target = target_degrees
	_target_speed = maxf(1.0, absf(dps))


## @condition _PARAM0_ вращается
func is_running() -> bool:
	return running and not is_zero_approx(_speed)


## @condition _PARAM0_ доворачивается до цели
func is_turning() -> bool:
	return not is_nan(_target)


## @expression Текущая скорость вращения
func current_speed() -> float:
	return _speed
