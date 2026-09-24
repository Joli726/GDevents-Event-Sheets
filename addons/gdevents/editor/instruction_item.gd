## Одна строка условия или действия в листе.
##
## Левый клик — выделить, двойной — открыть параметры, правый — меню.
## При наведении справа появляются кнопки: инвертировать, копировать, удалить —
## чтобы удаление не требовало похода в контекстное меню.
## Строку можно перетащить в другое событие или в другую колонку.
@tool
class_name GdeInstructionItem
extends PanelContainer

const DRAG_TYPE := "gde_instruction"

var panel: Control
var path: Array = []
var kind: String = "conditions"
var index: int = 0

var _text: RichTextLabel
var _tools: HBoxContainer
var _hovered: bool = false
var _over_self: bool = false
var _over_button: bool = false
var _pending: bool = false
var _selected: bool = false
var _accent: Color = Color(1, 0.78, 0.42)
var _payload: Dictionary = {}
## Куда встанет брошенная строка: -1 — выше этой, 1 — ниже, 0 — никуда.
var _drop_mark: int = 0


func setup(p: Control, event_path: Array, k: String, i: int, inst: Dictionary,
		def: Variant, accent: Color, selected: bool = false) -> void:
	panel = p
	path = event_path
	kind = k
	index = i
	_accent = accent
	_selected = selected
	_payload = inst.duplicate(true)

	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("panel", _style())
	draw.connect(_draw_drop_mark)

	if def is Dictionary:
		var desc := str((def as Dictionary).get("description", ""))
		tooltip_text = desc if not desc.is_empty() \
				else GdeText.with_labels(def as Dictionary)
	var err: String = panel.instruction_error(path, k, i)
	if not err.is_empty():
		tooltip_text = GdeI18n.t("Ошибка: %s\n\n%s") % [err, tooltip_text]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	var icon := TextureRect.new()
	icon.texture = GdeIcons.for_instruction(def, k)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color(1, 1, 1, 0.75)
	row.add_child(icon)

	if not err.is_empty():
		var bad := Label.new()
		bad.text = "!"
		bad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bad.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
		bad.add_theme_font_size_override("font_size", 14)
		row.add_child(bad)

	if inst.get("disabled", false):
		var off := Label.new()
		off.text = GdeI18n.t("ВЫКЛ")
		off.mouse_filter = Control.MOUSE_FILTER_IGNORE
		off.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		off.add_theme_font_size_override("font_size", 10)
		row.add_child(off)

	if inst.get("inverted", false):
		var marker := Label.new()
		marker.text = GdeI18n.t("НЕ")
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
		marker.add_theme_font_size_override("font_size", 10)
		row.add_child(marker)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.text = GdeText.with_values(def, inst, accent)
	row.add_child(_text)

	# Кнопки всегда занимают своё место и только проявляются при наведении.
	# Если их прятать целиком, текст при появлении сужается, переносится,
	# и строка прыгает по высоте прямо под курсором.
	_tools = HBoxContainer.new()
	_tools.add_theme_constant_override("separation", 0)
	row.add_child(_tools)
	if kind == "conditions":
		_tools.add_child(_tool_button("invert", GdeI18n.t("Инвертировать (НЕ)"), func():
			panel.invert_instruction(path, kind, index)))
	_tools.add_child(_tool_button("copy", GdeI18n.t("Копировать (Ctrl+C)"), func():
		panel.copy_instruction(path, kind, index)))
	_tools.add_child(_tool_button("trash", GdeI18n.t("Удалить (Delete)"), func():
		panel.remove_instruction(path, kind, index)))

	if inst.get("disabled", false):
		modulate = Color(1, 1, 1, 0.4)

	mouse_entered.connect(func():
		_over_self = true
		_schedule())
	mouse_exited.connect(func():
		_over_self = false
		_schedule())
	for b: Node in _tools.get_children():
		(b as Control).mouse_entered.connect(func():
			_over_button = true
			_schedule())
		(b as Control).mouse_exited.connect(func():
			_over_button = false
			_schedule())
	_apply_hover()


## Кнопки видны, пока курсор над строкой ИЛИ над одной из её кнопок.
##
## Godot шлёт строке mouse_exited, как только курсор переходит на её же
## кнопку: кнопка забирает события мыши себе. Раньше кнопки в этот момент
## прятались, курсор снова оказывался над строкой, они появлялись — и так
## каждый кадр, а клик уходил в пустоту. Теперь решение откладывается до
## конца обработки события: «ушёл со строки» и «пришёл на кнопку» приходят
## парой, и смотреть надо на итог, а не на первый сигнал.
func _schedule() -> void:
	if _pending:
		return
	_pending = true
	_settle.call_deferred()


func _settle() -> void:
	_pending = false
	var v := _over_self or _over_button
	if v != _hovered:
		_hovered = v
		_apply_hover()


func _apply_hover() -> void:
	_tools.modulate.a = 1.0 if _hovered else 0.0
	# Невидимые кнопки не должны ловить клики — иначе можно нечаянно
	# удалить строку, щёлкнув по пустому на вид месту.
	for b: Node in _tools.get_children():
		(b as Control).mouse_filter = Control.MOUSE_FILTER_STOP if _hovered \
				else Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", _style())


func _tool_button(icon: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.icon = GdeIcons.get_icon(icon)
	b.tooltip_text = tip
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(22, 20)
	b.pressed.connect(cb)
	return b


func set_selected(v: bool) -> void:
	if _selected == v:
		return
	_selected = v
	add_theme_stylebox_override("panel", _style())


func _style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if _selected:
		sb.bg_color = Color(_accent.r, _accent.g, _accent.b, 0.16)
		sb.border_color = Color(_accent.r, _accent.g, _accent.b, 0.75)
		sb.border_width_left = 2
	else:
		sb.bg_color = Color(1, 1, 1, 0.07) if _hovered else Color(1, 1, 1, 0.0)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.set_corner_radius_all(3)
	return sb


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if mb.double_click:
			panel.edit_instruction(path, kind, index)
		else:
			panel.select_instruction(path, kind, index)
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		# Точку для меню берём ДО выделения: раньше выделение перерисовывало
		# лист, строка выпадала из дерева, и её координаты становились (0, 0) —
		# меню открывалось в левом верхнем углу.
		var at := get_screen_position() + mb.position
		panel.select_instruction(path, kind, index)
		panel.instruction_menu(path, kind, index, at)


# -------------------------------------------------------------- перетаскивание ---

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
	l.text = _text.get_parsed_text().strip_edges()
	l.clip_text = true
	l.custom_minimum_size = Vector2(260, 0)
	preview.add_child(l)
	set_drag_preview(preview)
	return {
		"type": DRAG_TYPE,
		"kind": kind,
		"path": path.duplicate(),
		"index": index,
		"data": _payload.duplicate(true),
	}


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary \
			and str((data as Dictionary).get("type", "")) == DRAG_TYPE \
			and str((data as Dictionary).get("kind", "")) == kind
	var mark := 0
	if ok:
		mark = -1 if at.y < size.y * 0.5 else 1
		panel.mark_drop(self)
	if mark != _drop_mark:
		_drop_mark = mark
		queue_redraw()
	return ok


## Бросок ложится туда, где горела линия-подсказка, а не туда, куда
## укажет координата в момент отпускания: при резком движении мыши они
## расходятся, и строка вставала не там, где обещала подсказка.
func _drop_data(at: Vector2, data: Variant) -> void:
	var side := _drop_mark
	if side == 0:
		side = -1 if at.y < size.y * 0.5 else 1
	clear_drop_mark()
	var d: Dictionary = data
	panel.drop_instruction(d, path, kind, index if side < 0 else index + 1)


func clear_drop_mark() -> void:
	if _drop_mark != 0:
		_drop_mark = 0
		queue_redraw()


## Линия там, куда встанет строка, — видно заранее, а не после броска.
func _draw_drop_mark() -> void:
	if _drop_mark == 0:
		return
	var y := 0.0 if _drop_mark < 0 else size.y - 2.0
	draw_rect(Rect2(0, y, size.x, 2), Color(_accent.r, _accent.g, _accent.b, 0.95))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		clear_drop_mark()
