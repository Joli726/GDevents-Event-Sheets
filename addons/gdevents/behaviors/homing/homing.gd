## Поведение «Самонаведение».
##
## @behavior Homing
## @title Самонаведение
## @title.en Homing
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Ракета летит вперёд и доворачивает к цели с ограниченной скоростью поворота. Может промахнуться и потерять цель, если та ушла из поля зрения. Со «Выстрелом» стартует туда, куда выстрелили.
## @description.en A missile flies forward and turns toward the target with a limited turn speed. It can miss and lose the target if the target leaves its field of view. With "Shoot" it starts where it was fired.
## @icon homing
@tool
extends GdeBehavior

## Захватил цель.
signal locked
## Потерял цель — промахнулся или цель исчезла.
signal lost_target
## Время жизни вышло.
signal expired

## @group.en Target
@export_group("Цель")
## Цель — имя объекта из листа событий, например Enemy.
## @en Target — the name of an object from the event sheet, e.g. Enemy.
@export var target_object: String = "Enemy"
## Дальность захвата — дальше цель не замечается. 0 — без предела.
## @en Lock range — the target is not noticed beyond it. 0 — no limit.
@export_range(0.0, 5000.0, 10.0) var lock_range: float = 600.0
## Поле зрения, градусов: цель за его пределами теряется. 360 — видит во все стороны и не промахивается.
## @en Field of view, degrees: a target outside it is lost. 360 — sees all around and never misses.
@export_range(10.0, 360.0, 5.0) var view_angle: float = 150.0
## Потеряв цель, искать новую.
## @en After losing the target, look for a new one.
@export var retarget: bool = true

## @group.en Flight
@export_group("Полёт")
## Скорость, пикселей в секунду.
## @en Speed, pixels per second.
@export_range(0.0, 5000.0, 10.0) var speed: float = 300.0
## Разгон, пикселей в секунду за секунду. 0 — постоянная скорость.
## @en Acceleration, pixels per second per second. 0 — a constant speed.
@export_range(0.0, 10000.0, 10.0) var acceleration: float = 0.0
## Предел скорости при разгоне.
## @en Speed limit when accelerating.
@export_range(0.0, 10000.0, 10.0) var max_speed: float = 800.0
## Скорость поворота, градусов в секунду. Меньше — шире дуга и чаще промахи.
## @en Turn speed, degrees per second. Less — a wider arc and more misses.
@export_range(0.0, 2000.0, 5.0) var turn_speed: float = 180.0
## Задержка наведения — сколько секунд лететь прямо после старта.
## @en Homing delay — how many seconds to fly straight after the start.
@export_range(0.0, 5.0, 0.05) var arm_time: float = 0.1
## Время жизни, секунд: потом снаряд исчезает. 0 — вечно.
## @en Lifetime, seconds: then the projectile disappears. 0 — forever.
@export_range(0.0, 60.0, 0.1) var lifetime: float = 5.0
## Поворачивать объект по направлению полёта.
## @en Rotate the object — toward the flight direction.
@export var rotate_object: bool = true
## Наведение включено.
## @en Homing is on.
@export var running: bool = true

var _heading: float = 0.0
var _started: bool = false
var _age: float = 0.0
var _speed: float = 0.0
var _target: Node2D = null
var _lock_frame: int = -100
var _lost_frame: int = -100


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _started:
		_started = true
		_heading = o.global_rotation
		_speed = speed
	if not running:
		return
	_age += delta
	if lifetime > 0.0 and _age >= lifetime:
		expired.emit()
		Gde.delete_object(o)
		return

	if _age >= arm_time:
		_track(o)
		if _target != null:
			var want := (_target.global_position - o.global_position).angle()
			_heading = rotate_toward(_heading, want, deg_to_rad(turn_speed) * delta)
	if acceleration > 0.0:
		_speed = minf(max_speed, _speed + acceleration * delta)

	var vel := Vector2.RIGHT.rotated(_heading) * _speed
	var body := o as CharacterBody2D
	if body != null:
		body.velocity = vel
		body.move_and_slide()
	else:
		o.global_position += vel * delta
	if rotate_object:
		o.global_rotation = _heading


## Держать цель, пока она видна; потерянную — сменить, если можно.
func _track(o: Node2D) -> void:
	if _target != null and not (is_instance_valid(_target) and _acceptable(o, _target)):
		_target = null
		_lost_frame = Engine.get_physics_frames()
		lost_target.emit()
		if not retarget:
			return
	if target_object.is_empty():
		return
	if _target == null and (retarget or _lock_frame < 0):
		var best: Node2D = null
		var best_d := INF
		for n: Node in Gde.all_instances(target_object):
			var t := Gde.main(n)
			if t == null or t == o or not _acceptable(o, t):
				continue
			var d := o.global_position.distance_squared_to(t.global_position)
			if d < best_d:
				best_d = d
				best = t
		if best != null:
			_target = best
			_lock_frame = Engine.get_physics_frames()
			locked.emit()


func _acceptable(o: Node2D, t: Node2D) -> bool:
	var to := t.global_position - o.global_position
	if lock_range > 0.0 and to.length() > lock_range:
		return false
	if view_angle >= 360.0 or to.length() < 1.0:
		return true
	return absf(angle_difference(_heading, to.angle())) <= deg_to_rad(view_angle) * 0.5


## Задать направление полёта. Нужно, если снаряд создан не «Выстрелом», а событием.
## @en Set the flight direction. Needed if the projectile was created by an event, not by "Shoot".
## @action Запустить _PARAM0_ под углом _PARAM1_ градусов
## @action.en Launch _PARAM0_ at an angle of _PARAM1_ degrees
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
func launch(angle_deg: float) -> void:
	_heading = deg_to_rad(angle_deg)
	_started = true
	_speed = speed
	_age = 0.0
	running = true
	var o := object as Node2D
	if o != null and rotate_object:
		o.global_rotation = _heading


## @action Навести _PARAM0_ на объект _PARAM1_
## @action.en Aim _PARAM0_ at object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func set_target(name: String) -> void:
	target_object = name
	_target = null
	_lock_frame = -100


## Снаряд летит дальше прямо и больше не ищет цель.
## @en The projectile keeps flying straight and no longer looks for a target.
## @action Сбросить цель _PARAM0_
## @action.en Drop the target of _PARAM0_
func drop_target() -> void:
	_target = null
	target_object = ""


## @condition _PARAM0_ держит цель
## @condition.en _PARAM0_ has a target locked
func has_target() -> bool:
	return _target != null and is_instance_valid(_target)


## @condition _PARAM0_ только что захватил цель
## @condition.en _PARAM0_ has just locked a target
func just_locked() -> bool:
	return Engine.get_physics_frames() - _lock_frame <= RECENT_FRAMES


## @condition _PARAM0_ только что потерял цель
## @condition.en _PARAM0_ has just lost the target
func just_lost() -> bool:
	return Engine.get_physics_frames() - _lost_frame <= RECENT_FRAMES


## @expression Направление полёта в градусах
## @expression.en Flight direction in degrees
func heading() -> float:
	return rad_to_deg(_heading)


## @expression Текущая скорость
## @expression.en Current speed
func current_speed() -> float:
	return _speed if _started else speed


## @expression Расстояние до цели, -1 — цели нет
## @expression.en Distance to the target, -1 — no target
func distance_to_target() -> float:
	var o := object as Node2D
	if o == null or not has_target():
		return -1.0
	return o.global_position.distance_to(_target.global_position)
