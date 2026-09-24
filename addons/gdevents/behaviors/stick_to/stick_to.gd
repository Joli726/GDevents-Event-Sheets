## Поведение «Привязка к объекту».
##
## @behavior StickTo
## @title Привязка к объекту
## @title.en Stick to an object
## @description Держится у другого объекта со смещением: полоска здоровья над врагом, оружие в руке, имя над головой. Разворачивается вместе с ним и может исчезнуть вместе с ним.
## @description.en Stays next to another object with an offset: a health bar above an enemy, a weapon in a hand, a name above a head. Turns together with it and can disappear together with it.
## @icon stick
@tool
extends GdeBehavior

## Объект, к которому привязан, исчез.
signal target_lost

## @group.en Target
@export_group("К чему")
## К какому объекту держаться — имя из листа, например Enemy. Берётся ближайший в момент привязки.
## @en Which object to stay at — a name from the sheet, e.g. Enemy. The nearest one at the moment of sticking is taken.
@export var target_object: String = ""
## Исчезнуть вместе с ним.
## @en Disappear together with it.
@export var delete_with_target: bool = true
## Привязка включена.
## @en Sticking is on.
@export var running: bool = true

## @group.en Offset
@export_group("Смещение")
## Смещение по X, пикселей.
## @en Offset along X, pixels.
@export_range(-2000.0, 2000.0, 1.0) var offset_x: float = 0.0
## Смещение по Y, пикселей. Минус — выше.
## @en Offset along Y, pixels. Minus — higher.
@export_range(-2000.0, 2000.0, 1.0) var offset_y: float = -32.0
## Отражаться вместе с ним: смещение по X меняет сторону, спрайт отражается.
## @en Flip together with it: the X offset changes sides, the sprite flips.
@export var follow_flip: bool = true
## Поворачиваться вместе с ним — как оружие в руке.
## @en Rotate together with it — like a weapon in a hand.
@export var follow_rotation: bool = false
## Плавность: 0 — жёстко, ближе к 1 — мягко догоняет.
## @en Smoothness: 0 — rigid, closer to 1 — softly catches up.
@export_range(0.0, 0.99, 0.01) var smoothing: float = 0.0

var _target: Node2D = null
var _had: bool = false


func _physics_process(_delta: float) -> void:
	_follow()


func _process(_delta: float) -> void:
	# И в кадре отрисовки: иначе при частоте экрана выше 60 полоска над
	# врагом отставала бы и дрожала. Плавное догоняние — только в физике,
	# чтобы мягкость не зависела от частоты кадров.
	if smoothing <= 0.0:
		_follow()


func _follow() -> void:
	var o := object as Node2D
	if o == null or not running:
		return
	var t := _find()
	if t == null:
		if _had:
			_had = false
			target_lost.emit()
			if delete_with_target:
				Gde.delete_object(o)
		return
	_had = true
	var flipped := follow_flip and Gde.is_flipped_h(t)
	var off := Vector2(-offset_x if flipped else offset_x, offset_y)
	var rot := 0.0
	if follow_rotation:
		rot = t.global_rotation
		off = off.rotated(rot)
		o.global_rotation = rot
	var want := t.global_position + off
	if smoothing > 0.0:
		o.global_position = o.global_position.lerp(want, 1.0 - smoothing)
	else:
		o.global_position = want
	if follow_flip:
		Gde.set_flip_h(o, flipped)


func _find() -> Node2D:
	if _target != null and is_instance_valid(_target) and _target.is_inside_tree() \
			and not _target.is_queued_for_deletion():
		return _target
	_target = null
	if target_object.is_empty() or _had:
		return null
	var o := object as Node2D
	var best_d := INF
	for n: Node in Gde.all_instances(target_object):
		var m := Gde.main(n)
		if m == null or m == o or n == o:
			continue
		var d := m.global_position.distance_squared_to(o.global_position)
		if d < best_d:
			best_d = d
			_target = m
	return _target


## @action Привязать _PARAM0_ к ближайшему объекту _PARAM1_
## @action.en Stick _PARAM0_ to the nearest object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func stick_to(name: String) -> void:
	target_object = name
	_target = null
	_had = false
	running = true


## @action Смещение привязки _PARAM0_: _PARAM1_ ; _PARAM2_
## @action.en Sticking offset of _PARAM0_: _PARAM1_ ; _PARAM2_
## @param x X
## @param y Y
func set_offset(x: float, y: float) -> void:
	offset_x = x
	offset_y = y


## @action Отвязать _PARAM0_
## @action.en Unstick _PARAM0_
func unstick() -> void:
	running = false
	_target = null
	_had = false


## @condition _PARAM0_ привязан к объекту
## @condition.en _PARAM0_ is stuck to an object
func is_stuck() -> bool:
	return running and _target != null and is_instance_valid(_target)
