## Настройки одной инструкции — правая колонка окна выбора, как в GDevelop.
##
## Сверху живая фраза с подставленными значениями и описание, ниже поле на
## каждый параметр, подсказки к полю и тумблеры строки. Раньше всё это жило
## в отдельном окне, которое открывалось после выбора, — лишний шаг на
## каждое условие. Теперь щелчок по условию сразу показывает его настройки.
@tool
class_name GdeParamEditor
extends VBoxContainer

## Enter в поле ввода — «готово, добавляй».
signal submitted

const CMP_OPS := ["=", "≠", "<", ">", "≤", "≥"]
const MOD_OPS := ["=", "+", "-", "*", "/"]

var _def: Dictionary = {}
var _id: String = ""
var _kind: String = ""
var _color: Color = Color(1, 0.78, 0.42)
var _reg: GdeRegistry
var _doc: GdeSheetDocument
var _editors: Array[Control] = []
var _active: int = -1
var _pool: Array = []

var _empty: Label
var _content: VBoxContainer
var _preview: RichTextLabel
var _desc: Label
var _grid: GridContainer
var _problem: Label
var _expr_note: Label
var _hint_box: VBoxContainer
var _hints: ItemList
var _hint_text: Label
var _invert: CheckButton
var _disable: CheckButton


func _init() -> void:
	add_theme_constant_override("separation", 0)

	_empty = Label.new()
	_empty.text = GdeI18n.t("Выберите условие или действие —\nего настройки появятся здесь.")
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.modulate = Color(1, 1, 1, 0.45)
	add_child(_empty)

	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	_content.visible = false
	add_child(_content)

	_preview = RichTextLabel.new()
	_preview.bbcode_enabled = true
	_preview.fit_content = true
	_preview.scroll_active = false
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.add_theme_font_size_override("normal_font_size", 15)
	_preview.add_theme_font_size_override("bold_font_size", 15)
	# Минимальная ширина у текста с переносом обязательна: без неё в первый
	# кадр ширина нулевая, текст переносится по букве и распирает окно.
	_preview.custom_minimum_size = Vector2(280, 0)
	_content.add_child(_preview)

	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_theme_font_size_override("font_size", 12)
	_desc.modulate = Color(1, 1, 1, 0.6)
	_desc.custom_minimum_size = Vector2(280, 0)
	_content.add_child(_desc)

	_content.add_child(HSeparator.new())

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(_grid)

	# Ошибка в выражении видна сразу, пока пишешь, — а не при запуске игры.
	_problem = Label.new()
	_problem.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
	_problem.clip_text = true
	_problem.visible = false
	_content.add_child(_problem)

	_expr_note = Label.new()
	_expr_note.text = GdeI18n.t("В полях работают выражения: Player.X(), RandomInRange(0, 5), Variable(score)")
	_expr_note.add_theme_font_size_override("font_size", 11)
	_expr_note.modulate = Color(1, 1, 1, 0.45)
	_expr_note.clip_text = true
	_content.add_child(_expr_note)

	_hint_box = VBoxContainer.new()
	_hint_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hint_box.add_theme_constant_override("separation", 4)
	_hint_box.visible = false
	_content.add_child(_hint_box)

	var cap := Label.new()
	cap.text = GdeI18n.t("ПОДСКАЗКИ — дважды щёлкните, чтобы подставить")
	cap.add_theme_font_size_override("font_size", 10)
	cap.modulate = Color(1, 1, 1, 0.45)
	_hint_box.add_child(cap)

	_hints = ItemList.new()
	_hints.custom_minimum_size = Vector2(0, 100)
	_hints.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hints.allow_reselect = true
	_hints.item_selected.connect(_on_hint_hover)
	_hints.item_activated.connect(_apply_hint)
	_hint_box.add_child(_hints)

	_hint_text = Label.new()
	_hint_text.add_theme_font_size_override("font_size", 11)
	_hint_text.modulate = Color(1, 1, 1, 0.6)
	_hint_text.clip_text = true
	_hint_box.add_child(_hint_text)

	# Пустое место между полями и тумблерами, когда подсказок нет:
	# тумблеры всегда стоят внизу, как в GDevelop.
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.name = "Spacer"
	_content.add_child(spacer)

	_content.add_child(HSeparator.new())
	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 24)
	_content.add_child(toggles)

	_invert = CheckButton.new()
	_invert.text = GdeI18n.t("Инвертировать (НЕ)")
	_invert.tooltip_text = GdeI18n.t("Условие срабатывает, когда оно ЛОЖНО: «НЕ стоит на земле» — в прыжке.\n") \
			+ GdeI18n.t("Выборка переворачивается вместе с ним: остаются экземпляры,\n") \
			+ GdeI18n.t("для которых условие не выполнено.")
	_invert.toggled.connect(func(_on): _refresh_preview())
	toggles.add_child(_invert)

	_disable = CheckButton.new()
	_disable.text = GdeI18n.t("Выключено")
	_disable.tooltip_text = GdeI18n.t("Строка остаётся в листе, но не выполняется и не проверяется.\n") \
			+ GdeI18n.t("Удобно, чтобы временно отключить что-то, не удаляя.")
	_disable.toggled.connect(func(_on): _refresh_preview())
	toggles.add_child(_disable)


# ------------------------------------------------------------------ снаружи ---

## Показать настройки инструкции. kind — "conditions" или "actions":
## у условий есть тумблер «НЕ». flags — {"inverted", "disabled"}.
func edit(id: String, def: Dictionary, params: Array, object_names: Array,
		accent: Color, reg: GdeRegistry, doc: GdeSheetDocument, kind: String,
		flags: Dictionary = {}) -> void:
	_id = id
	_def = def
	_color = accent
	_reg = reg
	_doc = doc
	_kind = kind
	_active = -1
	_invert.visible = kind == "conditions"
	_invert.set_pressed_no_signal(bool(flags.get("inverted", false)) and kind == "conditions")
	_disable.set_pressed_no_signal(bool(flags.get("disabled", false)))
	_empty.visible = false
	_content.visible = true
	_build(params, object_names)
	# Через _set_hints_visible, а не напрямую: вместе с подсказками прячется
	# и распорка, и после окна с подсказками тумблеры иначе липли бы к полям.
	_set_hints_visible(false)
	# Подсказки — через кадр: только что наполненный список на кадр-другой
	# заявляет минимум во всё содержимое и расталкивает окно.
	_first_field_hints.call_deferred()


func clear_editor() -> void:
	_id = ""
	_def = {}
	_editors.clear()
	_empty.visible = true
	_content.visible = false


func has_instruction() -> bool:
	return not _id.is_empty()


func instruction_id() -> String:
	return _id


## Есть ли что вводить руками. Без полей Enter в поиске сразу добавляет.
func has_fields() -> bool:
	for e: Control in _editors:
		if e is LineEdit:
			return true
	return false


func focus_first_field() -> void:
	for e: Control in _editors:
		if e is LineEdit:
			(e as LineEdit).grab_focus()
			(e as LineEdit).select_all()
			return


func current_values() -> Array:
	var out: Array = []
	for e: Control in _editors:
		if e is LineEdit:
			out.append((e as LineEdit).text)
		elif e is OptionButton:
			var ob := e as OptionButton
			var idx := ob.selected
			if idx < 0:
				out.append("")
			else:
				var meta: Variant = ob.get_item_metadata(idx)
				out.append(str(meta) if meta != null else ob.get_item_text(idx))
		else:
			out.append("")
	return out


func current_flags() -> Dictionary:
	return {
		"inverted": _invert.visible and _invert.button_pressed,
		"disabled": _disable.button_pressed,
	}


# ------------------------------------------------------------------- поля ---

func _build(params: Array, object_names: Array) -> void:
	for c: Node in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_editors.clear()

	var defs: Array = _def.get("params", [])
	var has_expression := false
	for i in range(defs.size()):
		var pd: Dictionary = defs[i]
		var kind := str(pd.get("kind", "number"))
		var value := str(params[i]) if i < params.size() else ""

		var label := Label.new()
		label.text = str(pd.get("label", GdeI18n.t("Параметр %d") % (i + 1)))
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_grid.add_child(label)

		var editor: Control
		match kind:
			"object", "objname":
				editor = _make_options(object_names, value, true)
			"cmpop":
				editor = _make_options(CMP_OPS, value if not value.is_empty() else "=", false)
			"modop":
				editor = _make_options(MOD_OPS, value if not value.is_empty() else "=", false)
			_:
				var le := LineEdit.new()
				le.text = value
				le.custom_minimum_size = Vector2(200, 0)
				le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var idx := i
				le.text_changed.connect(func(_t):
					_refresh_preview()
					_refresh_hints(idx))
				le.focus_entered.connect(func(): _refresh_hints(idx))
				le.gui_input.connect(func(ev: InputEvent): _field_input(ev, idx))
				le.text_submitted.connect(func(_t): submitted.emit())
				if kind == "number" or kind == "string":
					has_expression = true
					le.placeholder_text = GdeI18n.t("число, текст или выражение")
				editor = le
		_grid.add_child(editor)
		_editors.append(editor)

	_grid.visible = not defs.is_empty()
	_desc.text = str(_def.get("description", ""))
	_desc.visible = not _desc.text.is_empty()
	_expr_note.visible = has_expression
	_refresh_preview()


func _first_field_hints() -> void:
	if not _content.visible:
		return
	for i in range(_editors.size()):
		if _editors[i] is LineEdit:
			_refresh_hints(i)
			return


## Стрелка вниз из поля уводит фокус в список подсказок — там работают
## стрелки и Enter.
func _field_input(ev: InputEvent, idx: int) -> void:
	var k := ev as InputEventKey
	if k == null or not k.pressed:
		return
	if k.keycode == KEY_DOWN and _hint_box.visible and _hints.item_count > 0:
		_active = idx
		_hints.grab_focus()
		_hints.select(0)
		_on_hint_hover(0)
		get_viewport().set_input_as_handled()


func _make_options(items: Array, current: String, editable_text: bool) -> Control:
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var found := -1
	for i in range(items.size()):
		ob.add_item(str(items[i]), i)
		if str(items[i]) == current:
			found = i
	if found < 0:
		# Значение из листа больше не существует — показываем его, а не теряем молча.
		if not current.is_empty():
			ob.add_item(GdeI18n.t("%s (нет в листе)") % current, items.size())
			ob.set_item_metadata(items.size(), current)
			found = items.size()
		elif editable_text and ob.item_count > 0:
			found = 0
	if ob.item_count == 0:
		ob.add_item(GdeI18n.t("— нет объектов в листе —"), 0)
		ob.set_item_metadata(0, "")
		found = 0
	ob.selected = maxi(found, 0)
	ob.item_selected.connect(func(_i):
		_refresh_preview()
		# Сменился объект — у него другие анимации и поведения.
		if _active >= 0:
			_refresh_hints(_active))
	return ob


# ------------------------------------------------------------- подсказки ---

func _refresh_hints(idx: int) -> void:
	_active = idx
	var defs: Array = _def.get("params", [])
	if idx < 0 or idx >= defs.size():
		_set_hints_visible(false)
		return
	_pool = GdeSuggest.build(_id, idx, defs[idx], _reg, _doc, current_values())
	if _pool.is_empty():
		_set_hints_visible(false)
		return
	_set_hints_visible(true)

	var needle := _token(idx).to_lower()
	_hints.clear()
	var shown := 0
	for c: Variant in _pool:
		var d: Dictionary = c
		var text := str(d["text"])
		if not needle.is_empty() and not text.to_lower().contains(needle):
			continue
		var at := _hints.add_item(text)
		_hints.set_item_metadata(at, d)
		_hints.set_item_tooltip(at, str(d.get("hint", "")))
		shown += 1
		if shown >= 200:
			break
	if _hints.item_count == 0:
		_hints.add_item(GdeI18n.t("— ничего не подошло —"))
		_hints.set_item_disabled(0, true)
	_hint_text.text = ""


func _set_hints_visible(v: bool) -> void:
	_hint_box.visible = v
	(_content.get_node("Spacer") as Control).visible = not v


## Слово под курсором: от последнего разделителя до каретки. По нему идёт
## фильтрация, его же заменяет выбранная подсказка.
func _token(idx: int) -> String:
	if idx < 0 or idx >= _editors.size() or not (_editors[idx] is LineEdit):
		return ""
	var le := _editors[idx] as LineEdit
	var caret: int = le.caret_column
	var text := le.text.substr(0, caret)
	var start := 0
	for i in range(text.length() - 1, -1, -1):
		var ch := text[i]
		var ok := (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") \
				or (ch >= "0" and ch <= "9") or ch == "_" or ch == "." or ch == ":" \
				or ch == "/" or ch == "-"
		if not ok:
			start = i + 1
			break
	return text.substr(start)


func _on_hint_hover(i: int) -> void:
	var meta: Variant = _hints.get_item_metadata(i)
	_hint_text.text = str((meta as Dictionary).get("hint", "")) if meta is Dictionary else ""


func _apply_hint(i: int) -> void:
	var meta: Variant = _hints.get_item_metadata(i)
	if not (meta is Dictionary):
		return
	if _active < 0 or _active >= _editors.size() or not (_editors[_active] is LineEdit):
		return
	var le := _editors[_active] as LineEdit
	var insert := str((meta as Dictionary)["insert"])
	var caret: int = le.caret_column
	var tok := _token(_active)
	var head := le.text.substr(0, caret - tok.length())
	var tail := le.text.substr(caret)
	le.text = head + insert + tail
	le.caret_column = (head + insert).length()
	le.grab_focus()
	_refresh_preview()
	_refresh_hints(_active)


# ---------------------------------------------------------------- фраза ---

func _refresh_preview() -> void:
	var text := GdeText.with_values(_def, {"id": _id, "params": current_values()}, _color)
	if _invert.visible and _invert.button_pressed:
		text = GdeI18n.t("[color=#f07070]НЕ[/color] ") + text
	if _disable.button_pressed:
		text = GdeI18n.t("[color=#8a8a8a][s]%s[/s]  (выключено)[/color]") % text
	_preview.text = text
	_validate()


## Проверить выражения в полях тем же компилятором, что и сборка.
## Поле с ошибкой краснеет, первая ошибка пишется под полями.
func _validate() -> void:
	if _reg == null:
		return
	var defs: Array = _def.get("params", [])
	var first := ""
	if _doc != null:
		for n: String in _doc.object_names():
			GdeExpr.known_objects[n] = true
	for i in range(mini(defs.size(), _editors.size())):
		var le := _editors[i] as LineEdit
		if le == null:
			continue
		var kind := str((defs[i] as Dictionary).get("kind", "number"))
		var bad := ""
		if (kind == "number" or kind == "string") and not le.text.strip_edges().is_empty():
			var r := GdeExpr.compile_as(le.text, kind, "_ctx", _reg)
			var errs: Array = r.get("errors", [])
			if not errs.is_empty():
				bad = str(errs[0])
		if bad.is_empty():
			le.remove_theme_color_override("font_color")
		else:
			le.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
			if first.is_empty():
				first = "«%s»: %s" % [str((defs[i] as Dictionary).get("label", "")), bad]
	GdeExpr.known_objects = {}
	_problem.text = first
	_problem.tooltip_text = first
	_problem.visible = not first.is_empty()
