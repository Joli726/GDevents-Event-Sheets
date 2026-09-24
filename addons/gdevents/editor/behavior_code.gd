## Код поведения — как оно устроено внутри. Вкладка «Код» у поведения
## в окне объектов.
##
## Только чтение: править код удобнее в редакторе скриптов Godot, где
## есть автодополнение, подсветка ошибок и отладчик, — туда ведёт кнопка.
## «Перейти к…» перечисляет действия, условия и выражения поведения теми же
## фразами, что и в листе событий, и ставит курсор на их функцию.
@tool
class_name GdeBehaviorCode
extends VBoxContainer

## Попросили открыть скрипт в редакторе Godot — окну объектов пора уступить.
signal opened_in_editor

var script_path: String = ""

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
	_code.text = src if not src.is_empty() else "# Скрипт поведения не найден: %s" % path
	_code.set_caret_line(0)
	_code.scroll_vertical = 0
	_open.disabled = not Engine.is_editor_hint() or src.is_empty()
	_fill_jump(src, entry)


func source() -> String:
	return _code.text


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
