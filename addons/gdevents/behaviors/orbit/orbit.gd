## Поведение «Орбита».
##
## @behavior Orbit
## @title Орбита
## @title.en Orbit
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Вращается вокруг другого объекта: щиты, спутники, пилы вокруг босса. Несколько объектов вокруг одного центра сами встают поровну по кругу.
## @description.en Circles around another object: shields, satellites, saws around a boss. Several objects around one center spread evenly around the circle by themselves.
## @icon orbit
@tool
extends GdeBehavior

## Центр орбиты исчез.
signal center_lost

## @group.en Center
@export_group("Центр")
## Центр — имя объекта из листа событий, например Boss. Пусто — вращаться вокруг места старта.
## @en Center — the name of an object from the event sheet, e.g. Boss. Empty — circle around the start point.
@export var center_object: String = ""
## Исчезнуть вместе с центром: щиты пропадают, когда босс погиб.
## @en Disappear together with the center: shields vanish when the boss is defeated.
@export var delete_with_center: bool = false
## Вращение включено.
## @en Circling is on.
@export var running: bool = true

## @group.en Circle
@export_group("Круг")
## Радиус орбиты, пикселей.
## @en Orbit radius, pixels.
@export_range(0.0, 2000.0, 1.0) var radius: float = 64.0
## Скорость, градусов в секунду. Отрицательная — против часовой стрелки.
## @en Speed, degrees per second. Negative — counterclockwise.
@export_range(-2000.0, 2000.0, 5.0) var degrees_per_second: float = 90.0
## Начальный угол, градусов: 0 — справа от центра, 90 — снизу.
## @en Start angle, degrees: 0 — to the right of the center, 90 — below.
@export_range(-360.0, 360.0, 1.0) var start_angle: float = 0.0
## Встать поровну по кругу с другими объектами на той же орбите.
## @en Spread evenly around the circle with other objects on the same orbit.
@export var spread_evenly: bool = true

## @group.en Wobble
@export_group("Дыхание")
## Дыхание орбиты — насколько радиус то растёт, то сжимается, пикселей. 0 — ровный круг.
## @en Orbit breathing — how much the radius grows and shrinks, pixels. 0 — an even circle.
@export_range(0.0, 1000.0, 1.0) var radius_wobble: float = 0.0
## Частота дыхания, раз в секунду.
## @en Breathing frequency, times per second.
@export_range(0.0, 10.0, 0.05) var wobble_speed: float = 0.5

## @group.en Look
@export_group("Вид")
## Поворачивать объект вдоль орбиты — как пила, которая смотрит по ходу.
## @en Rotate the object along the orbit — like a saw facing the way it moves.
@export var face_along: bool = false
## Собственное вращение объекта, градусов в секунду — как крутящаяся пила.
## @en The object's own spin, degrees per second — like a spinning saw.
@export_range(-3600.0, 3600.0, 10.0) var spin: float = 0.0

const GROUP := "__gde_orbit"

var _angle: float = 0.0
var _time: float = 0.0
var _started: bool = false
var _home: Vector2 = Vector2.ZERO
var _center: Node2D = null
var _had_center: bool = false


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _started:
		_started = true
		_home = o.global_position
		_angle = deg_to_rad(start_angle)
	var c := _find_center(o)
	if c == null and _had_center:
		_had_center = false
		center_lost.emit()
		if delete_with_center:
			Gde.delete_object(o)
			return
	if c != null:
		_had_center = true
	if not running:
		return
	_time += delta
	_angle = wrapf(_angle + deg_to_rad(degrees_per_second) * delta, -PI, PI)
	var at := _angle + _slot_offset()
	var r := radius + radius_wobble * sin(_time * TAU * wobble_speed)
	var pivot := c.global_position if c != null else _home
	o.global_position = pivot + Vector2.RIGHT.rotated(at) * r
	if face_along:
		o.global_rotation = at + (PI * 0.5 if degrees_per_second >= 0.0 else -PI * 0.5)
	elif not is_zero_approx(spin):
		o.global_rotation += deg_to_rad(spin) * delta


func _find_center(o: Node2D) -> Node2D:
	if center_object.is_empty():
		return null
	if _center != null and is_instance_valid(_center) and _center.is_inside_tree():
		return _center
	_center = null
	var best_d := INF
	for n: Node in Gde.all_instances(center_object):
		var t := Gde.main(n)
		if t == null or t == o:
			continue
		var d := o.global_position.distance_squared_to(t.global_position)
		if d < best_d:
			best_d = d
			_center = t
	return _center


## Сдвиг по кругу: соседи на той же орбите — поровну, порядок по возрасту.
func _slot_offset() -> float:
	if not spread_evenly:
		return 0.0
	var mates: Array[int] = []
	for b: Node in get_tree().get_nodes_in_group(GROUP):
		if b.get("center_object") == center_object and _same_center(b):
			mates.append(b.get_instance_id())
	if mates.size() <= 1:
		return 0.0
	mates.sort()
	return TAU * float(mates.find(get_instance_id())) / float(mates.size())


func _same_center(b: Node) -> bool:
	if center_object.is_empty():
		return b == self
	var theirs: Variant = b.get("_center")
	return theirs == _center


## @action Вращать _PARAM0_ вокруг объекта _PARAM1_
## @action.en Circle _PARAM0_ around object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func set_center(name: String) -> void:
	center_object = name
	_center = null


## @action Радиус орбиты _PARAM0_: _PARAM1_
## @action.en Orbit radius of _PARAM0_: _PARAM1_
## @param r Радиус
## @param.en r Radius
func set_radius(r: float) -> void:
	radius = maxf(0.0, r)


## @action Поставить _PARAM0_ на угол _PARAM1_ градусов
## @action.en Put _PARAM0_ at an angle of _PARAM1_ degrees
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
func set_angle(angle_deg: float) -> void:
	_angle = deg_to_rad(angle_deg)
	_started = true


## @action Развернуть вращение _PARAM0_ в другую сторону
## @action.en Reverse the circling of _PARAM0_
func reverse() -> void:
	degrees_per_second = -degrees_per_second


## @condition У _PARAM0_ есть центр орбиты
## @condition.en _PARAM0_ has an orbit center
func has_center() -> bool:
	return _center != null and is_instance_valid(_center)


## @expression Угол на орбите в градусах
## @expression.en Angle on the orbit in degrees
func angle() -> float:
	return rad_to_deg(wrapf(_angle + _slot_offset(), -PI, PI))


## @expression Текущий радиус с учётом дыхания
## @expression.en Current radius including breathing
func current_radius() -> float:
	return radius + radius_wobble * sin(_time * TAU * wobble_speed)
