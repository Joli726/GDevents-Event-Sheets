## Код поведения — как оно устроено внутри. Вкладка «Код» у поведения
## в окне объектов.
##
## Только чтение: править код удобнее в редакторе скриптов Godot, где
## есть автодополнение, подсветка ошибок и отладчик, — туда ведёт кнопка.
## Встроенное поведение туда не открывается: править его нельзя, для этого
## есть своя копия (GdeBehaviorLibrary). Полоса сверху говорит, что перед
## нами — встроенное, своя копия или своё, — и не сломан ли скрипт.
## «Перейти к…» перечисляет действия, условия и выражения поведения теми же
## фразами, что и в листе событий, и ставит курсор на их функцию.
##
## Здесь же версии: «Запомнить текущую версию», просмотр и восстановление
## любой из них, сравнение своей копии со встроенной и напоминание, если
## встроенная обновилась после того, как сделали копию.
@tool
class_name GdeBehaviorCode
extends VBoxContainer

## Попросили открыть скрипт в редакторе Godot — окну объектов пора уступить.
signal opened_in_editor
signal copy_requested
signal reset_requested
signal derive_requested
signal remember_requested
signal restore_requested(version_path: String, version_title: String)
signal accept_builtin_requested

var script_path: String = ""
var kind: String = ""
var broken: bool = false

var _state: PanelContainer
var _state_style: StyleBoxFlat
var _state_text: Label
var _btn_copy: Button
var _btn_reset: Button
var _btn_derive: Button
var _versions: MenuButton
var _btn_compare: Button
var _update_box: HBoxContainer

## Что показано в поле кода: "code" — текущий код, "compare" — отличия от
## встроенной, "version" — сохранённая версия, "update" — что изменилось
## во встроенной после копии.
var mode: String = "code"
var _entry: Dictionary = {}
var _src: String = ""
var _version_list: Array = []
var _shown_version: Dictionary = {}
var _view: PanelContainer
var _view_text: Label
var _view_diff: Button
var _view_restore: Button
var _view_accept: Button

var _bar: HBoxContainer
var _path: Label
var _jump: MenuButton
var _open: Button
var _code: CodeEdit
## пункт «Перейти к…» -> номер строки
var _jump_lines: Array[int] = []


func _init() -> void:
	add_theme_constant_override("separation", 6)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_state = PanelContainer.new()
	_state_style = StyleBoxFlat.new()
	_state_style.set_content_margin_all(8)
	_state_style.set_corner_radius_all(4)
	_state_style.border_width_left = 3
	_state.add_theme_stylebox_override("panel", _state_style)
	add_child(_state)
	var state_box := VBoxContainer.new()
	state_box.add_theme_constant_override("separation", 6)
	_state.add_child(state_box)
	_state_text = Label.new()
	_state_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_state_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_state_text.add_theme_font_size_override("font_size", 12)
	# Без минимальной ширины автоперенос при первой раскладке считает текст
	# в колонку по слову и раздувает высоту окна за край экрана.
	_state_text.custom_minimum_size = Vector2(360, 0)
	state_box.add_child(_state_text)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	state_box.add_child(actions)
	_btn_copy = Button.new()
	_btn_copy.text = "Изменить поведение…"
	_btn_copy.icon = GdeIcons.get_icon("edit")
	_btn_copy.tooltip_text = "Сделать свою копию: она заменит встроенное поведение у всех объектов, а встроенное останется нетронутым"
	_btn_copy.pressed.connect(func() -> void: copy_requested.emit())
	actions.add_child(_btn_copy)
	_btn_reset = Button.new()
	_btn_reset.text = "Вернуть встроенную…"
	_btn_reset.icon = GdeIcons.get_icon("undo")
	_btn_reset.tooltip_text = "Все объекты снова работают на встроенной версии; копия уйдёт в историю версий"
	_btn_reset.pressed.connect(func() -> void: reset_requested.emit())
	actions.add_child(_btn_reset)
	_btn_derive = Button.new()
	_btn_derive.text = "Новое на основе…"
	_btn_derive.icon = GdeIcons.get_icon("copy")
	_btn_derive.tooltip_text = "Отдельное поведение с новым именем — например, «Выстрел врага» рядом с «Выстрелом игрока»"
	_btn_derive.pressed.connect(func() -> void: derive_requested.emit())
	actions.add_child(_btn_derive)
	_versions = MenuButton.new()
	_versions.text = "Версии ▾"
	_versions.flat = false
	_versions.tooltip_text = "Запомнить текущий код и вернуться к любой сохранённой версии"
	_versions.get_popup().id_pressed.connect(_on_version_menu)
	actions.add_child(_versions)
	_btn_compare = Button.new()
	_btn_compare.text = "Сравнить со встроенной"
	_btn_compare.tooltip_text = "Что изменено в копии относительно встроенного поведения"
	_btn_compare.pressed.connect(show_compare)
	actions.add_child(_btn_compare)

	# Плагин обновился, а копия живёт старым кодом встроенного.
	_update_box = HBoxContainer.new()
	_update_box.add_theme_constant_override("separation", 6)
	state_box.add_child(_update_box)
	var upd := Label.new()
	upd.text = "Встроенная версия обновилась после того, как вы сделали копию — в копию обновление само не попало."
	upd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upd.custom_minimum_size = Vector2(240, 0)
	upd.add_theme_font_size_override("font_size", 12)
	upd.modulate = Color(1.0, 0.8, 0.45)
	_update_box.add_child(upd)
	var what := Button.new()
	what.text = "Что изменилось"
	what.pressed.connect(show_builtin_update)
	_update_box.add_child(what)

	_bar = HBoxContainer.new()
	_bar.add_theme_constant_override("separation", 6)
	add_child(_bar)

	_path = Label.new()
	_path.modulate = Color(1, 1, 1, 0.5)
	_path.add_theme_font_size_override("font_size", 11)
	_path.clip_text = true
	_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.add_child(_path)

	_jump = MenuButton.new()
	_jump.text = "Перейти к… ▾"
	_jump.flat = false
	_jump.tooltip_text = "Действия, условия и выражения поведения — как в листе событий"
	_jump.get_popup().id_pressed.connect(_on_jump)
	_bar.add_child(_jump)

	_open = Button.new()
	_open.text = "Открыть в редакторе скриптов"
	_open.icon = GdeIcons.get_icon("edit")
	_open.tooltip_text = "Автодополнение, подсветка ошибок и отладчик — в редакторе скриптов Godot"
	_open.pressed.connect(open_in_script_editor)
	_bar.add_child(_open)

	# Над кодом — что именно показано, если это не текущий код.
	_view = PanelContainer.new()
	var vs := StyleBoxFlat.new()
	vs.bg_color = Color(0.4, 0.55, 0.9, 0.12)
	vs.set_content_margin_all(6)
	vs.set_corner_radius_all(4)
	_view.add_theme_stylebox_override("panel", vs)
	add_child(_view)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_view.add_child(vbox)
	# Надпись — отдельной строкой: рядом с кнопками название версии обрезалось.
	_view_text = Label.new()
	_view_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view_text.clip_text = true
	_view_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(_view_text)
	var vrow := HBoxContainer.new()
	vrow.add_theme_constant_override("separation", 6)
	vbox.add_child(vrow)
	_view_diff = Button.new()
	_view_diff.text = "Отличия от текущего"
	_view_diff.toggle_mode = true
	_view_diff.toggled.connect(func(_on: bool) -> void: _show_version_body())
	vrow.add_child(_view_diff)
	_view_restore = Button.new()
	_view_restore.text = "Восстановить эту версию…"
	_view_restore.icon = GdeIcons.get_icon("undo")
	_view_restore.pressed.connect(func() -> void:
		restore_requested.emit(str(_shown_version.get("path", "")), str(_shown_version.get("title", ""))))
	vrow.add_child(_view_restore)
	_view_accept = Button.new()
	_view_accept.text = "Учтено"
	_view_accept.tooltip_text = "Считать новую встроенную версию точкой отсчёта — напоминание пропадёт"
	_view_accept.pressed.connect(func() -> void: accept_builtin_requested.emit())
	vrow.add_child(_view_accept)
	var back := Button.new()
	back.text = "К текущему коду"
	back.pressed.connect(show_current)
	vrow.add_child(back)

	_code = CodeEdit.new()
	_code.editable = false
	_code.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_code.gutters_draw_line_numbers = true
	_code.highlight_current_line = true
	_code.minimap_draw = false
	_code.syntax_highlighter = _highlighter()
	add_child(_code)


## Показать исходник поведения. entry — его запись в реестре: из неё
## берутся фразы для «Перейти к…».
func show_script(path: String, entry: Dictionary = {}) -> void:
	script_path = path
	_path.text = path
	_path.tooltip_text = path
	var src := ""
	if not path.is_empty() and FileAccess.file_exists(path):
		src = FileAccess.get_file_as_string(path)
	_entry = entry
	_src = src
	show_current()
	_code.set_caret_line(0)
	_code.scroll_vertical = 0
	_open.disabled = not Engine.is_editor_hint() or src.is_empty()
	_fill_jump(src, entry)
	_update_state(entry, path, src.is_empty())
	_fill_versions()


func _update_state(entry: Dictionary, path: String, missing: bool) -> void:
	kind = GdeBehaviorLibrary.kind_of(entry) if not entry.is_empty() else "own"
	broken = not missing and GdeBehaviorLibrary.is_broken(path)
	var c := Color(0.55, 0.65, 0.8)
	match kind:
		"builtin":
			_state_text.text = "Встроенное поведение. Его код не правится — чтобы что-то изменить или " + \
					"добавить, сделайте свою копию. Встроенное останется нетронутым, к нему всегда можно вернуться."
		"copy":
			c = Color(0.45, 0.75, 0.55)
			_state_text.text = "Своя копия встроенного поведения — у всех объектов проекта работает она. " + \
					"Файл: %s" % path
		_:
			c = Color(0.45, 0.75, 0.55)
			_state_text.text = "Своё поведение. Файл: %s" % path
	if broken:
		c = Color(0.93, 0.36, 0.36)
		_state_text.text = "Скрипт не собирается — объекты с этим поведением в игре не работают. " + \
				"Откройте его в редакторе скриптов: там видна строка с ошибкой." + \
				(" Или верните встроенную версию." if kind == "copy" else "")
	_state_style.bg_color = Color(c.r, c.g, c.b, 0.08)
	_state_style.border_color = Color(c.r, c.g, c.b, 0.8)
	_btn_copy.visible = kind == "builtin"
	_btn_reset.visible = kind == "copy"
	_btn_derive.visible = not missing
	_btn_compare.visible = kind == "copy"
	_update_box.visible = GdeBehaviorLibrary.builtin_changed(entry)
	# Встроенное в редакторе скриптов открылось бы на правку — а его не правят.
	_open.visible = kind != "builtin"


# ------------------------------------------------------------------ версии ---

func _fill_versions() -> void:
	var pop := _versions.get_popup()
	pop.clear()
	_version_list = GdeBehaviorLibrary.list_versions(GdeBehaviorLibrary.history_path(_entry)) \
			if not _entry.is_empty() else []
	if kind != "builtin":
		pop.add_item("Запомнить текущую версию…", 100000)
	if _version_list.is_empty():
		pop.add_item("Сохранённых версий пока нет", 100001)
		pop.set_item_disabled(pop.item_count - 1, true)
	else:
		pop.add_separator("Прошлые копии" if kind == "builtin" else "История")
		for i in range(_version_list.size()):
			var v: Dictionary = _version_list[i]
			pop.add_item("%s — %s" % [str(v.get("title", "")), nice_time(str(v.get("time", "")))], i)
	# У встроенного без истории версий показывать нечего.
	_versions.visible = kind != "builtin" or not _version_list.is_empty()


func _on_version_menu(id: int) -> void:
	if id == 100000:
		remember_requested.emit()
	elif id >= 0 and id < _version_list.size():
		preview_version(_version_list[id])


## «2026-09-24 13:05:41» -> «24.09 13:05»
static func nice_time(t: String) -> String:
	var parts := t.replace("T", " ").split(" ")
	if parts.size() < 2:
		return t
	var d := parts[0].split("-")
	var hm := parts[1].substr(0, 5)
	return "%s.%s %s" % [d[2], d[1], hm] if d.size() == 3 else t


# ------------------------------------------------------------ что показано ---

func show_current() -> void:
	mode = "code"
	_view.visible = false
	_set_lines(_src.split("\n"), [])


## Отличия своей копии от встроенной версии.
func show_compare() -> void:
	var builtin := FileAccess.get_file_as_string(str(_entry.get("builtin_path", "")))
	var ops := GdeDiff.lines(builtin, _src)
	var st := GdeDiff.stats(ops)
	mode = "compare"
	_show_banner("Своя копия против встроенной: добавлено строк %d, убрано %d" % [st["added"], st["removed"]]
			if st["added"] + st["removed"] > 0 else "Копия пока ничем не отличается от встроенной",
			false, false, false)
	_show_ops(GdeDiff.hunks(ops))


## Что изменилось во встроенной с тех пор, как сделали копию.
func show_builtin_update() -> void:
	var base := GdeBehaviorLibrary.base_source(_entry)
	var now := FileAccess.get_file_as_string(str(_entry.get("builtin_path", "")))
	mode = "update"
	var st := GdeDiff.stats(GdeDiff.lines(base, now))
	_show_banner("Что изменилось во встроенной после вашей копии: добавлено %d, убрано %d — перенесите нужное в копию"
			% [st["added"], st["removed"]], false, false, true)
	_show_ops(GdeDiff.hunks(GdeDiff.lines(base, now)))


func preview_version(v: Dictionary) -> void:
	_shown_version = v
	mode = "version"
	_view_diff.set_pressed_no_signal(false)
	_show_banner("Версия «%s» от %s" % [str(v.get("title", "")), nice_time(str(v.get("time", "")))],
			true, true, false)
	_show_version_body()


func _show_version_body() -> void:
	var text := FileAccess.get_file_as_string(str(_shown_version.get("path", "")))
	if _view_diff.button_pressed:
		# Что поменяет восстановление: из текущего кода — в эту версию.
		_show_ops(GdeDiff.hunks(GdeDiff.lines(_src, text)))
	else:
		_set_lines(text.split("\n"), [])


func _show_banner(text: String, with_diff: bool, with_restore: bool, with_accept: bool) -> void:
	_view.visible = true
	_view_text.text = text
	_view_text.tooltip_text = text
	_view_diff.visible = with_diff
	_view_restore.visible = with_restore
	_view_accept.visible = with_accept


## Показать отличия: добавленное — зелёным, убранное — красным.
func _show_ops(ops: Array) -> void:
	var lines: Array[String] = []
	var marks: Array[String] = []
	for op: Array in ops:
		var k := str(op[0])
		var prefix: String = {"+": "+ ", "-": "− ", "…": "  ⋯ "}.get(k, "  ")
		lines.append(prefix + str(op[1]))
		marks.append(k)
	_set_lines(PackedStringArray(lines), marks)


func _set_lines(lines: PackedStringArray, marks: Array) -> void:
	_code.text = "\n".join(lines)
	for i in range(_code.get_line_count()):
		var k := str(marks[i]) if i < marks.size() else " "
		var c := Color(0, 0, 0, 0)
		match k:
			"+":
				c = Color(0.3, 0.8, 0.4, 0.18)
			"-":
				c = Color(0.9, 0.3, 0.3, 0.2)
			"…":
				c = Color(1, 1, 1, 0.05)
		_code.set_line_background_color(i, c)


## Строки, помеченные как добавленные/убранные — для тестов.
func marked_lines(kind_mark: String) -> Array[String]:
	var out: Array[String] = []
	for i in range(_code.get_line_count()):
		var c := _code.get_line_background_color(i)
		if (kind_mark == "+" and c.g > c.r and c.a > 0.1) or (kind_mark == "-" and c.r > c.g and c.a > 0.1):
			out.append(_code.get_line(i))
	return out


## Код поведения — даже если сейчас на экране сравнение или версия.
func source() -> String:
	return _src


func caret_line() -> int:
	return _code.get_caret_line()


## Номер строки функции method или -1.
static func line_of_func(src: String, method: String) -> int:
	var re := RegEx.create_from_string("^\\s*func\\s+%s\\s*\\(" % method)
	var lines := src.split("\n")
	for i in range(lines.size()):
		if re.search(lines[i]) != null:
			return i
	return -1


func _fill_jump(src: String, entry: Dictionary) -> void:
	var pop := _jump.get_popup()
	pop.clear()
	_jump_lines.clear()
	var sections := [
		["Действия", "actions"],
		["Условия", "conditions"],
	]
	for sec: Array in sections:
		var table: Dictionary = entry.get(sec[1], {})
		var first := true
		for method: String in table:
			var line := line_of_func(src, method)
			if line < 0:
				continue  # действия и условия настроек — у них нет своей функции
			if first:
				pop.add_separator(str(sec[0]))
				first = false
			_add_jump(GdeText.with_labels(table[method]), line)
	var exprs: Dictionary = entry.get("expressions", {})
	var re_method := RegEx.create_from_string("\\{beh\\}\", \"(\\w+)\"")
	var first_expr := true
	for ename: String in exprs:
		var m := re_method.search(str((exprs[ename] as Dictionary).get("template", "")))
		if m == null:
			continue
		var line2 := line_of_func(src, m.get_string(1))
		if line2 < 0:
			continue
		if first_expr:
			pop.add_separator("Выражения")
			first_expr = false
		_add_jump("%s() — %s" % [ename, str((exprs[ename] as Dictionary).get("description", ""))], line2)
	_jump.disabled = _jump_lines.is_empty()


func _add_jump(text: String, line: int) -> void:
	var pop := _jump.get_popup()
	pop.add_item(text, _jump_lines.size())
	_jump_lines.append(line)


func _on_jump(id: int) -> void:
	if id < 0 or id >= _jump_lines.size():
		return
	if mode != "code":
		show_current()
	jump_to_line(_jump_lines[id])


func jump_to_line(line: int) -> void:
	# Строку — в верх окна, а не куда придётся: над функцией её описание.
	_code.set_caret_line(line)
	_code.set_line_as_first_visible(maxi(0, line - 3))
	_code.grab_focus()


## Открыть скрипт в редакторе скриптов Godot на той же строке.
func open_in_script_editor() -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return
	var scr: Script = load(script_path)
	if scr == null:
		return
	if mode != "code":
		show_current()
	var ei: Object = Engine.get_singleton("EditorInterface")
	ei.call("edit_script", scr, _code.get_caret_line() + 1)
	ei.call("set_main_screen_editor", "Script")
	opened_in_editor.emit()


## В редакторе — родная подсветка GDScript. Вне его (тесты, снимки) ей
## неоткуда взять цвета темы, поэтому простая своя.
static func _highlighter() -> SyntaxHighlighter:
	if Engine.is_editor_hint() and ClassDB.can_instantiate("GDScriptSyntaxHighlighter"):
		return ClassDB.instantiate("GDScriptSyntaxHighlighter")
	var h := CodeHighlighter.new()
	h.number_color = Color(0.63, 1.0, 0.88)
	h.symbol_color = Color(0.67, 0.79, 1.0)
	h.function_color = Color(0.34, 0.7, 1.0)
	h.member_variable_color = Color(0.74, 0.88, 1.0)
	var kw := Color(1.0, 0.44, 0.52)
	for w: String in ["func", "var", "const", "extends", "class_name", "if", "elif", "else", "for",
			"while", "match", "return", "and", "or", "not", "in", "pass", "break", "continue",
			"signal", "static", "await", "true", "false", "null", "self", "super"]:
		h.add_keyword_color(w, kw)
	for t: String in ["float", "int", "bool", "String", "Vector2", "Node", "Node2D", "Array",
			"Dictionary", "PackedScene", "void"]:
		h.add_keyword_color(t, Color(0.26, 1.0, 0.76))
	h.add_color_region("#", "", Color(0.6, 0.62, 0.66), true)
	h.add_color_region("\"", "\"", Color(1.0, 0.93, 0.63))
	h.add_color_region("@", " ", Color(1.0, 0.7, 0.45), true)
	return h
