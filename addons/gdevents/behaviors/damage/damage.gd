## Поведение «Урон при касании».
##
## @behavior Damage
## @title Урон при касании
## @title.en Contact damage
## @needs Area2D Область урона
## @needs.en Area2D Damage area
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @description Снимает здоровье тому, кого задел: шипы, пуля, огонь, враг. С перезарядкой по каждой жертве, отбросом, пробитием нескольких целей и самоуничтожением после удара.
## @description.en Takes health from whoever it touches: spikes, a bullet, fire, an enemy. With a per-victim cooldown, knockback, piercing several targets and self-destruction after a hit.
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

## @group.en Preset
@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
## @en A ready-made set of settings. It changes nothing by itself — press the checkbox below.
## @options.en Custom, Spikes, Bullet, Piercing projectile, Poison
@export_enum("Свои настройки", "Шипы", "Пуля", "Пробивающий снаряд", "Яд")
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

## @group.en Whom to hit
@export_group("Кого бить")
## Жертва — имя объекта из листа событий, например Player.
## Пусто — не бьёт никого: цель задаётся действием из событий.
## @en Victim — the name of an object from the event sheet, e.g. Player. Empty — hits no one: the target is set by an action from events.
@export var target_object: String = ""
## Урон за одно попадание.
## @en Damage per hit.
@export_range(0.0, 1000.0, 0.5) var amount: float = 1.0
## Урон включён.
## @en Damage is on.
@export var active: bool = true

## @group.en How often
@export_group("Как часто")
## Перезарядка по каждой жертве — сколько секунд не бить её повторно.
## 0 — бить каждый кадр, пока касается.
## @en Cooldown per victim — how many seconds not to hit it again. 0 — hit every frame while touching.
@export_range(0.0, 10.0, 0.05) var repeat_delay: float = 0.5
## Пробитие — сколько всего попаданий выдержит объект. 0 — сколько угодно.
## @en Piercing — how many hits in total the object survives. 0 — any number.
@export_range(0, 50, 1) var pierce: int = 0
## Задержка после создания — сколько секунд не бить никого.
## Спасает снаряд от удара по тому, кто его выпустил.
## @en Arming delay — how many seconds after creation not to hit anyone. Keeps a projectile from hitting whoever fired it.
@export_range(0.0, 5.0, 0.05) var arm_time: float = 0.05

## @group.en What happens on a hit
@export_group("Что при ударе")
## Самоуничтожение — исчезнуть после удара. Если пробитие больше 1 — после последнего попадания.
## @en Self-destruct — disappear after a hit. If piercing is above 1 — after the last hit.
@export var destroy_on_hit: bool = false
## Отброс жертвы прочь от себя, пикселей за удар.
## @en Knockback of the victim away from itself, pixels per hit.
@export_range(0.0, 1000.0, 5.0) var knockback: float = 0.0
## Урон сквозь неуязвимость — не даёт жертве отсидеться после первого удара.
## @en Damage through invulnerability — does not let the victim wait it out after the first hit.
@export var pierce_invulnerability: bool = false
## Звук удара — путь к файлу.
## @en Hit sound — a path to the file.
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
## @action.en Set the victim of _PARAM0_: object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func target(name: String) -> void:
	target_object = name


## @action Включить урон у _PARAM0_
## @action.en Turn damage on for _PARAM0_
func arm() -> void:
	active = true
	_spent = false
	_hits = 0
	_age = 0.0


## @action Выключить урон у _PARAM0_
## @action.en Turn damage off for _PARAM0_
func disarm() -> void:
	active = false


## @action Сбросить перезарядку урона у _PARAM0_ — можно бить снова
## @action.en Reset the damage cooldown of _PARAM0_ — it can hit again
func reset_cooldowns() -> void:
	_cooldowns.clear()


## @condition _PARAM0_ только что нанёс урон
## @condition.en _PARAM0_ has just dealt damage
func just_hit() -> bool:
	return Engine.get_physics_frames() - _hit_frame <= RECENT_FRAMES


## @condition У _PARAM0_ кончились попадания
## @condition.en _PARAM0_ has run out of hits
func is_spent() -> bool:
	return _spent


## @condition Урон у _PARAM0_ включён
## @condition.en Damage of _PARAM0_ is on
func is_active() -> bool:
	return active and not _spent


## @expression Сколько раз объект уже попал
## @expression.en How many times the object has already hit
func hits_done() -> float:
	return float(_hits)


## @expression Сколько попаданий осталось
## @expression.en How many hits are left
func hits_left() -> float:
	return INF if pierce <= 0 else float(maxi(0, pierce - _hits))
