## Поведение «Здоровье».
##
## @behavior Health
## @title Здоровье
## @title.en Health
## @description Здоровье с бронёй, неуязвимостью после удара, регенерацией, миганием и сценой на смерть.
## @description.en Health with armor, invulnerability after a hit, regeneration, blinking and a death scene.
## @icon health
@tool
extends GdeBehavior

## Получил урон. Передаётся фактически снятое количество.
signal damaged(amount: float)
## Вылечен.
signal healed(amount: float)
## Здоровье кончилось.
signal died

## @group.en Health
@export_group("Здоровье")
## Запас здоровья — с него объект начинает и до него лечится.
## @en Health pool — the object starts with it and heals up to it.
@export_range(1.0, 1000.0, 1.0) var max_health: float = 3.0
## Текущее здоровье. При старте подтягивается к максимуму, если включено ниже.
## @en Current health. At start it is raised to the maximum, if enabled below.
@export_range(0.0, 1000.0, 1.0) var current: float = 3.0
## Полное здоровье при старте, не оглядываясь на поле выше.
## @en Full health at start, regardless of the field above.
@export var start_full: bool = true

## @group.en Protection
@export_group("Защита")
## Броня — сколько урона снимается с каждого удара.
## @en Armor — how much damage is removed from each hit.
@export_range(0.0, 100.0, 0.5) var armor_flat: float = 0.0
## Броня в долях — какая часть урона поглощается, от 0 до 1.
## @en Armor share — what part of the damage is absorbed, from 0 to 1.
@export_range(0.0, 0.95, 0.05) var armor_percent: float = 0.0
## Минимум урона за удар — ниже броня опустить не может.
## @en Minimum damage per hit — armor cannot lower it further.
@export_range(0.0, 10.0, 0.5) var min_damage: float = 1.0
## Неуязвимость после удара, секунд.
## @en Invulnerability after a hit, seconds.
@export_range(0.0, 5.0, 0.05) var invulnerable_time: float = 0.0

## @group.en Regeneration
@export_group("Регенерация")
## Регенерация — единиц здоровья в секунду. 0 — не лечится.
## @en Regeneration — health units per second. 0 — no healing.
@export_range(0.0, 50.0, 0.1) var regen_per_second: float = 0.0
## Задержка регенерации — сколько секунд после урона она молчит.
## @en Regeneration delay — how many seconds it stays silent after damage.
@export_range(0.0, 20.0, 0.1) var regen_delay: float = 3.0

## @group.en Death
@export_group("Смерть")
## Удалять объект при смерти.
## @en Delete the object on death.
@export var destroy_on_death: bool = false
## Задержка перед удалением — время доиграть анимацию смерти.
## @en Delay before deletion — time to finish the death animation.
@export_range(0.0, 10.0, 0.1) var death_delay: float = 0.0
## Что создать на месте гибели: взрыв, дроп, что угодно.
## @en What to create where it died: an explosion, a drop, anything.
@export var death_scene: PackedScene

## @group.en Look
@export_group("Вид")
## Мигание при получении урона.
## @en Blink when taking damage.
@export var blink_on_hit: bool = true
## Частота мигания, раз в секунду.
## @en Blink rate, times per second.
@export_range(1.0, 30.0, 1.0) var blink_speed: float = 12.0
## Анимация урона — имя анимации, которая играет при ударе.
## @en Hurt animation — the name of the animation that plays on a hit.
@export var hurt_animation: String = ""

var _invuln: float = 0.0
var _since_hit: float = 999.0
var _dying: float = -1.0
var _hurt_frame: int = -10
var _death_frame: int = -10
var _base_modulate: Color = Color.WHITE
var _has_base: bool = false
var _started: bool = false


## Заполнить здоровье до максимума при первом обращении — чем бы оно ни было.
## Раньше это делал первый _process, а урон приходит из _physics_process,
## который в первом кадре успевает раньше: удар по объекту, появившемуся
## прямо на шипах, тут же стирался заполнением.
func _ensure_started() -> void:
	if _started:
		return
	_started = true
	if start_full:
		current = max_health


func _process(delta: float) -> void:
	_ensure_started()

	_invuln = maxf(0.0, _invuln - delta)
	_since_hit += delta

	if regen_per_second > 0.0 and current > 0.0 and _since_hit >= regen_delay:
		current = minf(max_health, current + regen_per_second * delta)

	_update_blink()

	if _dying >= 0.0:
		_dying -= delta
		if _dying <= 0.0:
			_dying = -1.0
			Gde.delete_object(object)


func _update_blink() -> void:
	var ci := object as CanvasItem
	if ci == null:
		return
	if not _has_base:
		_base_modulate = ci.modulate
		_has_base = true
	if not blink_on_hit:
		return
	if _invuln > 0.0:
		# Мигание через синус: плавнее, чем просто вкл/выкл.
		var t := sin(Time.get_ticks_msec() * 0.001 * blink_speed * TAU)
		var c := _base_modulate
		c.a = _base_modulate.a * (0.35 if t > 0.0 else 1.0)
		ci.modulate = c
	elif ci.modulate != _base_modulate:
		ci.modulate = _base_modulate


## @action Нанести _PARAM1_ урона объекту _PARAM0_
## @action.en Deal _PARAM1_ damage to _PARAM0_
## @param amount Урон
## @param.en amount Damage
func damage(amount: float) -> void:
	_ensure_started()
	if _invuln > 0.0 or current <= 0.0:
		return
	var raw := absf(amount)
	var dealt := maxf(min_damage, (raw - armor_flat) * (1.0 - armor_percent))
	if dealt <= 0.0:
		return
	current = maxf(0.0, current - dealt)
	_invuln = invulnerable_time
	_since_hit = 0.0
	_hurt_frame = Engine.get_process_frames()
	damaged.emit(dealt)

	if not hurt_animation.is_empty():
		Gde.play_animation(object, hurt_animation)

	if current <= 0.0:
		_die()


## @action Нанести _PARAM1_ урона объекту _PARAM0_ сквозь неуязвимость
## @action.en Deal _PARAM1_ damage to _PARAM0_ through invulnerability
## @param amount Урон
## @param.en amount Damage
func damage_pierce(amount: float) -> void:
	_invuln = 0.0
	damage(amount)


## @action Восстановить _PARAM1_ здоровья объекту _PARAM0_
## @action.en Heal _PARAM0_ by _PARAM1_
## @param amount Здоровье
## @param.en amount Health
func heal(amount: float) -> void:
	_ensure_started()
	if current <= 0.0:
		return
	var before := current
	current = minf(max_health, current + absf(amount))
	healed.emit(current - before)


## @action Полностью восстановить здоровье _PARAM0_
## @action.en Fully heal _PARAM0_
func restore() -> void:
	_ensure_started()
	current = max_health
	_invuln = 0.0
	_dying = -1.0


## @action Убить _PARAM0_ немедленно
## @action.en Kill _PARAM0_ immediately
func kill() -> void:
	_ensure_started()
	if current <= 0.0:
		return
	current = 0.0
	_die()


## @action Сделать _PARAM0_ неуязвимым на _PARAM1_ секунд
## @action.en Make _PARAM0_ invulnerable for _PARAM1_ seconds
## @param seconds Секунд
## @param.en seconds Seconds
func make_invulnerable(seconds: float) -> void:
	_invuln = maxf(_invuln, absf(seconds))


func _die() -> void:
	_death_frame = Engine.get_process_frames()
	died.emit()
	var o := object as Node2D
	if death_scene != null and o != null:
		var fx := death_scene.instantiate()
		o.get_parent().add_child(fx)
		if fx is Node2D:
			(fx as Node2D).global_position = o.global_position
	if destroy_on_death:
		if death_delay > 0.0:
			_dying = death_delay
		else:
			Gde.delete_object(object)


## @condition У _PARAM0_ закончилось здоровье
## @condition.en _PARAM0_ has run out of health
func is_dead() -> bool:
	_ensure_started()
	return current <= 0.0


## @condition _PARAM0_ жив
## @condition.en _PARAM0_ is alive
func is_alive() -> bool:
	_ensure_started()
	return current > 0.0


## @condition _PARAM0_ только что погиб
## @condition.en _PARAM0_ has just died
func just_died() -> bool:
	return Engine.get_process_frames() - _death_frame <= RECENT_FRAMES


## @condition _PARAM0_ только что получил урон
## @condition.en _PARAM0_ has just taken damage
func just_hurt() -> bool:
	return Engine.get_process_frames() - _hurt_frame <= RECENT_FRAMES


## @condition _PARAM0_ сейчас неуязвим
## @condition.en _PARAM0_ is invulnerable now
func is_invulnerable() -> bool:
	return _invuln > 0.0


## @condition Здоровье _PARAM0_ ниже _PARAM1_ процентов
## @condition.en Health of _PARAM0_ is below _PARAM1_ percent
## @param percent Проценты
## @param.en percent Percent
func below_percent(percent: float) -> bool:
	_ensure_started()
	return max_health > 0.0 and (current / max_health) * 100.0 < percent


## @expression Доля здоровья от 0 до 1
## @expression.en Health share from 0 to 1
func fraction() -> float:
	_ensure_started()
	return current / max_health if max_health > 0.0 else 0.0


## @expression Сколько здоровья не хватает до максимума
## @expression.en How much health is missing to the maximum
func missing() -> float:
	_ensure_started()
	return maxf(0.0, max_health - current)


## @expression Секунд неуязвимости осталось
## @expression.en Seconds of invulnerability left
func invulnerable_left() -> float:
	return _invuln
