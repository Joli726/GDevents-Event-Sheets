## Одно событие в листе: карточка в две колонки плюс отступлённые подсобытия.
##
## Слева условия, справа действия — как в GDevelop. Полоска слева от карточки
## одновременно ручка перетаскивания и кнопка меню. Справа вверху при
## наведении появляются кнопки: дублировать, выключить, удалить.
@tool
class_name GdeEventRow
extends VBoxContainer

const INDENT := 22
const COL_SEPARATION := 8

var panel: Control
var path: Array = []

var _type: String = "standard"
var _accent: Color = Color(1, 0.78, 0.42)
var _tools: HBoxContainer


func setup(p: Control, event_path: Array, e: Dictionary, accent: Color) -> void:
	panel = p
	path = event_path
	_accent = accent
	_type = str(e.get("type", "standard"))
	add_theme_constant_override("separation", 2)

	var disabled: bool = e.get("disabled", false)

	if _type == "comment":
		add_child(_build_comment(e))
	else:
		var card := _build_card(e, accent)
		if disabled:
			card.modulate = Color(1, 1, 1, 0.45)
		add_child(card)

	var children: Array = e.get("children", [])
	if not children.is_empty() and e.get("folded", false):
		add_child(_folded_note(children.size()))
	elif not children.is_empty():
		var wrap := HBoxContainer.new()
		wrap.add_theme_constant_override("separation", 0)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(INDENT, 0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(spacer)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 2)
		wrap.add_child(box)
		add_child(wrap)
		for i in range(children.size()):
			var row := GdeEventRow.new()
			box.add_child(row)
			row.setup(panel, path + [i], children[i], accent)


# ------------------------------------------------------------- комментарий ---

## Комментарий — такая же карточка события: его можно выделить, перетащить
## за ручку, и на него можно бросить другое событие.
func _build_comment(e: Dictionary) -> Control:
	var pc := GdeEventCard.new()
	pc.comment = true
	pc.setup(panel, path, _accent, panel.is_event_selected(path))
	pc.set_found(panel.is_event_found(path))

	var row := HBoxContainer.new()
	pc.add_child(row)
	row.add_child(_grip())

	var te := TextEdit.new()
	te.text = str(e.get("text", ""))
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.custom_minimum_size = Vector2(0, 22 + 16 * maxi(0, te.text.count("\n")))
	te.scroll_fit_content_height = true
	te.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	te.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	te.focus_exited.connect(func():
		if te.text != str(e.get("text", "")):
			panel.set_event_field(path, "text", te.text))
	row.add_child(te)
	row.add_child(_row_tools(e))
	return pc


# ---------------------------------------------------------------- карточка ---

func _build_card(e: Dictionary, accent: Color) -> Control:
	var card := GdeEventCard.new()
	card.setup(panel, path, accent, panel.is_event_selected(path))
	card.set_found(panel.is_event_found(path))
	var errs: Array[String] = panel.event_errors(path)
	if not errs.is_empty():
		card.set_errors(errs)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	card.add_child(outer)
	outer.add_child(_grip())

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	outer.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	content.add_child(header)
	if not (e.get("children", []) as Array).is_empty():
		var folded: bool = e.get("folded", false)
		var fb := _tool_button("fold_closed" if folded else "fold_open",
				GdeI18n.t("Развернуть подсобытия") if folded else GdeI18n.t("Свернуть подсобытия"),
				func(): panel.toggle_event_folded(path))
		fb.custom_minimum_size = Vector2(20, 18)
		header.add_child(fb)
	_fill_header(header, e)
	var pad := Control.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(pad)
	header.add_child(_row_tools(e))

	# У подключения и функции нет своих условий и действий: у подключения —
	# только выбор листа, у функции тело — подсобытия.
	if _type == "include" or _type == "function":
		return card

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", COL_SEPARATION)
	content.add_child(cols)

	cols.add_child(_build_column(e, "conditions", GdeI18n.t("Условие"), 0.45, accent))
	var sep := VSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.25)
	cols.add_child(sep)
	cols.add_child(_build_column(e, "actions", GdeI18n.t("Действие"), 0.55, accent))
	return card


## Шапка специальных событий с редактированием прямо на месте.
func _fill_header(row: HBoxContainer, e: Dictionary) -> void:
	_fill_type_header(row, e)
	if e.get("any", false) and _type in ["standard", "foreach", "while"]:
		var any := _caption(GdeI18n.t("Любое из условий (ИЛИ)"))
		any.modulate = _accent
		any.tooltip_text = GdeI18n.t("Событие сработает, если выполнено хотя бы одно условие. Выключить — в меню события")
		any.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(any)
	var locals: Variant = e.get("locals", {})
	if locals is Dictionary and not (locals as Dictionary).is_empty():
		var parts: Array[String] = []
		for k: Variant in (locals as Dictionary):
			var v: Variant = (locals as Dictionary)[k]
			parts.append("%s = %s" % [k, JSON.stringify(v) if v is String else str(GdeSheetDocument._normalize(v))])
		var lb := Button.new()
		lb.flat = true
		lb.focus_mode = Control.FOCUS_NONE
		lb.icon = GdeIcons.get_icon("variable")
		lb.text = GdeI18n.t("Локальные: %s") % ", ".join(parts)
		lb.tooltip_text = GdeI18n.t("Локальные переменные события: живут в нём и его подсобытиях, обнуляются при каждом запуске. Нажмите, чтобы изменить")
		lb.add_theme_font_size_override("font_size", 11)
		lb.pressed.connect(func(): panel.edit_event_locals(path))
		row.add_child(lb)


func _fill_type_header(row: HBoxContainer, e: Dictionary) -> void:
	match _type:
		"foreach":
			row.add_child(_caption(GdeI18n.t("Для каждого объекта")))
			var ob := OptionButton.new()
			# Тип указан явно: panel объявлен как Control, чтобы не делать
			# циклическую ссылку между классами панели и строки.
			var names: Array = panel.object_names()
			var cur := str(e.get("object", ""))
			var sel := -1
			for i in range(names.size()):
				ob.add_item(str(names[i]), i)
				if str(names[i]) == cur:
					sel = i
			if sel < 0 and not cur.is_empty():
				ob.add_item(GdeI18n.t("%s (нет в листе)") % cur, ob.item_count)
				ob.set_item_metadata(ob.item_count - 1, cur)
				sel = ob.item_count - 1
			if ob.item_count == 0:
				ob.add_item(GdeI18n.t("— нет объектов —"), 0)
				ob.set_item_metadata(0, "")
				sel = 0
			ob.selected = maxi(sel, 0)
			ob.item_selected.connect(func(i: int):
				var meta: Variant = ob.get_item_metadata(i)
				panel.set_event_field(path, "object",
						str(meta) if meta != null else ob.get_item_text(i)))
			row.add_child(ob)
		"repeat":
			row.add_child(_caption(GdeI18n.t("Повторить")))
			var le := LineEdit.new()
			le.text = str(e.get("count", "1"))
			le.custom_minimum_size = Vector2(160, 0)
			le.focus_exited.connect(func():
				if le.text != str(e.get("count", "1")):
					panel.set_event_field(path, "count", le.text))
			le.text_submitted.connect(func(t: String): panel.set_event_field(path, "count", t))
			row.add_child(le)
			row.add_child(_caption(GdeI18n.t("раз")))
		"group":
			row.add_child(_caption(GdeI18n.t("Группа")))
			var ne := LineEdit.new()
			ne.text = str(e.get("name", GdeI18n.t("Группа")))
			ne.custom_minimum_size = Vector2(240, 0)
			ne.focus_exited.connect(func():
				if ne.text != str(e.get("name", "")):
					panel.set_event_field(path, "name", ne.text))
			ne.text_submitted.connect(func(t: String): panel.set_event_field(path, "name", t))
			row.add_child(ne)
		"while":
			row.add_child(_caption(GdeI18n.t("Пока выполняется")))
		"function":
			var icon := TextureRect.new()
			icon.texture = GdeIcons.get_icon("function")
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(18, 18)
			row.add_child(icon)
			var kind := OptionButton.new()
			kind.add_item(GdeI18n.t("Действие"), 0)
			kind.add_item(GdeI18n.t("Условие"), 1)
			kind.selected = 1 if str(e.get("kind", "action")) == "condition" else 0
			kind.tooltip_text = GdeI18n.t("Условие отвечает действием «Вернуть: условие истинно»")
			kind.item_selected.connect(func(i: int):
				panel.set_event_field(path, "kind", "condition" if i == 1 else "action"))
			row.add_child(kind)
			var ne := LineEdit.new()
			ne.text = str(e.get("name", ""))
			ne.placeholder_text = GdeI18n.t("Имя латиницей")
			ne.custom_minimum_size = Vector2(150, 0)
			ne.tooltip_text = GdeI18n.t("Имя функции: латинские буквы, цифры и _")
			ne.focus_exited.connect(func():
				if ne.text != str(e.get("name", "")):
					panel.set_event_field(path, "name", ne.text))
			ne.text_submitted.connect(func(t: String): panel.set_event_field(path, "name", t))
			row.add_child(ne)
			var se := LineEdit.new()
			se.text = str(e.get("sentence", ""))
			se.placeholder_text = GdeI18n.t("Фраза: Ранить _PARAM0_ на _PARAM1_")
			se.custom_minimum_size = Vector2(260, 0)
			se.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			se.tooltip_text = GdeI18n.t("Как функция читается в листе. _PARAM0_, _PARAM1_… — параметры по порядку")
			se.focus_exited.connect(func():
				if se.text != str(e.get("sentence", "")):
					panel.set_event_field(path, "sentence", se.text))
			se.text_submitted.connect(func(t: String): panel.set_event_field(path, "sentence", t))
			row.add_child(se)
			var pb := Button.new()
			var names: Array[String] = []
			for pr: Variant in e.get("params", []):
				if pr is Dictionary:
					names.append("%s: %s" % [(pr as Dictionary).get("name", ""), (pr as Dictionary).get("kind", "")])
			pb.text = GdeI18n.t("Параметры: %s") % (", ".join(names) if not names.is_empty() else GdeI18n.t("нет"))
			pb.flat = true
			pb.focus_mode = Control.FOCUS_NONE
			pb.add_theme_font_size_override("font_size", 11)
			pb.pressed.connect(func(): panel.edit_function_params(path))
			row.add_child(pb)
		"include":
			var cap := _caption(GdeI18n.t("Подключить лист"))
			row.add_child(cap)
			var ob := OptionButton.new()
			var cur := str(e.get("sheet", ""))
			var sheets: Array[String] = panel.includable_sheets()
			var sel := -1
			for i in range(sheets.size()):
				ob.add_item(sheets[i].replace("res://", ""), i)
				ob.set_item_metadata(i, sheets[i])
				if sheets[i] == cur:
					sel = i
			if sel < 0:
				var label := GdeI18n.t("— выберите лист —")
				if not cur.is_empty():
					label = cur.replace("res://", "") if FileAccess.file_exists(cur) else GdeI18n.t("%s (нет такого листа)") % cur
				ob.add_item(label, ob.item_count)
				ob.set_item_metadata(ob.item_count - 1, cur)
				sel = ob.item_count - 1
			ob.selected = sel
			ob.item_selected.connect(func(i: int):
				panel.set_event_field(path, "sheet", str(ob.get_item_metadata(i))))
			row.add_child(ob)
			if not cur.is_empty():
				var go := Button.new()
				go.flat = true
				go.focus_mode = Control.FOCUS_NONE
				go.icon = GdeIcons.get_icon("edit")
				go.tooltip_text = GdeI18n.t("Открыть подключённый лист")
				go.pressed.connect(func(): panel.go_to_sheet(cur))
				row.add_child(go)


func _build_column(e: Dictionary, kind: String, add_label: String,
		ratio: float, accent: Color) -> Control:
	var col := GdeInstructionColumn.new()
	col.setup(panel, path, kind)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = ratio

	# У «Повторить» и группы своих условий не бывает.
	if kind == "conditions" and (_type == "repeat" or _type == "group"):
		var stub := Label.new()
		stub.text = "—"
		stub.modulate = Color(1, 1, 1, 0.25)
		col.add_child(stub)
		return col

	var list: Array = e.get(kind, [])
	for i in range(list.size()):
		var inst: Dictionary = list[i]
		var def: Variant = panel.instruction_def(kind, str(inst.get("id", "")))
		var item := GdeInstructionItem.new()
		col.add_child(item)
		item.setup(panel, path, kind, i, inst, def, accent,
				panel.is_instruction_selected(path, kind, i))

	col.add_child(_add_row(kind, add_label))
	return col


## «+ Условие» и справа от него — «Вставить условие», как в GDevelop.
## Кнопка вставки появляется при наведении и только если в буфере строка
## того же рода: условие в колонку действий не вставить.
func _add_row(kind: String, add_label: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var add := Button.new()
	add.text = "+ %s" % add_label
	add.flat = true
	add.focus_mode = Control.FOCUS_NONE
	add.alignment = HORIZONTAL_ALIGNMENT_LEFT
	add.modulate = Color(1, 1, 1, 0.5)
	add.add_theme_font_size_override("font_size", 11)
	add.pressed.connect(func(): panel.add_instruction(path, kind))
	row.add_child(add)

	var paste := Button.new()
	paste.text = GdeI18n.t("Вставить %s") % (GdeI18n.t("условие") if kind == "conditions" else GdeI18n.t("действие"))
	paste.flat = true
	paste.focus_mode = Control.FOCUS_NONE
	paste.icon = GdeIcons.get_icon("paste")
	paste.add_theme_font_size_override("font_size", 11)
	paste.add_theme_color_override("font_color", _accent)
	paste.visible = false
	paste.set_meta("gde_paste_kind", kind)
	paste.pressed.connect(func(): panel.paste_instruction_into(path, kind))
	row.add_child(paste)

	# Наведение считаем по трём участникам: пустое место ряда, «+» и сама
	# «Вставить». Решение — после пары сигналов «ушёл / пришёл»: при переходе
	# с «+» на «Вставить» иначе кнопка пряталась бы из-под курсора.
	var state := {"row": false, "add": false, "paste": false, "pending": false}
	var settle := func():
		state["pending"] = false
		if not is_instance_valid(paste):
			return
		var over: bool = state["row"] or state["add"] or state["paste"]
		var clip: String = panel.clipboard_kind()
		var show := over and clip == kind
		if show:
			paste.tooltip_text = GdeI18n.t("Вставить в это событие:\n%s") % panel.clipboard_text()
		paste.visible = show
	var mark := func(key: String, v: bool):
		state[key] = v
		if not state["pending"]:
			state["pending"] = true
			settle.call_deferred()
	row.mouse_entered.connect(mark.bind("row", true))
	row.mouse_exited.connect(mark.bind("row", false))
	add.mouse_entered.connect(mark.bind("add", true))
	add.mouse_exited.connect(mark.bind("add", false))
	paste.mouse_entered.connect(mark.bind("paste", true))
	paste.mouse_exited.connect(mark.bind("paste", false))
	return row


# ------------------------------------------------------------------ мелочи ---

## Вместо свёрнутых подсобытий — строка «скрыто: N», по нажатию разворачивает.
func _folded_note(n: int) -> Control:
	var wrap := HBoxContainer.new()
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(INDENT, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(spacer)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.icon = GdeIcons.get_icon("fold_closed")
	b.text = GdeI18n.t("свёрнуто подсобытий: %d") % n
	b.tooltip_text = GdeI18n.t("Развернуть подсобытия")
	b.modulate = Color(1, 1, 1, 0.55)
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func(): panel.toggle_event_folded(path))
	wrap.add_child(b)
	return wrap


## Кнопки события. Показываются при наведении на карточку: постоянно висящий
## ряд иконок шумит, а прятать удаление в правую кнопку — неудобно.
func _row_tools(e: Dictionary) -> Control:
	_tools = HBoxContainer.new()
	_tools.add_theme_constant_override("separation", 0)
	# Полупрозрачны, пока на них не навелись: видно, что они есть,
	# но они не перетягивают внимание с самого события.
	_tools.modulate = Color(1, 1, 1, 0.3)
	_tools.add_child(_tool_button("copy", GdeI18n.t("Дублировать (Ctrl+D)"),
			func(): panel.duplicate_event(path)))
	var off: bool = e.get("disabled", false)
	_tools.add_child(_tool_button("disabled",
			GdeI18n.t("Включить") if off else GdeI18n.t("Выключить"),
			func(): panel.toggle_event_disabled(path)))
	_tools.add_child(_tool_button("trash", GdeI18n.t("Удалить событие (Delete)"),
			func(): panel.remove_event(path)))
	# Та же ловушка, что у строк: при переходе на кнопку ряд получает
	# mouse_exited и тускнел прямо под курсором. Считаем «над рядом или над
	# кнопкой» и решаем после того, как придут оба сигнала.
	var tools := _tools
	var state := {"row": false, "button": false, "pending": false}
	var settle := func():
		state["pending"] = false
		var lit: bool = state["row"] or state["button"]
		if is_instance_valid(tools):
			tools.modulate = Color(1, 1, 1, 1.0 if lit else 0.3)
	var mark := func(key: String, v: bool):
		state[key] = v
		if not state["pending"]:
			state["pending"] = true
			settle.call_deferred()
	tools.mouse_entered.connect(mark.bind("row", true))
	tools.mouse_exited.connect(mark.bind("row", false))
	for b: Node in tools.get_children():
		(b as Control).mouse_entered.connect(mark.bind("button", true))
		(b as Control).mouse_exited.connect(mark.bind("button", false))
	return tools


func _tool_button(icon: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.icon = GdeIcons.get_icon(icon)
	b.tooltip_text = tip
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(24, 20)
	b.pressed.connect(cb)
	return b


## Узкая полоска слева: клик открывает меню, перетаскивание двигает событие.
func _grip() -> Control:
	var g := GdeEventGrip.new()
	g.setup(panel, path, _accent)
	return g


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.7)
	return l
