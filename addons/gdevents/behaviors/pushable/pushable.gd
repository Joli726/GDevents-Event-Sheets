## Поведение «Толкаемый».
##
## @behavior Pushable
## @title Толкаемый
## @title.en Pushable
## @target CharacterBody2D
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Ящик, который персонаж сдвигает, упираясь в него боком. Падает с края, упирается в стены, в виде сверху толкается во все стороны.
## @description.en A crate a character moves by leaning into its side. It falls off edges, stops at walls, and in top-down games is pushed in every direction.
## @icon pushable
@tool
extends GdeBehavior

## Начали толкать.
signal push_started
## Перестали толкать.
signal push_ended

## @group.en Pushing
@export_group("Толкание")
## Кто может толкать — имя объекта из листа, например Player. Пусто — любой персонаж.
## @en Who can push — the name of a sheet object, e.g. Player. Empty — any character.
@export var pusher_object: String = ""
## Скорость, с которой едет ящик, пикселей в секунду. Лучше меньше скорости бега — толкать тяжело.
## @en Speed at which the crate moves, pixels per second. Better lower than the running speed — pushing is hard.
@export_range(0.0, 2000.0, 5.0) var push_speed: float = 90.0
## Тяжесть — сколько секунд упираться, прежде чем ящик сдвинется.
## @en Heaviness — how many seconds to lean before the crate moves.
@export_range(0.0, 5.0, 0.05) var push_delay: float = 0.0
## Скольжение — как быстро ящик останавливается, когда его отпустили. 0 — сразу.
## @en Sliding — how fast the crate stops when released. 0 — at once.
@export_range(0.0, 10000.0, 10.0) var slide_friction: float = 0.0
## Толкать можно.
## @en Pushing is allowed.
@export var enabled: bool = true

## @group.en Gravity
@export_group("Гравитация")
## Вид сверху: без гравитации, толкается во все стороны.
## @en Top-down: no gravity, pushed in every direction.
@export var top_down: bool = false
## Сила тяжести, пикселей в секунду за секунду.
## @en Gravity strength, pixels per second per second.
@export_range(0.0, 5000.0, 10.0) var gravity: float = 1300.0
## Предел скорости падения.
## @en Maximum fall speed.
@export_range(0.0, 3000.0, 10.0) var max_fall_speed: float = 900.0

const GRACE := 0.15

var _pushing: bool = false
var _lean: float = 0.0
var _grace: float = 0.0
var _last_dir: Vector2 = Vector2.ZERO
var _moved: float = 0.0


func _physics_process(delta: float) -> void:
	var body := object as CharacterBody2D
	if body == null:
		return
	# Вид сверху — без пола: скольжение по стенам одинаковое во все стороны.
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING if top_down \
			else CharacterBody2D.MOTION_MODE_GROUNDED
	var dir := _push_direction(body) if enabled else Vector2.ZERO
	# Толкание «липкое»: упёршийся персонаж теряет скорость о ящик, отстаёт
	# на кадр-другой и снова догоняет. Без запаса ящик ехал бы рывками.
	if dir != Vector2.ZERO:
		_last_dir = dir
		_grace = GRACE
	else:
		_grace -= delta
		if _grace > 0.0 and _lean > 0.0:
			dir = _last_dir
	if dir != Vector2.ZERO:
		_lean += delta
	else:
		_lean = 0.0
	var pushing := dir != Vector2.ZERO and _lean >= push_delay
	if pushing != _pushing:
		_pushing = pushing
		if pushing:
			push_started.emit()
		else:
			push_ended.emit()

	var v := body.velocity
	if top_down:
		if pushing:
			v = dir * push_speed
		else:
			v = v.move_toward(Vector2.ZERO, slide_friction * delta) if slide_friction > 0.0 else Vector2.ZERO
	else:
		if pushing:
			v.x = dir.x * push_speed
		else:
			v.x = move_toward(v.x, 0.0, slide_friction * delta) if slide_friction > 0.0 else 0.0
		if not body.is_on_floor():
			v.y = minf(v.y + gravity * delta, max_fall_speed)
	var before := body.global_position
	body.velocity = v
	body.move_and_slide()
	_moved += body.global_position.distance_to(before) if pushing else 0.0


## Кто и куда толкает: персонаж, который в этом кадре упёрся в ящик сбоку.
## Упёрся — значит, его движение остановил именно ящик: так отличаем
## толкание от того, что игрок просто стоит рядом.
func _push_direction(body: CharacterBody2D) -> Vector2:
	var r := Gde.aabb(body).grow(3.0)
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, r.get_center())
	q.exclude = [body.get_rid()]
	q.collide_with_areas = false
	var allowed: Array = []
	if not pusher_object.is_empty():
		for n: Node in Gde.all_instances(pusher_object):
			allowed.append(Gde.body_of(n))
	var out := Vector2.ZERO
	for hit: Dictionary in body.get_world_2d().direct_space_state.intersect_shape(q, 8):
		var c := hit.get("collider") as CharacterBody2D
		if c == null or (not pusher_object.is_empty() and not allowed.has(c)):
			continue
		for i in c.get_slide_collision_count():
			var col := c.get_slide_collision(i)
			if col.get_collider() != body:
				continue
			var n := col.get_normal()
			if top_down:
				out = -n
			elif absf(n.x) > 0.7:
				out = Vector2(-signf(n.x), 0.0)
	return out.normalized() if out != Vector2.ZERO else out


## @action Разрешить толкать _PARAM0_: _PARAM1_ (1 да, 0 нет)
## @action.en Allow pushing _PARAM0_: _PARAM1_ (1 yes, 0 no)
## @param on Да или нет
## @param.en on Yes or no
func set_enabled(on: bool) -> void:
	enabled = on


## @action Толкнуть _PARAM0_ на _PARAM1_ ; _PARAM2_ пикселей
## @action.en Push _PARAM0_ by _PARAM1_ ; _PARAM2_ pixels
## @param dx По X
## @param.en dx Along X
## @param dy По Y
## @param.en dy Along Y
func shove(dx: float, dy: float) -> void:
	var body := object as CharacterBody2D
	if body != null:
		body.move_and_collide(Vector2(dx, dy))


## @condition _PARAM0_ толкают
## @condition.en _PARAM0_ is being pushed
func is_pushed() -> bool:
	return _pushing


## @expression Сколько пикселей ящик проехал, пока его толкали
## @expression.en How many pixels the crate moved while being pushed
func pushed_distance() -> float:
	return _moved
