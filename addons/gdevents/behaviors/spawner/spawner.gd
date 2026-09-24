## Поведение «Появление».
##
## @behavior Spawner
## @title Появление объектов
## @description Точка, из которой сами выходят объекты: волны врагов, дождь монет, фонтан искр. С интервалом и разбросом, пачками, с пределом всего и пределом живых одновременно.
## @icon spawn
@tool
extends GdeBehavior

## Выпустил объект. Передаёт созданный экземпляр.
signal spawned(instance: Node)
## Выпущено всё, что было задано пределом.
signal finished

const PRESETS: Array[Dictionary] = [
	{},
	# Волна врагов: не больше пяти на экране, всего десять.
	{
		"interval": 1.5, "interval_jitter": 0.3, "first_delay": 1.0, "per_spawn": 1,
		"total_limit": 10, "alive_limit": 5, "radius": 0.0,
	},
	# Дождь монет: часто, широко, бесконечно.
	{
		"interval": 0.3, "interval_jitter": 0.2, "first_delay": 0.0, "per_spawn": 1,
		"total_limit": 0, "alive_limit": 30, "radius": 220.0,
	},
	# Босс: один раз, после паузы.
	{
		"interval": 1.0, "interval_jitter": 0.0, "first_delay": 2.0, "per_spawn": 1,
		"total_limit": 1, "alive_limit": 0, "radius": 0.0,
	},
	# Фонтан: пачки по три, почти без паузы.
	{
		"interval": 0.08, "interval_jitter": 0.0, "first_delay": 0.0, "per_spawn": 3,
		"total_limit": 0, "alive_limit": 60, "radius": 12.0,
	},
]

@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
@export_enum("Свои настройки", "Волна врагов", "Дождь монет", "Босс", "Фонтан")
var preset: int = 1
## Поставьте галочку, чтобы записать выбранный пресет в настройки ниже.
## Галочка тут же снимается: это кнопка, а не переключатель.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

@export_group("Что выпускать")
## Объект — имя из листа событий, например Enemy.
@export var target_object: String = ""
## Работа включена.
@export var running: bool = true

@export_group("Когда")
## Интервал между выпусками, секунд.
@export_range(0.02, 60.0, 0.01) var interval: float = 1.5
## Разброс интервала, секунд: ±столько к каждому ожиданию, чтобы ритм не был механическим.
@export_range(0.0, 10.0, 0.01) var interval_jitter: float = 0.0
## Первая задержка — сколько секунд подождать после старта.
@export_range(0.0, 60.0, 0.05) var first_delay: float = 0.0

@export_group("Сколько")
## Пачка — сколько объектов за один выпуск.
@export_range(1, 50, 1) var per_spawn: int = 1
## Предел всего — сколько выпустить за всё время. 0 — без конца.
@export_range(0, 1000, 1) var total_limit: int = 0
## Предел живых — больше стольких одновременно не будет. 0 — без предела.
@export_range(0, 500, 1) var alive_limit: int = 0

@export_group("Где")
## Разброс места, в пикселях: объект появляется в случайной точке круга.
@export_range(0.0, 2000.0, 1.0) var radius: float = 0.0
## Смещение по X от точки появления.
@export_range(-2000.0, 2000.0, 1.0) var offset_x: float = 0.0
## Смещение по Y от точки появления.
@export_range(-2000.0, 2000.0, 1.0) var offset_y: float = 0.0

var _wait: float = -1.0
var _total: int = 0
var _alive: Array[Node] = []
var _spawn_frame: int = -10
var _finished: bool = false


func _process(delta: float) -> void:
	if not running or _finished or target_object.is_empty():
		return
	if _wait < 0.0:
		_wait = first_delay
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = maxf(0.02, interval + randf_range(-interval_jitter, interval_jitter))
	spawn_now(per_spawn)


func _prune() -> void:
	var keep: Array[Node] = []
	for n: Node in _alive:
		if is_instance_valid(n) and n.is_inside_tree() and not n.is_queued_for_deletion():
			keep.append(n)
	_alive = keep


## @action Выпустить из _PARAM0_ сейчас: _PARAM1_ шт.
func spawn_now(count: float) -> void:
	var o := Gde.main(object)
	if o == null or target_object.is_empty():
		return
	_prune()
	var level := get_tree().current_scene
	if level == null or not level.is_ancestor_of(o):
		level = o.get_parent()
	for _i in range(maxi(1, int(count))):
		if total_limit > 0 and _total >= total_limit:
			break
		if alive_limit > 0 and _alive.size() >= alive_limit:
			break
		var at := o.global_position + Vector2(offset_x, offset_y)
		if radius > 0.0:
			# Равномерно по площади круга, а не гуще к центру.
			at += Vector2.RIGHT.rotated(randf() * TAU) * radius * sqrt(randf())
		var n := Gde.create_object(null, target_object, at.x, at.y, level)
		if n == null:
			running = false
			return
		_alive.append(n)
		_total += 1
		_spawn_frame = Engine.get_process_frames()
		spawned.emit(n)
	if total_limit > 0 and _total >= total_limit and not _finished:
		_finished = true
		finished.emit()


## @action Запустить появление у _PARAM0_
func start() -> void:
	running = true


## @action Остановить появление у _PARAM0_
func stop() -> void:
	running = false


## @action Начать появление у _PARAM0_ заново (счёт с нуля)
func restart() -> void:
	_total = 0
	_finished = false
	_wait = first_delay
	running = true


## @action Выпускать из _PARAM0_ объект _PARAM1_
func set_object(name: String) -> void:
	target_object = name


## @condition _PARAM0_ только что выпустил объект
func just_spawned() -> bool:
	return Engine.get_process_frames() - _spawn_frame <= RECENT_FRAMES


## @condition _PARAM0_ выпустил всё, что было задано
func is_finished() -> bool:
	return _finished


## @condition Все выпущенные из _PARAM0_ уже уничтожены
func all_dead() -> bool:
	_prune()
	return _total > 0 and _alive.is_empty()


## @expression Сколько выпущено всего
func spawned_total() -> float:
	return float(_total)


## @expression Сколько выпущенных сейчас живы
func alive_count() -> float:
	_prune()
	return float(_alive.size())


## @expression Секунд до следующего выпуска
func time_left() -> float:
	return maxf(0.0, _wait)
