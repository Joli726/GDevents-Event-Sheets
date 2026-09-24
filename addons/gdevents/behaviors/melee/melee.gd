## Поведение «Ближний бой».
##
## @behavior Melee
## @title Ближний бой
## @title.en Melee attack
## @needs AnimatedSprite2D|Sprite2D Спрайт
## @needs.en AnimatedSprite2D|Sprite2D Sprite
## @description Удар мечом, кулаком, лапой. Зона поражения включается на нужных кадрах анимации удара, бьёт каждого один раз за замах, отбрасывает. Комбо до трёх ударов и перезарядка.
## @description.en A strike with a sword, a fist, a paw. The hit zone turns on at the right frames of the attack animation, hits everyone once per swing and knocks them back. Combos of up to three strikes and a cooldown.
## @icon melee
@tool
extends GdeBehavior

## Начался удар. Номер: 1, 2, 3 — шаг комбо.
signal attack_started(step: int)
## Удар попал.
signal hit(target: Node)
## Комбо закончилось — пошла перезарядка.
signal combo_finished

## @group.en Target
@export_group("Цель")
## Кого бить — имя объекта из листа, например Enemy.
## @en Whom to hit — the name of a sheet object, e.g. Enemy.
@export var target_object: String = "Enemy"
## Урон за удар. Бьёт через поведение «Здоровье» цели.
## @en Damage per strike. Hits through the target's "Health" behavior.
@export_range(0.0, 1000.0, 0.5) var damage: float = 1.0
## Прибавка урона — на каждом следующем ударе комбо.
## @en Damage added on each next strike of a combo.
@export_range(0.0, 1000.0, 0.5) var combo_bonus: float = 0.5
## Отбрасывание цели, пикселей.
## @en Target knockback, pixels.
@export_range(0.0, 500.0, 1.0) var knockback: float = 12.0

## @group.en Hit zone
@export_group("Зона удара")
## Сдвиг зоны вперёд от объекта, пикселей. Сзади не бьёт: зона разворачивается вместе со спрайтом.
## @en Zone offset forward from the object, pixels. It does not hit behind: the zone turns with the sprite.
@export_range(-500.0, 500.0, 1.0) var zone_forward: float = 24.0
## Сдвиг зоны по вертикали, пикселей. Минус — выше.
## @en Vertical zone offset, pixels. Minus — higher.
@export_range(-500.0, 500.0, 1.0) var zone_up: float = 0.0
## Ширина зоны, пикселей.
## @en Zone width, pixels.
@export_range(1.0, 1000.0, 1.0) var zone_width: float = 32.0
## Высота зоны, пикселей.
## @en Zone height, pixels.
@export_range(1.0, 1000.0, 1.0) var zone_height: float = 32.0
## Показывать зону удара — для отладки.
## @en Show the hit zone — for debugging.
@export var show_zone: bool = false

## @group.en Timing
@export_group("Время")
## Первый кадр удара — с какого кадра анимации зона включается.
## @en First hit frame — from which frame of the attack animation the zone turns on.
@export_range(0, 60, 1) var hit_frame_from: int = 1
## По какой кадр зона включена.
## @en Up to which frame the zone is on.
@export_range(0, 60, 1) var hit_frame_to: int = 2
## Длительность удара без анимации, секунд. С анимацией удар длится, пока она играет.
## @en Strike duration without an animation, seconds. With an animation, the strike lasts while it plays.
@export_range(0.05, 5.0, 0.05) var swing_time: float = 0.3
## Доля удара без анимации — сколько зона включена, считая от середины.
## @en Active share — without an animation, the share of the strike the zone is on, around the middle.
@export_range(0.05, 1.0, 0.05) var active_share: float = 0.4
## Перезарядка после комбо, секунд.
## @en Cooldown after a combo, seconds.
@export_range(0.0, 10.0, 0.05) var cooldown: float = 0.35

## @group.en Combo
@export_group("Комбо")
## Ударов в комбо: 1 — без комбо.
## @en Strikes in a combo: 1 — no combo.
@export_range(1, 3, 1) var combo_steps: int = 3
## Окно комбо — сколько секунд после удара ждать следующего нажатия.
## @en Combo window — how many seconds after a strike to wait for the next press.
@export_range(0.05, 2.0, 0.05) var combo_window: float = 0.4
## Анимация первого удара — имя из AnimatedSprite2D. Пусто — удар по времени.
## @en Animation of the first strike — a name from AnimatedSprite2D. Empty — a timed strike.
@export var attack_animation: String = ""
## Анимация второго удара. Пусто — как у первого.
## @en Animation of the second strike. Empty — as the first.
@export var attack_2_animation: String = ""
## Анимация третьего удара. Пусто — как у второго.
## @en Animation of the third strike. Empty — as the second.
@export var attack_3_animation: String = ""

## @group.en Controls
@export_group("Управление")
## Клавиша удара, например X. Пусто — только действием из листа.
## @en Attack key, e.g. X. Empty — only by an action from the sheet.
@export var attack_key: String = ""

var _step: int = 0
var _swing: float = -1.0
var _anim: String = ""
var _since_swing: float = 99.0
var _cool: float = 0.0
var _queued: bool = false
var _hit_this_swing: Array = []
var _hit_frame: int = -100
var _hits: int = 0
var _zone_view: Line2D = null
var _last_frame: int = 0


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not attack_key.is_empty() and Gde.key_just_pressed(attack_key):
		attack()
	_cool = maxf(0.0, _cool - delta)
	if _swing >= 0.0:
		_swing += delta
		if _zone_on(o):
			_strike(o)
		if _swing_over(o):
			_swing = -1.0
			_since_swing = 0.0
			if _queued and _step < combo_steps:
				_queued = false
				_begin(_step + 1)
			elif _step >= combo_steps:
				_finish_combo()
	elif _step > 0:
		_since_swing += delta
		if _since_swing > combo_window:
			_finish_combo()
	_draw_zone(o)


func _finish_combo() -> void:
	_step = 0
	_queued = false
	_cool = cooldown
	combo_finished.emit()


func _begin(step: int) -> void:
	_step = step
	_swing = 0.0
	_hit_this_swing.clear()
	_last_frame = 0
	_anim = [attack_animation, attack_2_animation, attack_3_animation][step - 1]
	if _anim.is_empty() and step > 1:
		_anim = attack_2_animation if step == 3 and not attack_2_animation.is_empty() else attack_animation
	if not _anim.is_empty():
		Gde.play_animation(object, _anim)
	attack_started.emit(step)


func _sprite(o: Node) -> AnimatedSprite2D:
	if o is AnimatedSprite2D:
		return o as AnimatedSprite2D
	for c: Node in o.get_children():
		var r := _sprite(c)
		if r != null:
			return r
	return null


## Анимация удара играет прямо сейчас — по ней и считаем кадры.
func _anim_playing(o: Node) -> AnimatedSprite2D:
	if _anim.is_empty():
		return null
	var a := _sprite(o)
	if a == null or String(a.animation) != _anim:
		return null
	return a


func _zone_on(o: Node) -> bool:
	var a := _anim_playing(o)
	if a != null:
		return a.frame >= hit_frame_from and a.frame <= hit_frame_to
	var k := _swing / swing_time
	return k >= 0.5 - active_share * 0.5 and k <= 0.5 + active_share * 0.5


func _swing_over(o: Node) -> bool:
	var a := _anim_playing(o)
	if a == null:
		return _swing >= swing_time
	# Незацикленная анимация останавливается сама; зацикленная — удар
	# длится один проход: кадр перескочил с конца на начало.
	var wrapped := a.frame < _last_frame
	_last_frame = a.frame
	return not a.is_playing() or (wrapped and _swing > 0.05)


## Зона удара в мире: впереди объекта, по направлению спрайта.
func zone() -> Rect2:
	var o := object as Node2D
	if o == null:
		return Rect2()
	var facing := -1.0 if Gde.is_flipped_h(o) else 1.0
	var c := o.global_position + Vector2(zone_forward * facing, zone_up)
	return Rect2(c - Vector2(zone_width, zone_height) * 0.5, Vector2(zone_width, zone_height))


func _strike(o: Node2D) -> void:
	if target_object.is_empty():
		return
	var z := zone()
	for n: Node in Gde.all_instances(target_object):
		if n == o or _hit_this_swing.has(n):
			continue
		var r := Gde.aabb(n)
		if not (z.intersects(r) or z.has_point(Gde.pos_of(n))):
			continue
		_hit_this_swing.append(n)
		var dmg := damage + combo_bonus * float(_step - 1)
		if Gde.has_behavior(n, "Health"):
			Gde.beh_call(n, "Health", "damage", [dmg])
		if knockback > 0.0:
			Gde.knockback(n, o, knockback)
		_hits += 1
		_hit_frame = Engine.get_physics_frames()
		hit.emit(n)


func _draw_zone(o: Node2D) -> void:
	if not show_zone:
		if _zone_view != null:
			_zone_view.queue_free()
			_zone_view = null
		return
	if _zone_view == null:
		_zone_view = Line2D.new()
		_zone_view.width = 1.5
		_zone_view.top_level = true
		_zone_view.closed = true
		add_child(_zone_view)
	var z := zone()
	_zone_view.points = PackedVector2Array([z.position, Vector2(z.end.x, z.position.y), z.end,
			Vector2(z.position.x, z.end.y)])
	_zone_view.default_color = Color(1, 0.2, 0.2, 0.9) if _swing >= 0.0 and _zone_on(o) else Color(1, 1, 1, 0.35)


## Во время удара нажатие запоминается и продолжает комбо.
## @en A press during a strike is remembered and continues the combo.
## @action Ударить: _PARAM0_
## @action.en Attack: _PARAM0_
func attack() -> void:
	if _swing >= 0.0:
		if _step < combo_steps:
			_queued = true
		return
	if _step > 0 and _step < combo_steps and _since_swing <= combo_window:
		_begin(_step + 1)
		return
	if _cool > 0.0:
		return
	_begin(1)


## @action Прервать удар _PARAM0_
## @action.en Interrupt the attack of _PARAM0_
func interrupt() -> void:
	_swing = -1.0
	_finish_combo()


## @condition _PARAM0_ бьёт
## @condition.en _PARAM0_ is attacking
func is_attacking() -> bool:
	return _swing >= 0.0


## @condition Зона удара _PARAM0_ включена
## @condition.en The hit zone of _PARAM0_ is on
func zone_active() -> bool:
	var o := object as Node
	return _swing >= 0.0 and o != null and _zone_on(o)


## @condition _PARAM0_ только что попал
## @condition.en _PARAM0_ has just hit
func just_hit() -> bool:
	return Engine.get_physics_frames() - _hit_frame <= RECENT_FRAMES


## @condition _PARAM0_ может ударить
## @condition.en _PARAM0_ can attack
func can_attack() -> bool:
	return _swing < 0.0 and (_cool <= 0.0 or (_step > 0 and _step < combo_steps))


## @expression Шаг комбо: 0 — не бьёт, 1, 2, 3
## @expression.en Combo step: 0 — not attacking, 1, 2, 3
func combo_step() -> float:
	return float(_step)


## @expression Сколько раз попал
## @expression.en How many times it hit
func hit_count() -> float:
	return float(_hits)


## @expression Сколько секунд до конца перезарядки
## @expression.en How many seconds until the cooldown ends
func cooldown_left() -> float:
	return _cool
