## Поведение «Вид сверху».
##
## @behavior TopDown
## @title Вид сверху
## @title.en Top-down movement
## @target CharacterBody2D
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @needs AnimatedSprite2D|Sprite2D Спрайт
## @needs.en AnimatedSprite2D|Sprite2D Sprite
## @description Движение в 4 или 8 сторон с разгоном, рывком, плавным поворотом и анимациями.
## @description.en Movement in 4 or 8 directions with acceleration, a dash, smooth turning and animations.
## @icon topdown
@tool
extends GdeBehavior

## Начался рывок.
signal dashed
## Рывок закончился.
signal dash_ended

const PRESETS: Array[Dictionary] = [
	{},
	# Классический — ровное движение восьмёркой.
	{
		"max_speed": 220.0, "acceleration": 1400.0, "deceleration": 1400.0,
		"directions": 8, "rotate_object": false, "rotation_speed": 0.0,
		"dash_enabled": false,
	},
	# Скользкий — катится по инерции.
	{
		"max_speed": 240.0, "acceleration": 700.0, "deceleration": 200.0,
		"directions": 0, "rotate_object": false, "rotation_speed": 0.0,
		"dash_enabled": false,
	},
	# Танк — медленно поворачивается и едет куда смотрит.
	{
		"max_speed": 160.0, "acceleration": 500.0, "deceleration": 600.0,
		"directions": 0, "rotate_object": true, "rotation_speed": 4.0,
		"dash_enabled": false,
	},
	# Резкий — мгновенный старт и рывок.
	{
		"max_speed": 260.0, "acceleration": 5000.0, "deceleration": 5000.0,
		"directions": 8, "rotate_object": false, "rotation_speed": 0.0,
		"dash_enabled": true, "dash_speed": 720.0, "dash_time": 0.14, "dash_cooldown": 0.6,
	},
]

## @group.en Preset
@export_group("Пресет")
## @options.en Custom, Classic, Slippery, Tank, Snappy
@export_enum("Свои настройки", "Классический", "Скользкий", "Танк", "Резкий")
var preset: int = 1
## Поставьте галочку, чтобы записать пресет в настройки. Сама снимается.
## @en Check the box to write the preset into the settings. It unchecks itself.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

## @group.en Movement
@export_group("Движение")
## Максимальная скорость, пикселей в секунду.
## @en Maximum speed, pixels per second.
@export_range(0.0, 2000.0, 1.0) var max_speed: float = 220.0
## Разгон — как быстро набирается скорость.
## @en Acceleration — how fast the speed builds up.
@export_range(0.0, 20000.0, 10.0) var acceleration: float = 1400.0
## Торможение — как быстро гасится скорость без ввода.
## @en Deceleration — how fast the speed dies down without input.
@export_range(0.0, 20000.0, 10.0) var deceleration: float = 1400.0
## Число направлений: 4 — крестом, 8 — с диагоналями, 0 — свободно.
## @en Number of directions: 4 — a cross, 8 — with diagonals, 0 — free.
## @options.en Any, 4 directions, 8 directions
@export_enum("Любое:0", "4 стороны:4", "8 сторон:8") var directions: int = 8

## @group.en Dash
@export_group("Рывок")
## Рывок разрешён — короткий быстрый бросок вперёд.
## @en Dash allowed — a short fast lunge forward.
@export var dash_enabled: bool = false
## Скорость во время рывка.
## @en Speed during a dash.
@export_range(0.0, 3000.0, 10.0) var dash_speed: float = 700.0
## Длительность рывка, секунд.
## @en Dash duration, seconds.
@export_range(0.02, 1.0, 0.01) var dash_time: float = 0.15
## Перезарядка рывка — сколько секунд до следующего.
## @en Dash cooldown — how many seconds until the next one.
@export_range(0.0, 5.0, 0.05) var dash_cooldown: float = 0.6
## Рывок по Shift без событий.
## @en Dash on Shift without events.
@export var dash_on_shift: bool = true

## @group.en Turning and look
@export_group("Поворот и вид")
## Поворот объекта в сторону движения.
## @en Rotate the object toward the movement.
@export var rotate_object: bool = false
## Скорость доворота, градусов в секунду.
## @en Turn speed, degrees per second.
@export_range(0.0, 30.0, 0.5) var rotation_speed: float = 0.0
## Отражение спрайта по направлению движения.
## @en Flip the sprite — toward the movement direction.
@export var flip_sprite: bool = false
## Автоматические анимации по состоянию.
## @en Automatic animations by state.
@export var animate: bool = false
## Анимация покоя — имя из AnimatedSprite2D.
## @en Idle animation — a name from AnimatedSprite2D.
@export var idle_animation: String = "Idle"
## Анимация бега — имя из AnimatedSprite2D.
## @en Run animation — a name from AnimatedSprite2D.
@export var run_animation: String = "Run"

## @group.en Controls
@export_group("Управление")
## Управление стрелками автоматически.
## @en Arrow keys controls, automatic.
@export var default_controls: bool = true

var _input: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _dash_left: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _want_dash: bool = false


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return

	var dir := _input
	if default_controls:
		dir += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if dash_on_shift and Input.is_key_pressed(KEY_SHIFT):
			_want_dash = true
	_input = Vector2.ZERO
	if dir.length() > 1.0:
		dir = dir.normalized()
	dir = _snap(dir)

	_dash_cd = maxf(0.0, _dash_cd - delta)
	if _want_dash:
		_want_dash = false
		_start_dash(dir if dir != Vector2.ZERO else _facing())

	if _dash_left > 0.0:
		_dash_left = maxf(0.0, _dash_left - delta)
		_velocity = _dash_dir * dash_speed
		if is_zero_approx(_dash_left):
			_velocity = _dash_dir * max_speed
			dash_ended.emit()
	elif dir == Vector2.ZERO:
		_velocity = _velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		_velocity = _velocity.move_toward(dir * max_speed, acceleration * delta)

	var body := o as CharacterBody2D
	if body != null:
		body.velocity = _velocity
		body.move_and_slide()
		_velocity = body.velocity
	else:
		o.global_position += _velocity * delta

	_update_look(o, delta)


## Привести направление к разрешённому числу сторон.
func _snap(v: Vector2) -> Vector2:
	if v == Vector2.ZERO or directions <= 0:
		return v
	var step := TAU / float(directions)
	return Vector2.RIGHT.rotated(roundf(v.angle() / step) * step) * v.length()


func _facing() -> Vector2:
	if _velocity.length_squared() > 1.0:
		return _velocity.normalized()
	var o := object as Node2D
	return Vector2.RIGHT.rotated(o.global_rotation) if o != null else Vector2.RIGHT


func _start_dash(dir: Vector2) -> void:
	if not dash_enabled or _dash_cd > 0.0 or _dash_left > 0.0:
		return
	_dash_dir = dir.normalized()
	_dash_left = dash_time
	_dash_cd = dash_cooldown + dash_time
	dashed.emit()


func _update_look(o: Node2D, delta: float) -> void:
	if rotate_object and _velocity.length_squared() > 1.0:
		var target := _velocity.angle()
		if rotation_speed <= 0.0:
			o.global_rotation = target
		else:
			o.global_rotation = rotate_toward(o.global_rotation, target, rotation_speed * delta)
	if flip_sprite and absf(_velocity.x) > 1.0:
		Gde.set_flip_h(o, _velocity.x < 0.0)
	if animate:
		var anim := run_animation if _velocity.length() > 10.0 else idle_animation
		if not anim.is_empty():
			Gde.auto_animation(o, anim)


## @action Двигаться: _PARAM0_ по X _PARAM1_, по Y _PARAM2_
## @action.en Move: _PARAM0_ by X _PARAM1_, by Y _PARAM2_
## @param x По X
## @param.en x By X
## @param y По Y
## @param.en y By Y
func simulate_move(x: float, y: float) -> void:
	_input += Vector2(x, y)


## @action Остановить _PARAM0_
## @action.en Stop _PARAM0_
func stop() -> void:
	_velocity = Vector2.ZERO
	_dash_left = 0.0


## @action Рывок _PARAM0_ в сторону движения
## @action.en Dash _PARAM0_ toward the movement
func dash() -> void:
	_start_dash(_facing())


## @action Рывок _PARAM0_ под углом _PARAM1_ градусов
## @action.en Dash _PARAM0_ at an angle of _PARAM1_ degrees
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
func dash_at_angle(angle_deg: float) -> void:
	_start_dash(Vector2.RIGHT.rotated(deg_to_rad(angle_deg)))


## @action Толкнуть _PARAM0_ под углом _PARAM1_ с силой _PARAM2_
## @action.en Push _PARAM0_ at angle _PARAM1_ with force _PARAM2_
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
## @param force Сила
## @param.en force Force
func push(angle_deg: float, force: float) -> void:
	_velocity += Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * force


## @condition _PARAM0_ движется
## @condition.en _PARAM0_ is moving
func is_moving() -> bool:
	return _velocity.length_squared() > 1.0


## @condition _PARAM0_ в рывке
## @condition.en _PARAM0_ is dashing
func is_dashing() -> bool:
	return _dash_left > 0.0


## @condition _PARAM0_ может сделать рывок
## @condition.en _PARAM0_ can dash
func can_dash() -> bool:
	return dash_enabled and _dash_cd <= 0.0 and _dash_left <= 0.0


## @expression Текущая скорость
## @expression.en Current speed
func current_speed() -> float:
	return _velocity.length()


## @expression Угол движения в градусах
## @expression.en Movement angle in degrees
func move_angle() -> float:
	return rad_to_deg(_velocity.angle())


## @expression Секунд до следующего рывка
## @expression.en Seconds until the next dash
func dash_cooldown_left() -> float:
	return _dash_cd
