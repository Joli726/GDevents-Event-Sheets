## Поведение «Платформа».
##
## @behavior Platform
## @title Платформа
## @title.en Platform
## @target StaticBody2D
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Всё, чем бывает платформа: односторонняя (запрыгнуть снизу, спрыгнуть вниз — «вниз» и прыжок), движущаяся, которая везёт стоящего на ней, лента конвейера, рушащаяся через N секунд и батут. Включайте что нужно.
## @description.en Everything a platform can be: one-way (jump up through it, drop down with "down" and jump), moving and carrying whoever stands on it, a conveyor belt, crumbling after N seconds and a trampoline. Turn on what you need.
## @icon platform
@tool
extends GdeBehavior

## На платформу кто-то встал.
signal stood_on(body: Node)
## Платформа рассыпалась.
signal crumbled
## Рассыпанная платформа вернулась.
signal restored
## Батут подбросил.
signal bounced(body: Node)

## @group.en One-way
@export_group("Односторонняя")
## Односторонняя: снизу проходится насквозь, сверху держит. С неё спрыгивают вниз — «вниз» и прыжок.
## @en One-way: passable from below, holds from above. Drop down from it with "down" and jump.
@export var one_way: bool = false

## @group.en Movement
@export_group("Движение")
## Двигаться туда и обратно. Кто стоит на платформе, едет вместе с ней.
## @en Move back and forth. Whoever stands on the platform rides along.
@export var moving: bool = false
## Сдвиг до дальней точки по X, пикселей.
## @en Offset to the far point along X, pixels.
@export_range(-5000.0, 5000.0, 1.0) var move_x: float = 128.0
## Сдвиг до дальней точки по Y, пикселей.
## @en Offset to the far point along Y, pixels.
@export_range(-5000.0, 5000.0, 1.0) var move_y: float = 0.0
## Время пути в одну сторону, секунд.
## @en Travel time one way, seconds.
@export_range(0.1, 60.0, 0.1) var move_time: float = 2.0
## Пауза на концах, секунд.
## @en Pause at the ends, seconds.
@export_range(0.0, 30.0, 0.1) var end_pause: float = 0.5
## Плавный разгон и торможение у концов.
## @en Smooth ends — acceleration and braking near the ends.
@export var ease_ends: bool = true

## @group.en Conveyor
@export_group("Лента")
## Скорость ленты конвейера, пикселей в секунду: везёт стоящих вбок. Отрицательная — влево. 0 — не лента.
## @en Conveyor belt speed, pixels per second: carries whoever stands on it sideways. Negative — to the left. 0 — not a belt.
@export_range(-2000.0, 2000.0, 5.0) var conveyor_speed: float = 0.0

## @group.en Crumbling
@export_group("Рушится")
## Рассыпаться, когда на платформу встали.
## @en Crumble when someone stands on the platform.
@export var crumbles: bool = false
## Через сколько секунд после того, как встали, рассыпаться.
## @en Crumble delay — seconds after someone stood on it.
@export_range(0.0, 30.0, 0.05) var crumble_delay: float = 0.6
## Через сколько секунд вернуться. 0 — не возвращаться.
## @en How many seconds until it comes back. 0 — never.
@export_range(0.0, 120.0, 0.1) var respawn_time: float = 3.0
## Дрожать перед тем, как рассыпаться.
## @en Shake before crumbling.
@export var shake: bool = true

## @group.en Trampoline
@export_group("Батут")
## Батут: подбрасывает того, кто приземлился сверху.
## @en Trampoline: throws up whoever lands on top.
@export var trampoline: bool = false
## Сила батута, пикселей в секунду.
## @en Trampoline force, pixels per second.
@export_range(0.0, 5000.0, 10.0) var bounce_force: float = 700.0

var _start: Vector2 = Vector2.ZERO
var _started: bool = false
var _phase: float = 0.0
var _going_back: bool = false
var _pause_left: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO
var _crumble_left: float = -1.0
var _broken: bool = false
var _respawn_left: float = 0.0
var _riders: Array = []
var _bounced: Dictionary = {}
var _visual_offset: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	var p := object as Node2D
	if p == null:
		return
	if not _started:
		_started = true
		_start = p.global_position
		_last_pos = _start
		_apply_one_way(p)
		var ab := p as AnimatableBody2D
		if ab != null:
			ab.sync_to_physics = true
	if _broken:
		_respawn_left -= delta
		if respawn_time > 0.0 and _respawn_left <= 0.0:
			restore()
		return

	var riders := _standing(p)
	for r: Node in riders:
		if not _riders.has(r):
			stood_on.emit(r)
	_riders = riders

	if moving:
		_move(p, delta)
	var sb := p as StaticBody2D
	# Движущуюся AnimatableBody2D не трогаем: её скорость движок считает
	# сам по перемещению, а заданная вручную затёрла бы её — и стоящий
	# оставался бы на месте, пока платформа уезжает из-под ног.
	if sb != null and not (moving and p is AnimatableBody2D):
		# Скорость, которую тело сообщает стоящему на нём: так едут на ленте.
		# AnimatableBody2D возит пассажиров само; обычное StaticBody2D при
		# движении телепортируется, и ему скорость нужно сообщить.
		var v := Vector2(conveyor_speed, 0.0)
		if moving and not (p is AnimatableBody2D):
			v += (p.global_position - _last_pos) / maxf(delta, 0.0001)
		sb.constant_linear_velocity = v
	_last_pos = p.global_position

	if crumbles:
		if _crumble_left < 0.0 and not riders.is_empty():
			_crumble_left = crumble_delay
		if _crumble_left >= 0.0:
			_crumble_left -= delta
			if shake:
				_shake_visual(p, 2.0)
			if _crumble_left <= 0.0:
				_crumble(p)
				return

	if trampoline:
		for r: Node in riders:
			var last: int = _bounced.get(r, -100)
			if Engine.get_physics_frames() - last > 6:
				_bounced[r] = Engine.get_physics_frames()
				_bounce(r)


func _move(p: Node2D, delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		return
	_phase = minf(1.0, _phase + delta / move_time)
	var t := _phase * _phase * (3.0 - 2.0 * _phase) if ease_ends else _phase
	var k := 1.0 - t if _going_back else t
	p.global_position = _start + Vector2(move_x, move_y) * k
	if _phase >= 1.0:
		_phase = 0.0
		_going_back = not _going_back
		_pause_left = end_pause


## Кто стоит сверху: полоска над верхним краем. Персонаж — только если
## он на полу, иначе прыжок сквозь одностороннюю платформу считался бы.
func _standing(p: Node2D) -> Array:
	var r := Gde.aabb(p)
	if r.size == Vector2.ZERO:
		return []
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(1.0, r.size.x - 2.0), 4.0)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, Vector2(r.get_center().x, r.position.y - 2.0))
	q.collide_with_areas = false
	q.exclude = _rids(p)
	var out: Array = []
	for hit: Dictionary in p.get_world_2d().direct_space_state.intersect_shape(q, 16):
		var col: Variant = hit.get("collider")
		if col is CharacterBody2D:
			var cb := col as CharacterBody2D
			if cb.is_on_floor() and cb.global_position.y < r.position.y:
				out.append(cb)
		elif col is RigidBody2D and not out.has(col):
			out.append(col)
	return out


func _rids(n: Node) -> Array[RID]:
	var out: Array[RID] = []
	if n is CollisionObject2D:
		out.append((n as CollisionObject2D).get_rid())
	for c: Node in n.get_children():
		out.append_array(_rids(c))
	return out


func _apply_one_way(p: Node) -> void:
	for c: Node in p.get_children():
		if c is CollisionShape2D:
			(c as CollisionShape2D).one_way_collision = one_way
		elif c is CollisionPolygon2D:
			(c as CollisionPolygon2D).one_way_collision = one_way


func _shake_visual(p: Node2D, amount: float) -> void:
	var off := Vector2(randf_range(-amount, amount), randf_range(-amount, amount * 0.5))
	for c: Node in p.get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			(c as Node2D).position += off - _visual_offset
	_visual_offset = off


func _crumble(p: Node2D) -> void:
	_shake_visual(p, 0.0)
	_broken = true
	_crumble_left = -1.0
	_respawn_left = respawn_time
	_riders = []
	p.visible = false
	_set_collision(p, false)
	crumbled.emit()


func _set_collision(p: Node, on: bool) -> void:
	for c: Node in p.get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.set_deferred("disabled", not on)


func _bounce(r: Node) -> void:
	if Gde.has_behavior(r, "Platformer"):
		Gde.beh_call(r, "Platformer", "bounce", [bounce_force])
	elif r is CharacterBody2D:
		(r as CharacterBody2D).velocity.y = -bounce_force
	elif r is RigidBody2D:
		var rb := r as RigidBody2D
		rb.linear_velocity = Vector2(rb.linear_velocity.x, -bounce_force)
	bounced.emit(r)


## @action Рассыпать _PARAM0_ сейчас
## @action.en Crumble _PARAM0_ now
func crumble_now() -> void:
	var p := object as Node2D
	if p != null and not _broken:
		_crumble(p)


## @action Вернуть рассыпанную _PARAM0_
## @action.en Bring back the crumbled _PARAM0_
func restore() -> void:
	var p := object as Node2D
	if p == null or not _broken:
		return
	_broken = false
	p.visible = true
	_set_collision(p, true)
	restored.emit()


## @action Запустить движение _PARAM0_
## @action.en Start the movement of _PARAM0_
func start_moving() -> void:
	moving = true


## @action Остановить движение _PARAM0_
## @action.en Stop the movement of _PARAM0_
func stop_moving() -> void:
	moving = false


## @action Скорость ленты _PARAM0_: _PARAM1_
## @action.en Belt speed of _PARAM0_: _PARAM1_
## @param v Скорость
## @param.en v Speed
func set_conveyor(v: float) -> void:
	conveyor_speed = v


## @condition На _PARAM0_ кто-то стоит
## @condition.en Someone stands on _PARAM0_
func has_rider() -> bool:
	return not _riders.is_empty()


## @condition _PARAM0_ вот-вот рассыплется
## @condition.en _PARAM0_ is about to crumble
func is_crumbling() -> bool:
	return _crumble_left >= 0.0 and not _broken


## @condition _PARAM0_ рассыпалась
## @condition.en _PARAM0_ has crumbled
func is_broken() -> bool:
	return _broken


## @expression Сколько объектов стоит на платформе
## @expression.en How many objects stand on the platform
func rider_count() -> float:
	return float(_riders.size())
