## Ручка события — полоска слева от карточки.
##
## Клик открывает меню события, перетаскивание переставляет событие.
## Вынесена отдельным классом, потому что источник перетаскивания обязан
## переопределять _get_drag_data, а это метод, не сигнал.
@tool
class_name GdeEventGrip
extends Control

var panel: Control
var path: Array = []

var _accent: Color = Color(1, 0.78, 0.42)
var _hot: bool = false
var _pressed: bool = false
var _dragged: bool = false


func setup(p: Control, event_path: Array, accent: Color) -> void:
	panel = p
	path = event_path
	_accent = accent
	custom_minimum_size = Vector2(12, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	tooltip_text = "Меню события. Потяните, чтобы переставить"
	mouse_entered.connect(func():
		_hot = true
		queue_redraw())
	mouse_exited.connect(func():
		_hot = false
		queue_redraw())
	draw.connect(_draw_grip)


func _draw_grip() -> void:
	var w := 2.0
	var x := (size.x - w) * 0.5
	var c := Color(_accent.r, _accent.g, _accent.b, 0.9) if _hot else Color(1, 1, 1, 0.18)
	draw_rect(Rect2(x, 2, w, maxf(0.0, size.y - 4)), c)


## Правая кнопка — меню сразу. Левая — меню по ОТПУСКАНИЮ и только если
## событие не потащили. Раньше меню открывалось по нажатию левой, а открытое
## меню забирает мышь себе — утащить событие за ручку было невозможно.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null:
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		accept_event()
		var at := get_screen_position() + mb.position
		panel.select_event(path)
		panel.event_menu(path, at)
	elif mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if mb.pressed:
			_pressed = true
			_dragged = false
			panel.select_event(path)
		elif _pressed:
			_pressed = false
			if not _dragged:
				panel.event_menu(path, get_screen_position() + mb.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN and _pressed:
		_dragged = true
	elif what == NOTIFICATION_DRAG_END:
		_pressed = false


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.17, 0.95)
	sb.border_color = Color(_accent.r, _accent.g, _accent.b, 0.8)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(6)
	sb.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = panel.event_summary(path)
	l.clip_text = true
	l.custom_minimum_size = Vector2(280, 0)
	preview.add_child(l)
	set_drag_preview(preview)
	return {"type": GdeEventCard.DRAG_TYPE, "path": path.duplicate()}
