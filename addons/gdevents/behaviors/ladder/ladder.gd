## Поведение «Лестница».
##
## @behavior Ladder
## @title Лестница
## @title.en Ladder
## @target Area2D
## @needs CollisionShape2D Зона лестницы
## @needs.en CollisionShape2D Ladder zone
## @description Зона, в которой «Персонаж платформера» лазит вверх и вниз стрелками. Прыжок — соскочить. Лиана, канат и вьюн — тоже лестницы.
## @description.en A zone where a "Platformer character" climbs up and down with the arrow keys. Jump to get off. A vine, a rope and ivy are ladders too.
## @icon ladder
@tool
extends GdeBehavior

## Кто-то начал лезть.
signal climb_started(body: Node)

const GROUP := "__gde_ladder"

## Лазать можно.
## @en Climbing is allowed.
@export var enabled: bool = true
## Ставить лезущего по центру лестницы, как на настоящей лестнице. Выключите для широкой стены с вьюном.
## @en Put the climber at the center of the ladder, as on a real ladder. Turn off for a wide wall with ivy.
@export var snap_to_center: bool = true
## Скорость лазанья, пикселей в секунду. 0 — как в настройках платформера.
## @en Climbing speed, pixels per second. 0 — as in the platformer settings.
@export_range(0.0, 2000.0, 5.0) var climb_speed: float = 0.0

var _climbers: Array = []


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(GROUP)


## Внутри ли зоны лестницы точка — центр персонажа.
func contains(p: Vector2) -> bool:
	if not enabled:
		return false
	var r := Gde.aabb(object)
	return r.size != Vector2.ZERO and r.grow(1.0).has_point(p)


func zone() -> Rect2:
	return Gde.aabb(object)


## Персонаж сообщает, что лезет или слез: для условия «на лестнице кто-то есть».
func _climber(body: Node, on: bool) -> void:
	if on and not _climbers.has(body):
		_climbers.append(body)
		climb_started.emit(body)
	elif not on:
		_climbers.erase(body)


## @action Разрешить лазать по _PARAM0_: _PARAM1_ (1 да, 0 нет)
## @action.en Allow climbing _PARAM0_: _PARAM1_ (1 yes, 0 no)
## @param on Да или нет
## @param.en on Yes or no
func set_enabled(on: bool) -> void:
	enabled = on


## @condition По _PARAM0_ кто-то лезет
## @condition.en Someone is climbing _PARAM0_
func has_climber() -> bool:
	for c: Variant in _climbers.duplicate():
		if not is_instance_valid(c):
			_climbers.erase(c)
	return not _climbers.is_empty()
