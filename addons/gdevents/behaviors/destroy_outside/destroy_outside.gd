## Поведение «За краем экрана».
##
## @behavior DestroyOutside
## @title За краем экрана
## @description Что делать, когда объект ушёл за край: удалить, перенести на противоположную сторону или не выпускать.
## @icon trash
@tool
extends GdeBehavior

## Ушёл за край.
signal left_screen
## Перенесён на противоположную сторону.
signal wrapped

@export_group("Поведение")
## Что делать за краем — удалить, зациклить или не выпускать. Удалить для пуль, зациклить как в «Астероидах», не выпускать для игрока.
@export_enum("Удалить", "Зациклить", "Не выпускать") var mode: int = 0
## Запас за краем — сколько пикселей объект может зайти, прежде чем сработает.
@export_range(0.0, 1000.0, 4.0) var margin: float = 64.0
## Отсрочка после создания — сколько секунд не трогать объект. Спасает тех, кто рождён за экраном.
@export_range(0.0, 10.0, 0.1) var grace_time: float = 0.0

@export_group("Какие края считать")
## Следить за левым краем.
@export var left: bool = true
## Следить за правым краем.
@export var right: bool = true
## Следить за верхним краем.
@export var top: bool = true
## Следить за нижним краем.
@export var bottom: bool = true

var _age: float = 0.0
var _was_outside: bool = false


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	_age += delta
	if _age < grace_time:
		return

	var vp := o.get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	var xf := vp.get_canvas_transform()
	var p := xf * o.global_position

	var out_l := left and p.x < r.position.x - margin
	var out_r := right and p.x > r.end.x + margin
	var out_t := top and p.y < r.position.y - margin
	var out_b := bottom and p.y > r.end.y + margin
	var outside := out_l or out_r or out_t or out_b

	if outside and not _was_outside:
		left_screen.emit()
	_was_outside = outside

	match mode:
		1:
			if outside:
				var np := p
				if out_l:
					np.x = r.end.x + margin
				elif out_r:
					np.x = r.position.x - margin
				if out_t:
					np.y = r.end.y + margin
				elif out_b:
					np.y = r.position.y - margin
				o.global_position = xf.affine_inverse() * np
				wrapped.emit()
		2:
			var half := Gde.aabb(o).size * 0.5
			var hp := xf.basis_xform(half)
			var cp := Vector2(
					clampf(p.x, r.position.x + hp.x, r.end.x - hp.x),
					clampf(p.y, r.position.y + hp.y, r.end.y - hp.y))
			if cp != p:
				o.global_position = xf.affine_inverse() * cp
		_:
			if outside:
				Gde.delete_object(o)


## @action Режим краёв для _PARAM0_: _PARAM1_ (0 удалить, 1 зациклить, 2 не выпускать)
func set_edge_mode(new_mode: float) -> void:
	mode = clampi(int(new_mode), 0, 2)


## @condition _PARAM0_ за пределами экрана
func is_outside() -> bool:
	return not Gde.on_screen(object)


## @expression Сколько секунд объект существует
func age() -> float:
	return _age
