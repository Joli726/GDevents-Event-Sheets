## Поведение «Перетаскиваемый».
##
## @behavior Draggable
## @title Перетаскиваемый
## @title.en Draggable
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Перетаскивание мышью с сеткой, ограничением осей, плавным следованием и возвратом на место.
## @description.en Mouse dragging with a grid, axis locking, smooth following and returning home.
## @icon drag
@tool
extends GdeBehavior

## Взяли мышью.
signal grabbed
## Отпустили.
signal dropped

## @group.en Dragging
@export_group("Перетаскивание")
## Перетаскивание включено. Выключите, чтобы временно закрепить объект на месте.
## @en Dragging is on. Turn it off to pin the object in place for a while.
@export var enabled: bool = true
## Кнопка мыши, которой тащат объект.
## @en Mouse button used to drag the object.
## @options.en Left, Right, Middle
@export_enum("Левая:1", "Правая:2", "Средняя:3") var mouse_button: int = 1
## Оси движения — по какой из них объект можно двигать.
## @en Movement axes — along which the object can be moved.
## @options.en Both axes, X only, Y only
@export_enum("Обе оси", "Только по X", "Только по Y") var axis_lock: int = 0
## Прилипание к сетке в пикселях. 0 — без прилипания.
## @en Grid snapping in pixels. 0 — no snapping.
@export_range(0.0, 256.0, 1.0) var grid: float = 0.0
## Плавность следования за курсором. 0 — приклеен намертво.
## @en Smoothness of following the cursor. 0 — glued tight.
@export_range(0.0, 1.0, 0.02) var smoothing: float = 0.0
## Хват за точку касания — объект не прыгает центром под курсор.
## @en Grab at the touch point — the object does not jump its center under the cursor.
@export var keep_grab_offset: bool = true

## @group.en Bounds
@export_group("Границы")
## Держать в экране — не выпускать за края.
## @en Keep on screen — do not let it past the edges.
@export var clamp_to_screen: bool = false

## @group.en Return
@export_group("Возврат")
## Возврат на место после отпускания.
## @en Return home after release.
@export var return_on_drop: bool = false
## Скорость возврата на место, пикселей в секунду.
## @en Speed of returning home, pixels per second.
@export_range(10.0, 3000.0, 10.0) var return_speed: float = 600.0

## @group.en Look
@export_group("Вид")
## Подъём поверх остальных, пока объект тащат.
## @en Lift above the others while the object is dragged.
@export var lift_while_dragging: bool = true
## Размер во время перетаскивания. 1.1 — чуть крупнее обычного.
## @en Size while dragging. 1.1 — a little bigger than usual.
@export_range(0.5, 2.0, 0.05) var drag_scale: float = 1.0

var _dragging: bool = false
var _grab_offset: Vector2 = Vector2.ZERO
var _home: Vector2 = Vector2.ZERO
var _returning: bool = false
var _base_z: int = 0
var _base_scale: Vector2 = Vector2.ONE
var _saved: bool = false


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _saved:
		_base_z = o.z_index
		_base_scale = o.scale
		_saved = true

	if _returning:
		o.global_position = o.global_position.move_toward(_home, return_speed * delta)
		if o.global_position.distance_to(_home) < 0.5:
			o.global_position = _home
			_returning = false
		return

	var pressed := Input.is_mouse_button_pressed(mouse_button as MouseButton)
	var mouse: Vector2 = Gde.mouse_world()

	if not _dragging:
		if enabled and pressed and Gde.aabb(o).has_point(mouse):
			_dragging = true
			_home = o.global_position
			_grab_offset = (o.global_position - mouse) if keep_grab_offset else Vector2.ZERO
			if lift_while_dragging:
				o.z_index = _base_z + 100
			o.scale = _base_scale * drag_scale
			grabbed.emit()
		return

	if not pressed:
		_dragging = false
		o.z_index = _base_z
		o.scale = _base_scale
		_returning = return_on_drop
		dropped.emit()
		return

	var target := mouse + _grab_offset
	if axis_lock == 1:
		target.y = o.global_position.y
	elif axis_lock == 2:
		target.x = o.global_position.x
	if grid > 0.0:
		target = (target / grid).round() * grid
	if smoothing > 0.0:
		target = o.global_position.lerp(target, clampf((1.0 - smoothing) * 30.0 * delta, 0.0, 1.0))
	if clamp_to_screen:
		target = _clamped(o, target)
	o.global_position = target


func _clamped(o: Node2D, p: Vector2) -> Vector2:
	var vp := o.get_viewport()
	if vp == null:
		return p
	var r := vp.get_visible_rect()
	var inv := vp.get_canvas_transform().affine_inverse()
	var half: Vector2 = Gde.aabb(o).size * 0.5
	var tl := inv * r.position + half
	var br := inv * r.end - half
	return Vector2(clampf(p.x, tl.x, br.x), clampf(p.y, tl.y, br.y))


## @action Разрешить перетаскивание _PARAM0_: _PARAM1_ (1 да, 0 нет)
## @action.en Allow dragging _PARAM0_: _PARAM1_ (1 yes, 0 no)
## @param on 1 да, 0 нет
## @param.en on 1 yes, 0 no
func allow(on: float) -> void:
	enabled = on > 0.5
	if not enabled:
		_dragging = false


## @action Запомнить текущее место _PARAM0_ как домашнее
## @action.en Remember the current place of _PARAM0_ as home
func set_home() -> void:
	var o := object as Node2D
	if o != null:
		_home = o.global_position


## @action Вернуть _PARAM0_ на домашнее место
## @action.en Return _PARAM0_ home
func go_home() -> void:
	_dragging = false
	_returning = true


## @condition _PARAM0_ сейчас тащат
## @condition.en _PARAM0_ is being dragged
func is_dragging() -> bool:
	return _dragging


## @condition _PARAM0_ возвращается на место
## @condition.en _PARAM0_ is returning home
func is_returning() -> bool:
	return _returning


## @expression Расстояние до домашнего места
## @expression.en Distance to the home place
func distance_from_home() -> float:
	var o := object as Node2D
	return o.global_position.distance_to(_home) if o != null else 0.0
