## Область, принимающая сцены из файловой системы редактора.
##
## Добавление объекта через форму внизу никуда не делось, но перетащить
## .tscn мышью — движение, которого ждёшь в первую очередь.
@tool
class_name GdeSceneDrop
extends PanelContainer

signal dropped(paths: Array)

var _hot: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", _style())


func _style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if _hot:
		sb.bg_color = Color(1, 1, 1, 0.06)
		sb.border_color = Color(0.55, 0.75, 1.0, 0.8)
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(1, 1, 1, 0.08)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(2)
	return sb


func _set_hot(v: bool) -> void:
	if _hot == v:
		return
	_hot = v
	add_theme_stylebox_override("panel", _style())


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	var ok := not scenes_in(data).is_empty()
	_set_hot(ok)
	return ok


func _drop_data(_at: Vector2, data: Variant) -> void:
	_set_hot(false)
	var list := scenes_in(data)
	if not list.is_empty():
		dropped.emit(list)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_hot(false)


## Пути сцен в перетаскиваемом. Файловая система редактора отдаёт
## {"type": "files", "files": [...]} — берём из него только .tscn.
static func scenes_in(data: Variant) -> Array[String]:
	var out: Array[String] = []
	if not (data is Dictionary):
		return out
	var d: Dictionary = data
	if str(d.get("type", "")) != "files":
		return out
	for f: Variant in d.get("files", []):
		var p := str(f)
		if p.ends_with(".tscn"):
			out.append(p)
	return out
