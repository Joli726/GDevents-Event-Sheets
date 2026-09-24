## Поведение «Способность с перезарядкой».
##
## @behavior Ability
## @title Способность с перезарядкой
## @title.en Ability with cooldown
## @description Рывок, щит или лечение по кнопке — с перезарядкой и зарядами, без событий. «Своя» способность ничего не делает сама: только считает заряды, а что делать — решают события по условию «только что применена».
## @description.en A dash, a shield or healing on a key — with a cooldown and charges, without events. A "custom" ability does nothing by itself: it only counts charges, and events decide what to do by the "has just been used" condition.
## @icon ability
@tool
extends GdeBehavior

## Применена.
signal used
## Действие способности кончилось (рывок, щит).
signal ended
## Заряд восстановился.
signal recharged

## @group.en Ability
@export_group("Способность")
## Что делает: рывок, щит (неуязвимость через «Здоровье»), лечение или своё — только заряды.
## @en What it does: a dash, a shield (invulnerability through "Health"), healing or custom — charges only.
## @options.en Dash, Shield, Heal, Custom
@export_enum("Рывок", "Щит", "Лечение", "Своя") var kind: int = 0
## Клавиша, например Shift. Пусто — только действием из листа.
## @en Key, e.g. Shift. Empty — only by an action from the sheet.
@export var key: String = "Shift"
## Зарядов — сколько раз подряд можно применить.
## @en Charges — how many times in a row it can be used.
@export_range(1, 20, 1) var max_charges: int = 1
## Перезарядка одного заряда, секунд.
## @en Recharge time of one charge, seconds.
@export_range(0.0, 120.0, 0.05) var cooldown: float = 1.0
## Длительность рывка или щита, секунд.
## @en Duration of a dash or a shield, seconds.
@export_range(0.0, 30.0, 0.05) var duration: float = 0.18

## @group.en Dash
@export_group("Рывок")
## Скорость рывка, пикселей в секунду.
## @en Dash speed, pixels per second.
@export_range(0.0, 5000.0, 10.0) var dash_speed: float = 700.0
## Куда рваться: по движению (стоя — куда смотрит) или всегда куда смотрит.
## @en Where to dash: along the movement (standing — where it faces) or always where it faces.
## @options.en Along the movement, Where it faces
@export_enum("По движению", "Куда смотрит") var dash_direction: int = 0
## Сохранить часть скорости после рывка, доля.
## @en Keep part of the speed after the dash, share.
@export_range(0.0, 1.0, 0.05) var keep_speed: float = 0.3

## @group.en Shield and healing
@export_group("Щит и лечение")
## Оттенок объекта, пока держится щит.
## @en Object tint while the shield holds.
@export var shield_color: Color = Color(0.6, 0.85, 1.0, 1.0)
## Сколько здоровья лечит.
## @en How much health it heals.
@export_range(0.0, 1000.0, 0.5) var heal_amount: float = 1.0

var _charges: int = -1
var _recharge: float = 0.0
var _active: float = 0.0
var _dir: Vector2 = Vector2.RIGHT
var _paused: Array = []
var _tint_saved: bool = false
var _base_modulate: Color = Color.WHITE
var _use_frame: int = -100
var _recharge_frame: int = -100


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if _charges < 0:
		_charges = max_charges
	if not key.is_empty() and Gde.key_just_pressed(key):
		use()
	if _charges < max_charges:
		_recharge += delta
		if cooldown <= 0.0 or _recharge >= cooldown:
			_recharge = 0.0
			_charges = mini(max_charges, _charges + 1)
			_recharge_frame = Engine.get_physics_frames()
			recharged.emit()
	else:
		_recharge = 0.0
	if _active > 0.0:
		_active -= delta
		if kind == 0:
			_dash_step(o, delta)
		if _active <= 0.0:
			_end(o)


func _dash_step(o: Node2D, delta: float) -> void:
	var body := Gde.body_of(o) as CharacterBody2D
	if body != null:
		body.velocity = _dir * dash_speed
		body.move_and_slide()
	else:
		o.global_position += _dir * dash_speed * delta


func _end(o: Node2D) -> void:
	_active = 0.0
	if kind == 0:
		var body := Gde.body_of(o) as CharacterBody2D
		if body != null:
			body.velocity = _dir * dash_speed * keep_speed
		for b: Node in _paused:
			if is_instance_valid(b):
				b.set_physics_process(true)
		_paused.clear()
	elif kind == 1 and _tint_saved:
		o.modulate = _base_modulate
		_tint_saved = false
	ended.emit()


func _pick_direction(o: Node2D) -> Vector2:
	var facing := Vector2.LEFT if Gde.is_flipped_h(o) else Vector2.RIGHT
	if dash_direction == 1:
		return facing
	var body := Gde.body_of(o) as CharacterBody2D
	if body != null and body.velocity.length() > 20.0:
		var v := body.velocity
		# Платформер: по горизонтали, а не туда, куда тянет гравитация.
		if Gde.has_behavior(o, "Platformer") and absf(v.x) > 5.0:
			return Vector2(signf(v.x), 0.0)
		if not Gde.has_behavior(o, "Platformer"):
			return v.normalized()
	return facing


## @action Применить способность _PARAM0_
## @action.en Use the ability of _PARAM0_
func use() -> void:
	var o := object as Node2D
	if o == null:
		return
	if _charges < 0:
		_charges = max_charges
	if _charges <= 0 or _active > 0.0:
		return
	_charges -= 1
	_use_frame = Engine.get_physics_frames()
	match kind:
		0:
			_dir = _pick_direction(o)
			_active = duration
			# Рывок главнее ходьбы: платформер и вид сверху на это время молчат.
			for bname: String in ["Platformer", "TopDown", "Car"]:
				var b := Gde.behavior(o, bname, true)
				if b != null and b.is_physics_processing():
					b.set_physics_process(false)
					_paused.append(b)
		1:
			_active = duration
			if Gde.has_behavior(o, "Health"):
				Gde.beh_call(o, "Health", "make_invulnerable", [duration])
			if not _tint_saved:
				_base_modulate = o.modulate
				_tint_saved = true
			o.modulate = _base_modulate * shield_color
		2:
			if Gde.has_behavior(o, "Health"):
				Gde.beh_call(o, "Health", "heal", [heal_amount])
	used.emit()
	if _active <= 0.0:
		ended.emit()


## @action Добавить _PARAM1_ зарядов способности _PARAM0_
## @action.en Add _PARAM1_ charges to the ability of _PARAM0_
## @param n Зарядов
## @param.en n Charges
func add_charges(n: float) -> void:
	if _charges < 0:
		_charges = max_charges
	_charges = clampi(_charges + int(n), 0, max_charges)


## @action Мгновенно перезарядить _PARAM0_
## @action.en Instantly recharge _PARAM0_
func refill() -> void:
	_charges = max_charges
	_recharge = 0.0


## @condition Способность _PARAM0_ готова
## @condition.en The ability of _PARAM0_ is ready
func can_use() -> bool:
	return (_charges < 0 or _charges > 0) and _active <= 0.0


## @condition Способность _PARAM0_ действует (рывок или щит)
## @condition.en The ability of _PARAM0_ is in effect (a dash or a shield)
func is_active() -> bool:
	return _active > 0.0


## @condition Способность _PARAM0_ только что применена
## @condition.en The ability of _PARAM0_ has just been used
func just_used() -> bool:
	return Engine.get_physics_frames() - _use_frame <= RECENT_FRAMES


## @condition Заряд способности _PARAM0_ только что восстановился
## @condition.en A charge of the ability of _PARAM0_ has just been restored
func just_recharged() -> bool:
	return Engine.get_physics_frames() - _recharge_frame <= RECENT_FRAMES


## @expression Сколько зарядов есть
## @expression.en How many charges there are
func charges() -> float:
	return float(max_charges if _charges < 0 else _charges)


## @expression Секунд до следующего заряда
## @expression.en Seconds until the next charge
func cooldown_left() -> float:
	if _charges < 0 or _charges >= max_charges:
		return 0.0
	return maxf(0.0, cooldown - _recharge)


## @expression Готовность следующего заряда, от 0 до 1 — для полоски
## @expression.en Readiness of the next charge, from 0 to 1 — for a bar
func readiness() -> float:
	if _charges < 0 or _charges >= max_charges or cooldown <= 0.0:
		return 1.0
	return clampf(_recharge / cooldown, 0.0, 1.0)
