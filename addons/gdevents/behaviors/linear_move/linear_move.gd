## Поведение «Прямолинейное движение».
##
## @behavior LinearMove
## @title Прямолинейное движение
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @description Движение по углу с разгоном, гравитацией, сопротивлением, отскоком от краёв и угасанием. Основа для пуль и простых врагов.
## @icon move
@tool
extends GdeBehavior

## Время жизни вышло.
signal expired
## Отскочил от края экрана.
signal bounced

@export_group("Движение")
## Направление в градусах: 0 вправо, −90 вверх, 90 вниз.
@export_range(-180.0, 180.0, 1.0) var angle: float = 0.0
## Скорость полёта, пикселей в секунду.
@export_range(0.0, 3000.0, 5.0) var speed: float = 200.0
## Разгон, пикселей в секунду за секунду. Отрицательный — замедление.
@export_range(-3000.0, 3000.0, 10.0) var acceleration: float = 0.0
## Потолок скорости при разгоне.
@export_range(0.0, 5000.0, 10.0) var max_speed: float = 0.0
## Сопротивление среды — какая доля скорости теряется за секунду.
@export_range(0.0, 5.0, 0.05) var drag: float = 0.0

@export_group("Гравитация")
## Гравитация — тянет вниз, превращая полёт в дугу.
@export_range(0.0, 3000.0, 10.0) var gravity: float = 0.0

@export_group("Жизнь")
## Время жизни, секунд. 0 — живёт вечно.
@export_range(0.0, 60.0, 0.1) var lifetime: float = 3.0
## Угасание — за сколько секунд до конца начать растворяться.
@export_range(0.0, 10.0, 0.1) var fade_out: float = 0.0

@export_group("Края экрана")
## Отскок от краёв экрана вместо вылета за них.
@export var bounce_off_edges: bool = false
## Упругость — какая доля скорости остаётся после отскока.
@export_range(0.0, 1.5, 0.05) var bounciness: float = 1.0

@export_group("Вид")
## Поворот объекта по направлению полёта.
@export var rotate_to_direction: bool = false

var _age: float = 0.0
var _vel: Vector2 = Vector2.ZERO
var _has_vel: bool = false
var _base_alpha: float = -1.0


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return

	# Скорость храним вектором: только так работают гравитация и отскок.
	if not _has_vel:
		_vel = Vector2.RIGHT.rotated(deg_to_rad(angle)) * speed
		_has_vel = true

	if not is_zero_approx(acceleration):
		_vel += _vel.normalized() * acceleration * delta
		if max_speed > 0.0 and _vel.length() > max_speed:
			_vel = _vel.normalized() * max_speed
	if drag > 0.0:
		_vel = _vel.lerp(Vector2.ZERO, clampf(drag * delta, 0.0, 1.0))
	if gravity > 0.0:
		_vel.y += gravity * delta

	o.global_position += _vel * delta
	angle = rad_to_deg(_vel.angle())
	speed = _vel.length()

	if rotate_to_direction and _vel.length_squared() > 1.0:
		o.global_rotation = _vel.angle()

	if bounce_off_edges:
		_bounce(o)

	if lifetime > 0.0:
		_age += delta
		_apply_fade(o)
		if _age >= lifetime:
			expired.emit()
			Gde.delete_object(o)


func _apply_fade(o: Node2D) -> void:
	if fade_out <= 0.0:
		return
	var left := lifetime - _age
	if left > fade_out:
		return
	if _base_alpha < 0.0:
		_base_alpha = o.modulate.a
	var c := o.modulate
	c.a = _base_alpha * clampf(left / fade_out, 0.0, 1.0)
	o.modulate = c


func _bounce(o: Node2D) -> void:
	var vp := o.get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	var p := vp.get_canvas_transform() * o.global_position
	var hit := false
	if (p.x < r.position.x and _vel.x < 0.0) or (p.x > r.end.x and _vel.x > 0.0):
		_vel.x = -_vel.x * bounciness
		hit = true
	if (p.y < r.position.y and _vel.y < 0.0) or (p.y > r.end.y and _vel.y > 0.0):
		_vel.y = -_vel.y * bounciness
		hit = true
	if hit:
		bounced.emit()


## @action Задать движение _PARAM0_: угол _PARAM1_ градусов, скорость _PARAM2_
func set_direction(angle_deg: float, new_speed: float) -> void:
	angle = angle_deg
	speed = new_speed
	_vel = Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * new_speed
	_has_vel = true


## @action Развернуть _PARAM0_ на 180 градусов
func reverse() -> void:
	_vel = -_vel


## @action Повернуть полёт _PARAM0_ на _PARAM1_ градусов
func turn(degrees: float) -> void:
	_vel = _vel.rotated(deg_to_rad(degrees))


## @action Направить _PARAM0_ на ближайший объект _PARAM1_
func aim_at(target_name: String) -> void:
	var o := object as Node2D
	if o == null:
		return
	var best: Node2D = null
	var best_d := INF
	for n: Node in Gde.all_instances(target_name):
		var n2 := n as Node2D
		if n2 == null or n2 == o:
			continue
		var d := o.global_position.distance_squared_to(n2.global_position)
		if d < best_d:
			best_d = d
			best = n2
	if best != null:
		set_direction(rad_to_deg((best.global_position - o.global_position).angle()), _vel.length())


## @action Продлить жизнь _PARAM0_ на _PARAM1_ секунд
func extend_life(seconds: float) -> void:
	_age = maxf(0.0, _age - absf(seconds))


## @condition _PARAM0_ движется
func is_moving() -> bool:
	return _vel.length_squared() > 1.0


## @expression Сколько секунд объект уже живёт
func age() -> float:
	return _age


## @expression Сколько секунд жизни осталось
func life_left() -> float:
	return maxf(0.0, lifetime - _age) if lifetime > 0.0 else 999.0
