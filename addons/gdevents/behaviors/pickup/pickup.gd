## Поведение «Подбираемое».
##
## @behavior Pickup
## @title Подбираемое
## @title.en Pickup
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Монета, кристалл, аптечка, патроны: покачивается на месте, притягивается магнитом к игроку и при касании сама прибавляет очки, лечит или пополняет магазин. Событий для этого писать не нужно.
## @description.en A coin, a crystal, a medkit, ammo: it bobs in place, is pulled to the player by a magnet and on touch adds points, heals or refills the magazine by itself. No events are needed for that.
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

## @group.en Preset
@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
## @en A ready-made set of settings. It changes nothing by itself — press the checkbox below.
## @options.en Custom, Coin, Crystal, Medkit, Ammo
@export_enum("Свои настройки", "Монета", "Кристалл", "Аптечка", "Патроны")
var preset: int = 1
## Поставьте галочку, чтобы записать выбранный пресет в настройки ниже.
## Галочка тут же снимается: это кнопка, а не переключатель.
## @en Check the box to write the selected preset into the settings below. The box unchecks itself right away: it is a button, not a switch.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

## @group.en Who picks up
@export_group("Кто подбирает")
## Сборщик — имя объекта из листа событий, например Player.
## @en Collector — the name of an object from the event sheet, e.g. Player.
@export var collector: String = "Player"
## Подбор включён.
## @en Picking up is on.
@export var active: bool = true
## Задержка подбора — сколько секунд после появления предмет нельзя взять.
## Нужна выпавшему из врага: иначе он исчезнет, не успев показаться.
## @en Pickup delay — how many seconds after appearing the item cannot be taken. Needed for a drop from an enemy: otherwise it vanishes before it is even seen.
@export_range(0.0, 5.0, 0.05) var pickup_delay: float = 0.0

## @group.en What it gives
@export_group("Что даёт")
## Что даёт предмет — очки в переменную, здоровье или патроны сборщику.
## @en What the item gives — points to a variable, health or ammo to the collector.
## @options.en Scene variable, Global variable, Health, Ammo, Nothing
@export_enum("Переменная сцены", "Глобальная переменная", "Здоровье", "Патроны", "Ничего")
var gives: int = Gives.SCENE_VARIABLE
## Имя переменной — куда прибавлять, например coins.
## @en Variable name — where to add, e.g. coins.
@export var variable: String = "coins"
## Сколько даёт — прибавка к переменной, здоровью или патронам.
## @en How much it gives — added to the variable, health or ammo.
@export_range(-1000.0, 1000.0, 0.5) var amount: float = 1.0

## @group.en Magnet
@export_group("Магнит")
## Радиус магнита — с какого расстояния предмет летит к сборщику. 0 — магнита нет.
## @en Magnet radius — from what distance the item flies to the collector. 0 — no magnet.
@export_range(0.0, 1000.0, 5.0) var magnet_radius: float = 60.0
## Скорость полёта к сборщику, пикселей в секунду.
## @en Flight speed to the collector, pixels per second.
@export_range(0.0, 3000.0, 10.0) var magnet_speed: float = 380.0

## @group.en Look
@export_group("Вид")
## Высота покачивания на месте, в пикселях. 0 — стоит неподвижно.
## @en Bobbing height in place, in pixels. 0 — stands still.
@export_range(0.0, 40.0, 0.5) var bob_height: float = 3.0
## Частота покачивания, раз в секунду.
## @en Bobbing rate, times per second.
@export_range(0.0, 10.0, 0.1) var bob_speed: float = 2.0
## Эффект подбора — сжаться и раствориться, а не пропасть мгновенно.
## @en Pickup effect — shrink and fade instead of vanishing instantly.
@export var collect_effect: bool = true
## Звук подбора — путь к файлу.
## @en Pickup sound — a path to the file.
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
## @action.en Set the collector of _PARAM0_: object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func set_collector(name: String) -> void:
	collector = name


## @action Отдать _PARAM0_ сборщику немедленно
## @action.en Give _PARAM0_ to the collector right away
func give_now() -> void:
	var o := Gde.main(object)
	if o == null or _done:
		return
	var who := _nearest_collector(o)
	if who != null:
		_collect(who)


## @action Запретить подбирать _PARAM0_ ещё _PARAM1_ секунд
## @action.en Forbid picking up _PARAM0_ for another _PARAM1_ seconds
## @param seconds Секунд
## @param.en seconds Seconds
func block_for(seconds: float) -> void:
	_age = minf(_age, pickup_delay - maxf(0.0, seconds))


## @condition _PARAM0_ только что подобран
## @condition.en _PARAM0_ has just been picked up
func just_collected() -> bool:
	return Engine.get_process_frames() - _collect_frame <= RECENT_FRAMES


## @condition _PARAM0_ летит к сборщику
## @condition.en _PARAM0_ is flying to the collector
func is_flying() -> bool:
	return _flying and not _done


## @condition _PARAM0_ уже можно подобрать
## @condition.en _PARAM0_ can already be picked up
func is_ready() -> bool:
	return active and _age >= pickup_delay and not _done


## @expression Расстояние до ближайшего сборщика
## @expression.en Distance to the nearest collector
func distance_to_collector() -> float:
	var o := Gde.main(object)
	if o == null:
		return -1.0
	var who := _nearest_collector(o)
	return o.global_position.distance_to(Gde.pos_of(who)) if who != null else -1.0
