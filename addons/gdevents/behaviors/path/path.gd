## Поведение «Путь».
##
## @behavior Path
## @title Путь по точкам
## @title.en Path by points
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Движение по точкам: патруль, кольцо, туда-обратно. С ожиданием на точках, разгоном, поворотом по направлению и переходом к любой точке из событий.
## @description.en Movement along points: patrol, loop, back and forth. With waiting at points, acceleration, turning toward the direction and going to any point from events.
## @icon path
@tool
extends GdeBehavior

## Дошёл до точки. Номер — с нуля.
signal reached_point(index: int)
## Прошёл весь путь. Для «один раз» — в конце, для кольца — на каждом круге.
signal path_finished

const PRESETS: Array[Dictionary] = [
	{},
	# Патруль влево-вправо — самый частый враг платформера.
	{
		"points": [Vector2(0, 0), Vector2(160, 0)],
		"mode": 1, "speed": 60.0, "wait_time": 0.4, "flip_sprite": true,
		"rotate_object": false,
	},
	# Лифт вверх-вниз.
	{
		"points": [Vector2(0, 0), Vector2(0, -140)],
		"mode": 1, "speed": 50.0, "wait_time": 1.0, "flip_sprite": false,
		"rotate_object": false,
	},
	# Квадрат по часовой — облёт комнаты.
	{
		"points": [
			Vector2(0, 0), Vector2(140, 0), Vector2(140, 140), Vector2(0, 140)],
		"mode": 0, "speed": 90.0, "wait_time": 0.0, "flip_sprite": true,
		"rotate_object": false,
	},
	# Заход на цель и обратно — снаряд-бумеранг.
	{
		"points": [Vector2(0, 0), Vector2(260, -60)],
		"mode": 2, "speed": 220.0, "wait_time": 0.0, "flip_sprite": false,
		"rotate_object": true,
	},
]

## @group.en Preset
@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
## @en A ready-made set of settings. It changes nothing by itself — press the checkbox below.
## @options.en Custom, Patrol left-right, Elevator, Square, There and back
@export_enum("Свои настройки", "Патруль влево-вправо", "Лифт", "Квадрат", "Туда и обратно")
var preset: int = 1
## Поставьте галочку, чтобы записать выбранный пресет в настройки ниже.
## Галочка тут же снимается: это кнопка, а не переключатель.
## @en Check the box to write the selected preset into the settings below. The box unchecks itself right away: it is a button, not a switch.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			# В const нельзя положить PackedVector2Array — точки пресетов
			# хранятся обычным массивом и переводятся здесь.
			var values: Dictionary = PRESETS[preset].duplicate()
			values["points"] = PackedVector2Array(values["points"])
			apply_values(values)

## @group.en Points
@export_group("Точки")
## Точки пути — смещения от места, где объект стоял на старте.
## Первая точка обычно (0, 0): это и есть исходное место.
## @en Path points — offsets from where the object stood at start. The first point is usually (0, 0): that is the starting place itself.
@export var points: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(160, 0)])
## Как проходить путь: кольцом, туда-обратно или один раз до конца.
## @en How to go along the path: in a loop, back and forth, or once to the end.
## @options.en Loop, Back and forth, Once
@export_enum("Кольцом", "Туда-обратно", "Один раз") var mode: int = 0
## Ожидание на каждой точке, секунд.
## @en Wait at each point, seconds.
@export_range(0.0, 10.0, 0.05) var wait_time: float = 0.0
## Насколько близко считать, что точка достигнута, в пикселях.
## @en How close counts as reaching a point, in pixels.
@export_range(1.0, 100.0, 1.0) var reach_distance: float = 4.0

## @group.en Movement
@export_group("Движение")
## Скорость движения, пикселей в секунду.
## @en Movement speed, pixels per second.
@export_range(0.0, 2000.0, 5.0) var speed: float = 80.0
## Разгон, пикселей в секунду за секунду. 0 — мгновенный старт.
## @en Acceleration, pixels per second per second. 0 — instant start.
@export_range(0.0, 10000.0, 10.0) var acceleration: float = 0.0
## Движение включено.
## @en Movement is on.
@export var running: bool = true

## @group.en Look
@export_group("Вид")
## Поворот объекта по направлению движения.
## @en Rotate the object — toward the movement direction.
@export var rotate_object: bool = false
## Отражение спрайта по направлению движения.
## @en Flip the sprite — toward the movement direction.
@export var flip_sprite: bool = false

var _origin: Vector2 = Vector2.ZERO
var _has_origin: bool = false
var _index: int = 0
var _dir: int = 1
var _wait: float = 0.0
var _vel: Vector2 = Vector2.ZERO
var _reach_frame: int = -10
var _done: bool = false


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null or points.size() < 2:
		return
	if not _has_origin:
		# Точки заданы смещениями, поэтому начало пути — то место, где объект
		# стоял при запуске. Так один и тот же путь можно повесить на сцену
		# в нескольких экземплярах, и каждый пойдёт от своего места.
		_origin = o.global_position
		_has_origin = true
	if not running or _done:
		return

	if _wait > 0.0:
		_wait = maxf(0.0, _wait - delta)
		_vel = Vector2.ZERO
		return

	var target := _origin + points[_index]
	var to := target - o.global_position
	if to.length() <= reach_distance:
		_arrive(o)
		return

	var want := to.normalized() * speed
	if acceleration <= 0.0:
		_vel = want
	else:
		_vel = _vel.move_toward(want, acceleration * delta)
	o.global_position += _vel * delta
	_look(o)


func _arrive(o: Node2D) -> void:
	o.global_position = _origin + points[_index]
	_vel = Vector2.ZERO
	_reach_frame = Engine.get_process_frames()
	reached_point.emit(_index)
	_wait = wait_time
	_advance()


## Следующая точка с учётом того, как проходится путь.
func _advance() -> void:
	var last := points.size() - 1
	match mode:
		1:
			# Туда-обратно: на краях разворачиваемся, а не прыгаем в начало.
			if _index >= last and _dir > 0:
				_dir = -1
				path_finished.emit()
			elif _index <= 0 and _dir < 0:
				_dir = 1
				path_finished.emit()
			_index = clampi(_index + _dir, 0, last)
		2:
			if _index >= last:
				_done = true
				path_finished.emit()
			else:
				_index += 1
		_:
			if _index >= last:
				_index = 0
				path_finished.emit()
			else:
				_index += 1


func _look(o: Node2D) -> void:
	if _vel.length_squared() < 1.0:
		return
	if rotate_object:
		o.global_rotation = _vel.angle()
	if flip_sprite and absf(_vel.x) > 1.0:
		Gde.set_flip_h(o, _vel.x < 0.0)


## @action Отправить _PARAM0_ к точке пути номер _PARAM1_
## @action.en Send _PARAM0_ to path point number _PARAM1_
## @param index Номер точки
## @param.en index Point number
func go_to_point(index: float) -> void:
	if points.size() < 2:
		return
	_index = clampi(int(index), 0, points.size() - 1)
	_wait = 0.0
	_done = false


## @action Запустить движение _PARAM0_ по пути
## @action.en Start the path movement of _PARAM0_
func start() -> void:
	running = true
	_done = false


## @action Остановить движение _PARAM0_ по пути
## @action.en Stop the path movement of _PARAM0_
func stop() -> void:
	running = false
	_vel = Vector2.ZERO


## @action Развернуть _PARAM0_ на пути в обратную сторону
## @action.en Reverse _PARAM0_ on the path
func reverse() -> void:
	_dir = -_dir
	if mode != 1:
		# Для кольца и «один раз» разворот — это просто шаг назад:
		# иначе объект застрял бы, дойдя до края.
		_index = clampi(_index - 1, 0, points.size() - 1)


## @action Вернуть _PARAM0_ в начало пути
## @action.en Return _PARAM0_ to the start of the path
func restart() -> void:
	_index = 0
	_dir = 1
	_wait = 0.0
	_done = false


## @action Считать текущее место _PARAM0_ началом пути
## @action.en Treat the current place of _PARAM0_ as the start of the path
func rebase() -> void:
	var o := object as Node2D
	if o != null:
		_origin = o.global_position
		_has_origin = true


## @condition _PARAM0_ идёт по пути
## @condition.en _PARAM0_ is moving along the path
func is_moving() -> bool:
	return running and not _done and _wait <= 0.0 and _vel.length_squared() > 1.0


## @condition _PARAM0_ ждёт на точке
## @condition.en _PARAM0_ is waiting at a point
func is_waiting() -> bool:
	return _wait > 0.0


## @condition _PARAM0_ только что дошёл до точки
## @condition.en _PARAM0_ has just reached a point
func just_reached() -> bool:
	return Engine.get_process_frames() - _reach_frame <= RECENT_FRAMES


## @condition _PARAM0_ прошёл весь путь до конца
## @condition.en _PARAM0_ has gone the whole path to the end
func is_finished() -> bool:
	return _done


## @expression Номер точки, к которой идёт объект
## @expression.en Number of the point the object is heading to
func current_point() -> float:
	return float(_index)


## @expression Сколько точек в пути
## @expression.en How many points are in the path
func point_count() -> float:
	return float(points.size())


## @expression Расстояние до следующей точки
## @expression.en Distance to the next point
func distance_to_point() -> float:
	var o := object as Node2D
	if o == null or points.size() < 2:
		return 0.0
	return o.global_position.distance_to(_origin + points[_index])
