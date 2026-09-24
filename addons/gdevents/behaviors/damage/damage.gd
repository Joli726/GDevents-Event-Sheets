## Поведение «Урон при касании».
##
## @behavior Damage
## @title Урон при касании
## @needs Area2D Область урона
## @needs CollisionShape2D Форма
## @description Снимает здоровье тому, кого задел: шипы, пуля, огонь, враг. С перезарядкой по каждой жертве, отбросом, пробитием нескольких целей и самоуничтожением после удара.
## @icon damage
@tool
extends GdeBehavior

## Попал по кому-то. Передаёт жертву.
signal hit(victim: Node)
## Попадания кончились — объект отработал своё.
signal spent

const PRESETS: Array[Dictionary] = [
	{},
	# Шипы: бьют постоянно, пока стоишь на них, и никуда не деваются.
	{
		"amount": 1.0, "repeat_delay": 0.7, "pierce": 0, "destroy_on_hit": false,
		"knockback": 90.0, "pierce_invulnerability": false,
	},
	# Пуля: один удар и исчезает.
	{
		"amount": 1.0, "repeat_delay": 0.0, "pierce": 1, "destroy_on_hit": true,
		"knockback": 0.0, "pierce_invulnerability": false,
	},
	# Пробивающий снаряд: проходит сквозь троих.
	{
		"amount": 2.0, "repeat_delay": 0.2, "pierce": 3, "destroy_on_hit": true,
		"knockback": 40.0, "pierce_invulnerability": false,
	},
	# Яд: слабо, часто и сквозь неуязвимость.
	{
		"amount": 0.5, "repeat_delay": 0.3, "pierce": 0, "destroy_on_hit": false,
		"knockback": 0.0, "pierce_invulnerability": true,
	},
]

@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
@export_enum("Свои настройки", "Шипы", "Пуля", "Пробивающий снаряд", "Яд")
var preset: int = 1
## Поставьте галочку, чтобы записать выбранный пресет в настройки ниже.
## Галочка тут же снимается: это кнопка, а не переключатель.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

@export_group("Кого бить")
## Жертва — имя объекта из листа событий, например Player.
## Пусто — не бьёт никого: цель задаётся действием из событий.
@export var target_object: String = ""
## Урон за одно попадание.
@export_range(0.0, 1000.0, 0.5) var amount: float = 1.0
## Урон включён.
@export var active: bool = true

@export_group("Как часто")
## Перезарядка по каждой жертве — сколько секунд не бить её повторно.
## 0 — бить каждый кадр, пока касается.
@export_range(0.0, 10.0, 0.05) var repeat_delay: float = 0.5
## Пробитие — сколько всего попаданий выдержит объект. 0 — сколько угодно.
@export_range(0, 50, 1) var pierce: int = 0
## Задержка после создания — сколько секунд не бить никого.
## Спасает снаряд от удара по тому, кто его выпустил.
@export_range(0.0, 5.0, 0.05) var arm_time: float = 0.05

@export_group("Что при ударе")
## Самоуничтожение — исчезнуть после удара. Если пробитие больше 1 — после последнего попадания.
@export var destroy_on_hit: bool = false
## Отброс жертвы прочь от себя, пикселей за удар.
@export_range(0.0, 1000.0, 5.0) var knockback: float = 0.0
## Урон сквозь неуязвимость — не даёт жертве отсидеться после первого удара.
@export var pierce_invulnerability: bool = false
## Звук удара — путь к файлу.
@export_file("*.ogg", "*.wav", "*.mp3") var hit_sound: String = ""

var _cooldowns: Dictionary = {}
var _hits: int = 0
var _age: float = 0.0
var _hit_frame: int = -10
var _spent: bool = false


func _physics_process(delta: float) -> void:
	_age += delta
	for id: int in _cooldowns.keys():
		var left := float(_cooldowns[id]) - delta
		if left <= 0.0:
			_cooldowns.erase(id)
		else:
			_cooldowns[id] = left

	if not active or _spent or target_object.is_empty() or _age < arm_time:
		return
	var o := object
	if o == null:
		return
	for victim: Node in Gde.all_instances(target_object):
		if not is_instance_valid(victim) or _is_self(victim):
			continue
		if _cooldowns.has(victim.get_instance_id()):
			continue
		if Gde.overlaps(o, victim):
			_strike(victim)
			if _spent:
				return


## Своё же дерево бить нельзя: область урона часто висит на том же объекте,
## что и жертва (например, враг с шипами внутри группы врагов).
func _is_self(victim: Node) -> bool:
	var root := object
	return victim == root or (root != null and root.is_ancestor_of(victim)) \
			or (victim != null and victim.is_ancestor_of(root))


func _strike(victim: Node) -> void:
	if pierce_invulnerability:
		Gde.beh_call(victim, "Health", "damage_pierce", [amount])
	else:
		Gde.beh_call(victim, "Health", "damage", [amount])
	if knockback > 0.0:
		Gde.knockback(victim, object, knockback)
	if not hit_sound.is_empty():
		Gde.play_sound(hit_sound, 0.0, randf_range(0.92, 1.08))

	_cooldowns[victim.get_instance_id()] = repeat_delay
	_hits += 1
	_hit_frame = Engine.get_physics_frames()
	hit.emit(victim)

	var used_up := pierce > 0 and _hits >= pierce
	var dies := destroy_on_hit and (pierce <= 1 or used_up)
	if used_up or dies:
		_spent = true
		spent.emit()
	if dies:
		Gde.delete_object(object)


## @action Задать жертву для _PARAM0_: объект _PARAM1_
func target(name: String) -> void:
	target_object = name


## @action Включить урон у _PARAM0_
func arm() -> void:
	active = true
	_spent = false
	_hits = 0
	_age = 0.0


## @action Выключить урон у _PARAM0_
func disarm() -> void:
	active = false


## @action Сбросить перезарядку урона у _PARAM0_ — можно бить снова
func reset_cooldowns() -> void:
	_cooldowns.clear()


## @condition _PARAM0_ только что нанёс урон
func just_hit() -> bool:
	return Engine.get_physics_frames() - _hit_frame <= RECENT_FRAMES


## @condition У _PARAM0_ кончились попадания
func is_spent() -> bool:
	return _spent


## @condition Урон у _PARAM0_ включён
func is_active() -> bool:
	return active and not _spent


## @expression Сколько раз объект уже попал
func hits_done() -> float:
	return float(_hits)


## @expression Сколько попаданий осталось
func hits_left() -> float:
	return INF if pierce <= 0 else float(maxi(0, pierce - _hits))
