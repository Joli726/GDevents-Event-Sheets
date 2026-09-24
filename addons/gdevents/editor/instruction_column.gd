## Колонка условий или действий внутри события.
##
## Нужна отдельным классом ради одного: принимать перетаскивание. Бросок
## в пустую колонку или ниже последней строки должен работать — иначе
## перенести единственное условие в пустое событие было бы нечем.
@tool
class_name GdeInstructionColumn
extends VBoxContainer

var panel: Control
var path: Array = []
var kind: String = "conditions"

var _highlight: bool = false


func setup(p: Control, event_path: Array, k: String) -> void:
	panel = p
	path = event_path
	kind = k
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 1)
	draw.connect(_draw_marker)


func _draw_marker() -> void:
	if _highlight:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.07), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25), false, 1.0)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary \
			and str((data as Dictionary).get("type", "")) == GdeInstructionItem.DRAG_TYPE \
			and str((data as Dictionary).get("kind", "")) == kind
	if ok != _highlight:
		_highlight = ok
		queue_redraw()
	return ok


func _drop_data(_at: Vector2, data: Variant) -> void:
	_highlight = false
	queue_redraw()
	panel.drop_instruction(data as Dictionary, path, kind, 9999)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _highlight:
		_highlight = false
		queue_redraw()
