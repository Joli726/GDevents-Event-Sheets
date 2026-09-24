## Поведение «Стая».
##
## @behavior Flock
## @title Стая
## @title.en Flock
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Пчёлы, птицы, рыбы: держатся вместе, летят в одну сторону, не сталкиваются друг с другом и огибают стены. Может следовать за объектом или убегать от него.
## @description.en Bees, birds, fish: they stay together, fly the same way, do not bump into each other and go around walls. Can follow an object or flee from it.
## @icon flock
@tool
extends GdeBehavior

const GROUP := "__gde_flock"

## @group.en Flock
@export_group("Стая")
## Имя стаи: вместе держатся объекты с одинаковым именем. Разные имена — разные стаи.
## @en Flock name: objects with the same name stay together. Different names — different flocks.
@export var flock_name: String = "flock"
## Радиус соседства — кого считать своими, пикселей.
## @en Neighbor radius — who counts as a neighbor, pixels.
@export_range(1.0, 1000.0, 1.0) var neighbor_radius: float = 70.0
## Личное пространство — ближе этого соседи расталкиваются, пикселей.
## @en Personal space — closer than this, neighbors push apart, pixels.
@export_range(1.0, 500.0, 1.0) var separation_radius: float = 24.0
## Стая включена.
## @en The flock is on.
@export var running: bool = true

## @group.en Movement
@export_group("Движение")
## Скорость, пикселей в секунду.
## @en Speed, pixels per second.
@export_range(0.0, 2000.0, 5.0) var max_speed: float = 120.0
## Поворотливость — насколько резко меняется курс.
## @en Agility — how sharply the course changes.
@export_range(1.0, 5000.0, 10.0) var max_force: float = 300.0
## Сколько случайного блуждания добавлять, 0 — никакого.
## @en How much random wandering to add, 0 — none.
@export_range(0.0, 5.0, 0.05) var wander: float = 0.3

## @group.en Rules
@export_group("Правила")
## Расталкивание — сила, с которой держат дистанцию.
## @en Separation — how strongly they keep their distance.
@export_range(0.0, 10.0, 0.05) var separation: float = 1.6
## Выравнивание — насколько лететь в ту же сторону, что соседи.
## @en Alignment — how much to fly the same way as the neighbors.
@export_range(0.0, 10.0, 0.05) var alignment: float = 1.0
## Сплочённость — насколько тянуться к центру соседей.
## @en Cohesion — how much to pull toward the center of the neighbors.
@export_range(0.0, 10.0, 0.05) var cohesion: float = 1.0

## @group.en Leader
@export_group("Вожак")
## Объект, за которым лететь, например Player. Пусто — летать свободно.
## @en An object to follow, e.g. Player. Empty — fly freely.
@export var follow_object: String = ""
## Как сильно тянуться к нему. Отрицательное — убегать.
## @en How strongly to pull toward it. Negative — flee.
@export_range(-10.0, 10.0, 0.05) var follow_weight: float = 1.0

## @group.en Obstacles
@export_group("Препятствия")
## Огибать стены.
## @en Go around walls.
@export var avoid_walls: bool = true
## На каком расстоянии замечать стену впереди, пикселей.
## @en At what distance to notice a wall ahead, pixels.
@export_range(1.0, 1000.0, 1.0) var avoid_distance: float = 50.0
## Сила уклонения от стен.
## @en Wall avoidance strength.
@export_range(0.0, 20.0, 0.1) var avoid_weight: float = 4.0

## @group.en Look
@export_group("Вид")
## Поворачивать объект по курсу.
## @en Rotate the object toward its course.
@export var rotate_object: bool = true
## Отражение спрайта по направлению движения.
## @en Flip the sprite — toward the movement direction.
@export var flip_sprite: bool = false

var _vel: Vector2 = Vector2.ZERO
var _neighbors: int = 0
var _noise: float = 0.0


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(GROUP)
		_noise = randf() * 1000.0
		_vel = Vector2.RIGHT.rotated(randf() * TAU) * max_speed * 0.5


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null or not running:
		return
	var steer := _rules(o) + _leader(o) + _walls(o) + _wander(delta)
	_vel = (_vel + steer.limit_length(max_force) * delta).limit_length(max_speed)
	var body := o as CharacterBody2D
	if body != null:
		body.velocity = _vel
		body.move_and_slide()
		_vel = body.velocity
	else:
		o.global_position += _vel * delta
	if _vel.length() > 1.0:
		if rotate_object:
			o.global_rotation = _vel.angle()
		if flip_sprite and absf(_vel.x) > 1.0:
			Gde.set_flip_h(o, _vel.x < 0.0)


## Три правила Рейнольдса: не толкаться, лететь как соседи, держаться вместе.
## Каждое правило — желаемая скорость, из неё поворот не сильнее max_force:
## так правила соизмеримы, и ни одно не глушит остальные и вожака.
func _rules(o: Node2D) -> Vector2:
	var away := Vector2.ZERO
	var close := 0
	var avg_vel := Vector2.ZERO
	var center := Vector2.ZERO
	_neighbors = 0
	for b: Node in get_tree().get_nodes_in_group(GROUP):
		if b == self or b.get("flock_name") != flock_name or not b.get("running"):
			continue
		var other := b.get("object") as Node2D
		if other == null:
			continue
		var to := o.global_position - other.global_position
		var d := to.length()
		if d > neighbor_radius:
			continue
		_neighbors += 1
		avg_vel += b.get("_vel")
		center += other.global_position
		if d < separation_radius:
			close += 1
			# Ближе — сильнее; совпавших разводим в случайную сторону.
			away += to / (d * d) if d > 0.01 else Vector2.RIGHT.rotated(randf() * TAU)
	if _neighbors == 0:
		return Vector2.ZERO
	var out := Vector2.ZERO
	if close > 0 and away.length() > 0.0:
		out += _steer_to(away.normalized() * max_speed) * separation
	if avg_vel.length() > 0.1:
		out += _steer_to(avg_vel.normalized() * max_speed) * alignment
	var to_center := center / float(_neighbors) - o.global_position
	# К центру — с замедлением: уже в центре тянуться некуда.
	out += _steer_to(to_center.normalized() * max_speed \
			* clampf(to_center.length() / neighbor_radius, 0.0, 1.0)) * cohesion
	return out


func _leader(o: Node2D) -> Vector2:
	if follow_object.is_empty() or is_zero_approx(follow_weight):
		return Vector2.ZERO
	var best: Node2D = null
	var best_d := INF
	for n: Node in Gde.all_instances(follow_object):
		var t := Gde.main(n)
		if t == null or t == o:
			continue
		var d := o.global_position.distance_squared_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t
	if best == null:
		return Vector2.ZERO
	var to := best.global_position - o.global_position
	if follow_weight > 0.0 and to.length() < separation_radius:
		return Vector2.ZERO
	# Убегают вдвое резвее, чем догоняют: от хищника не прогуливаются.
	var want := to.normalized() * max_speed * signf(follow_weight)
	return _steer_to(want) * absf(follow_weight) * (2.0 if follow_weight < 0.0 else 1.0)


## Лучи вперёд и по бокам: упёрлись — отворачиваем по нормали стены.
func _walls(o: Node2D) -> Vector2:
	if not avoid_walls or _vel.length() < 1.0:
		return Vector2.ZERO
	var space := o.get_world_2d().direct_space_state
	var out := Vector2.ZERO
	var fwd := _vel.normalized()
	var mask := 1
	var body := Gde.body_of(o)
	if body != null:
		mask = body.collision_mask
	for a: float in [0.0, -0.5, 0.5]:
		var dir := fwd.rotated(a)
		var q := PhysicsRayQueryParameters2D.create(o.global_position,
				o.global_position + dir * avoid_distance * (1.0 if a == 0.0 else 0.7), mask)
		if body != null:
			q.exclude = [body.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or not (hit["collider"] is StaticBody2D or (hit["collider"] as Object).is_class("TileMapLayer")):
			continue
		var closeness := 1.0 - o.global_position.distance_to(hit["position"]) / avoid_distance
		out += (hit["normal"] as Vector2) * max_force * maxf(0.2, closeness)
	return out * avoid_weight


func _wander(delta: float) -> Vector2:
	if wander <= 0.0:
		return Vector2.ZERO
	_noise += delta
	var a := sin(_noise * 1.3) * 1.7 + sin(_noise * 0.7 + 2.0)
	return Vector2.RIGHT.rotated(a + _vel.angle()) * max_force * 0.5 * wander


## Поворот к желаемой скорости, не резче max_force.
func _steer_to(want: Vector2) -> Vector2:
	return (want - _vel).limit_length(max_force)


## @action Вести стаю _PARAM0_ за объектом _PARAM1_
## @action.en Lead the flock of _PARAM0_ to object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func follow(name: String) -> void:
	follow_object = name
	follow_weight = absf(follow_weight) if follow_weight != 0.0 else 1.0


## @action Пугать стаю _PARAM0_ объектом _PARAM1_
## @action.en Scare the flock of _PARAM0_ with object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func flee_from(name: String) -> void:
	follow_object = name
	follow_weight = -absf(follow_weight) if follow_weight != 0.0 else -1.0


## @action Толкнуть _PARAM0_ под углом _PARAM1_ градусов со скоростью _PARAM2_
## @action.en Push _PARAM0_ at an angle of _PARAM1_ degrees with speed _PARAM2_
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
## @param push_speed Скорость
## @param.en push_speed Speed
func push(angle_deg: float, push_speed: float) -> void:
	_vel = Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * push_speed


## @condition У _PARAM0_ есть соседи по стае
## @condition.en _PARAM0_ has flock neighbors
func has_neighbors() -> bool:
	return _neighbors > 0


## @expression Сколько соседей рядом
## @expression.en How many neighbors are near
func neighbor_count() -> float:
	return float(_neighbors)


## @expression Курс в градусах
## @expression.en Course in degrees
func course() -> float:
	return rad_to_deg(_vel.angle())


## @expression Скорость
## @expression.en Speed
func speed() -> float:
	return _vel.length()
