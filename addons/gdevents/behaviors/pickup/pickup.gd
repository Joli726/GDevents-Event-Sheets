## Поведение «Подбираемое».
##
## @behavior Pickup
## @title Подбираемое
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @description Монета, кристалл, аптечка, патроны: покачивается на месте, притягивается магнитом к игроку и при касании сама прибавляет очки, лечит или пополняет магазин. Событий для этого писать не нужно.
## @icon pickup
@tool
extends GdeBehavior

## Подобран. Передаёт того, кто подобрал.
signal collected(by: Node)
## Магнит подхватил предмет и потянул к сборщику.
signal attracted

enum Gives { SCENE_VARIABLE, GLOBAL_VARIABLE, HEALTH, AMMO, NOTHING }

const PRESETS: Array[Dictionary] = [
	{},
	# Монета: мелкая, всегда рядом, копится в переменной сцены.
	{
		"gives": Gives.SCENE_VARIABLE, "variable": "coins", "amount": 1.0,
		"magnet_radius": 60.0, "magnet_speed": 380.0, "bob_height": 3.0,
		"bob_speed": 2.0, "pickup_delay": 0.0,
	},
	# Кристалл: дорогой, тянется издалека, копится между уровнями.
	{
		"gives": Gives.GLOBAL_VARIABLE, "variable": "gems", "amount": 10.0,
		"magnet_radius": 160.0, "magnet_speed": 520.0, "bob_height": 5.0,
		"bob_speed": 1.2, "pickup_delay": 0.0,
	},
	# Аптечка: лечит того, кто взял. Магнита нет — брать надо осознанно.
	{
		"gives": Gives.HEALTH, "variable": "", "amount": 1.0,
		"magnet_radius": 0.0, "magnet_speed": 0.0, "bob_height": 2.0,
		"bob_speed": 1.5, "pickup_delay": 0.0,
	},
	# Патроны из поверженного врага: сначала отлетают, потом притягиваются.
	{
		"gives": Gives.AMMO, "variable": "", "amount": 6.0,
		"magnet_radius": 120.0, "magnet_speed": 450.0, "bob_height": 0.0,
		"bob_speed": 0.0, "pickup_delay": 0.4,
	},
]

@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
@export_enum("Свои настройки", "Монета", "Кристалл", "Аптечка", "Патроны")
var preset: int = 1
## Поставьте галочку, чтобы записать выбранный пресет в настройки ниже.
## Галочка тут же снимается: это кнопка, а не переключатель.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

@export_group("Кто подбирает")
## Сборщик — имя объекта из листа событий, например Player.
@export var collector: String = "Player"
## Подбор включён.
@export var active: bool = true
## Задержка подбора — сколько секунд после появления предмет нельзя взять.
## Нужна выпавшему из врага: иначе он исчезнет, не успев показаться.
@export_range(0.0, 5.0, 0.05) var pickup_delay: float = 0.0

@export_group("Что даёт")
## Что даёт предмет — очки в переменную, здоровье или патроны сборщику.
@export_enum("Переменная сцены", "Глобальная переменная", "Здоровье", "Патроны", "Ничего")
var gives: int = Gives.SCENE_VARIABLE
## Имя переменной — куда прибавлять, например coins.
@export var variable: String = "coins"
## Сколько даёт — прибавка к переменной, здоровью или патронам.
@export_range(-1000.0, 1000.0, 0.5) var amount: float = 1.0

@export_group("Магнит")
## Радиус магнита — с какого расстояния предмет летит к сборщику. 0 — магнита нет.
@export_range(0.0, 1000.0, 5.0) var magnet_radius: float = 60.0
## Скорость полёта к сборщику, пикселей в секунду.
@export_range(0.0, 3000.0, 10.0) var magnet_speed: float = 380.0

@export_group("Вид")
## Высота покачивания на месте, в пикселях. 0 — стоит неподвижно.
@export_range(0.0, 40.0, 0.5) var bob_height: float = 3.0
## Частота покачивания, раз в секунду.
@export_range(0.0, 10.0, 0.1) var bob_speed: float = 2.0
## Эффект подбора — сжаться и раствориться, а не пропасть мгновенно.
@export var collect_effect: bool = true
## Звук подбора — путь к файлу.
@export_file("*.ogg", "*.wav", "*.mp3") var collect_sound: String = ""

var _age: float = 0.0
var _bob_t: float = 0.0
var _flying: bool = false
var _speed_now: float = 0.0
var _done: bool = false
var _collect_frame: int = -10


func _process(delta: float) -> void:
	var o := Gde.main(object)
	if o == null or _done:
		return
	_age += delta

	var who := _nearest_collector(o)
	var d := INF if who == null else o.global_position.distance_to(Gde.pos_of(who))

	if active and who != null and magnet_radius > 0.0 and d <= magnet_radius \
			and _age >= pickup_delay:
		if not _flying:
			_flying = true
			attracted.emit()
		# Разгоняемся, а не прыгаем: предмет «срывается» с места, как в играх.
		_speed_now = move_toward(_speed_now, magnet_speed, magnet_speed * 3.0 * delta)
		o.global_position = o.global_position.move_toward(Gde.pos_of(who), _speed_now * delta)
	elif bob_height > 0.0 and bob_speed > 0.0 and not _flying:
		# Покачивание приращением, а не от «базы»: так оно не спорит с тем,
		# что двигает предмет само (например, выпавший предмет падает).
		var before := sin(_bob_t * TAU)
		_bob_t += delta * bob_speed
		o.global_position.y += (sin(_bob_t * TAU) - before) * bob_height

	if active and who != null and _age >= pickup_delay and Gde.overlaps(object, who):
		_collect(who)


func _nearest_collector(o: Node2D) -> Node:
	if collector.is_empty():
		return null
	var best: Node = null
	var best_d := INF
	for n: Node in Gde.all_instances(collector):
		if not is_instance_valid(n):
			continue
		var dd := o.global_position.distance_squared_to(Gde.pos_of(n))
		if dd < best_d:
			best_d = dd
			best = n
	return best


func _collect(who: Node) -> void:
	_done = true
	_collect_frame = Engine.get_process_frames()
	match gives:
		Gives.SCENE_VARIABLE:
			if not variable.is_empty():
				Gde.var_set(variable, float(Gde.var_get(variable, 0.0)) + amount)
		Gives.GLOBAL_VARIABLE:
			if not variable.is_empty():
				Gde.gvar_set(variable, float(Gde.gvar_get(variable, 0.0)) + amount)
		Gives.HEALTH:
			Gde.beh_call(who, "Health", "heal", [amount])
		Gives.AMMO:
			Gde.beh_call(who, "Shoot", "add_ammo", [amount])
	if not collect_sound.is_empty():
		Gde.play_sound(collect_sound, 0.0, randf_range(0.95, 1.1))
	collected.emit(who)

	var o := object as CanvasItem
	if collect_effect and o != null:
		var t := o.create_tween().set_parallel(true)
		t.tween_property(o, "scale", Vector2.ZERO, 0.15)
		t.tween_property(o, "modulate:a", 0.0, 0.15)
		t.chain().tween_callback(func(): Gde.delete_object(object))
	else:
		Gde.delete_object(object)


## @action Задать сборщика для _PARAM0_: объект _PARAM1_
func set_collector(name: String) -> void:
	collector = name


## @action Отдать _PARAM0_ сборщику немедленно
func give_now() -> void:
	var o := Gde.main(object)
	if o == null or _done:
		return
	var who := _nearest_collector(o)
	if who != null:
		_collect(who)


## @action Запретить подбирать _PARAM0_ ещё _PARAM1_ секунд
func block_for(seconds: float) -> void:
	_age = minf(_age, pickup_delay - maxf(0.0, seconds))


## @condition _PARAM0_ только что подобран
func just_collected() -> bool:
	return Engine.get_process_frames() - _collect_frame <= RECENT_FRAMES


## @condition _PARAM0_ летит к сборщику
func is_flying() -> bool:
	return _flying and not _done


## @condition _PARAM0_ уже можно подобрать
func is_ready() -> bool:
	return active and _age >= pickup_delay and not _done


## @expression Расстояние до ближайшего сборщика
func distance_to_collector() -> float:
	var o := Gde.main(object)
	if o == null:
		return -1.0
	var who := _nearest_collector(o)
	return o.global_position.distance_to(Gde.pos_of(who)) if who != null else -1.0
