## Поведение «Преследование».
##
## @behavior Follow
## @title Преследование
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @description Гнаться, убегать или держать дистанцию. С разгоном, зоной замечания и потерей цели.
## @icon follow
@tool
extends GdeBehavior

## Заметил цель.
signal target_spotted
## Потерял цель.
signal target_lost

@export_group("Цель")
## Цель — имя объекта из листа событий, например Player.
@export var target_object: String = ""
## Что делать с целью — гнаться, убегать или держать дистанцию.
@export_enum("Гнаться", "Убегать", "Держать дистанцию") var mode: int = 0
## Преследование включено.
@export var running: bool = true

@export_group("Движение")
## Скорость преследования, пикселей в секунду.
@export_range(0.0, 2000.0, 5.0) var speed: float = 120.0
## Разгон, пикселей в секунду за секунду. 0 — мгновенный старт.
@export_range(0.0, 10000.0, 10.0) var acceleration: float = 0.0
## Дистанция остановки — на каком расстоянии замереть.
@export_range(0.0, 1000.0, 1.0) var stop_distance: float = 8.0
## Полоса терпимости вокруг дистанции, чтобы объект не дрожал на месте.
@export_range(0.0, 200.0, 1.0) var deadzone: float = 12.0

@export_group("Зрение")
## Радиус обнаружения — дальше цель не замечается. 0 — без предела.
@export_range(0.0, 3000.0, 10.0) var detection_range: float = 0.0
## Радиус потери — на каком расстоянии цель теряется.
@export_range(0.0, 4000.0, 10.0) var lose_range: float = 0.0

@export_group("Вид")
## Поворот к цели.
@export var rotate_object: bool = false
## Скорость доворота, градусов в секунду.
@export_range(0.0, 30.0, 0.5) var rotation_speed: float = 0.0
## Отражение спрайта по направлению движения.
@export var flip_sprite: bool = false

var _vel: Vector2 = Vector2.ZERO
var _had_target: bool = false


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null or not running or target_object.is_empty():
		return

	var t := _nearest(o)
	var has := t != null
	if has != _had_target:
		_had_target = has
		if has:
			target_spotted.emit()
		else:
			target_lost.emit()
	if not has:
		_vel = _vel.move_toward(Vector2.ZERO, maxf(acceleration, speed * 4.0) * delta)
		o.global_position += _vel * delta
		return

	var to := t.global_position - o.global_position
	var dist := to.length()
	var want := Vector2.ZERO

	match mode:
		1:
			want = -to.normalized() * speed
		2:
			# Держать дистанцию: близко — отойти, далеко — подойти.
			if dist < stop_distance - deadzone:
				want = -to.normalized() * speed
			elif dist > stop_distance + deadzone:
				want = to.normalized() * speed
		_:
			if dist > stop_distance:
				want = to.normalized() * speed

	if acceleration <= 0.0:
		_vel = want
	else:
		_vel = _vel.move_toward(want, acceleration * delta)

	var body := o as CharacterBody2D
	if body != null:
		body.velocity = _vel
		body.move_and_slide()
		_vel = body.velocity
	else:
		o.global_position += _vel * delta

	if rotate_object:
		var target_angle := to.angle()
		if rotation_speed <= 0.0:
			o.global_rotation = target_angle
		else:
			o.global_rotation = rotate_toward(o.global_rotation, target_angle, rotation_speed * delta)
	if flip_sprite and absf(_vel.x) > 1.0:
		Gde.set_flip_h(o, _vel.x < 0.0)


## Ближайшая цель с учётом зон замечания и потери.
func _nearest(o: Node2D) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n: Node in Gde.all_instances(target_object):
		var n2 := n as Node2D
		if n2 == null or n2 == o:
			continue
		var d := o.global_position.distance_squared_to(n2.global_position)
		if d < best_d:
			best_d = d
			best = n2
	if best == null:
		return null
	var dist := sqrt(best_d)
	# Уже видим — теряем только за lose_range, иначе объект дёргался бы на границе.
	var limit := detection_range
	if _had_target and lose_range > 0.0:
		limit = lose_range
	if limit > 0.0 and dist > limit:
		return null
	return best


## @action Задать цель для _PARAM0_: объект _PARAM1_
func target(name: String) -> void:
	target_object = name


## @action Режим _PARAM0_: _PARAM1_ (0 гнаться, 1 убегать, 2 держать дистанцию)
func set_mode(new_mode: float) -> void:
	mode = clampi(int(new_mode), 0, 2)


## @condition _PARAM0_ видит цель
func has_target() -> bool:
	var o := object as Node2D
	return o != null and _nearest(o) != null


## @condition _PARAM0_ дошёл до цели
func reached_target() -> bool:
	var d := distance_to_target()
	return d >= 0.0 and d <= stop_distance + deadzone


## @expression Расстояние до цели
func distance_to_target() -> float:
	var o := object as Node2D
	if o == null:
		return -1.0
	var t := _nearest(o)
	return o.global_position.distance_to(t.global_position) if t != null else -1.0


## @expression Угол на цель в градусах
func angle_to_target() -> float:
	var o := object as Node2D
	if o == null:
		return 0.0
	var t := _nearest(o)
	return rad_to_deg((t.global_position - o.global_position).angle()) if t != null else 0.0
