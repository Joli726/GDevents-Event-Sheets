## Выбор и настройка условия или действия — одно окно, как в GDevelop:
## слева объект, в середине что с ним можно сделать, справа настройки
## выбранного.
##
## Раньше после выбора открывалось второе окно с параметрами — лишний шаг на
## каждое условие, а «Отмена» в нём оставляла в листе недозаполненную строку.
## Теперь щелчок по условию сразу показывает его настройки, а строка
## появляется в листе только по «Добавить». Этим же окном правятся и
## существующие строки — с возможностью поменять само условие на другое.
@tool
class_name GdeInstructionPicker
extends ConfirmationDialog

## Готовая строка: что выбрали, с какими параметрами и тумблерами.
signal chosen(id: String, params: Array, flags: Dictionary)

const GENERAL := "general"

## Недавно выбранные инструкции, отдельно для условий и действий.
## В живом листе одни и те же условия повторяются десятками — искать их
## каждый раз по группам незачем. Живёт до перезапуска редактора.
const RECENT_MAX := 8
static var _recent: Dictionary = {"conditions": [], "actions": []}

var _reg: GdeRegistry
var _kind: String = "conditions"
var _doc: GdeSheetDocument
var _accent: Color = Color(1, 0.78, 0.42)

var _search: LineEdit
var _objects: ItemList
var _tree: Tree
var _beh_note: Label
var _editor: GdeParamEditor

var _all: Array = []
var _installed: Dictionary = {}   ## имя объекта -> Array[String] поведений
var _current_object: String = GENERAL
var _current_entry: Dictionary = {}
## Правится существующая строка: её исходные параметры и тумблеры.
var _edit_inst: Dictionary = {}
var _quiet: bool = false


func _init() -> void:
	title = "Добавить"
	ok_button_text = "Добавить"
	cancel_button_text = "Отмена"

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 6)
	box.add_child(search_row)

	var mag := TextureRect.new()
	mag.texture = GdeIcons.get_icon("search")
	mag.custom_minimum_size = Vector2(20, 20)
	mag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mag.modulate = Color(1, 1, 1, 0.6)
	search_row.add_child(mag)

	_search = LineEdit.new()
	_search.placeholder_text = "Поиск по всем объектам…  Enter — выбрать первое найденное"
	_search.clear_button_enabled = true
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_t): _rebuild_tree(true))
	_search.text_submitted.connect(func(_t): _search_enter())
	search_row.add_child(_search)

	var outer := HSplitContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.split_offset = 0
	box.add_child(outer)

	# ---- слева: объекты
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.custom_minimum_size = Vector2(180, 0)
	outer.add_child(left)
	left.add_child(_caption("ОБЪЕКТЫ"))

	_objects = ItemList.new()
	_objects.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_objects.auto_height = false
	_objects.item_selected.connect(_on_object_selected)
	left.add_child(_objects)

	var inner := HSplitContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(inner)

	# ---- в середине: условия и действия
	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", 4)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.custom_minimum_size = Vector2(320, 0)
	inner.add_child(middle)

	_beh_note = _caption("")
	_beh_note.clip_text = true
	middle.add_child(_beh_note)

	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_instruction_selected)
	_tree.item_activated.connect(_on_activated)
	middle.add_child(_tree)

	# ---- справа: настройки выбранного
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(440, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.03)
	sb.set_content_margin_all(12)
	sb.set_corner_radius_all(5)
	right.add_theme_stylebox_override("panel", sb)
	inner.add_child(right)

	_editor = GdeParamEditor.new()
	_editor.submitted.connect(_confirm)
	right.add_child(_editor)

	confirmed.connect(_emit_choice)


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(1, 1, 1, 0.5)
	return l


# ------------------------------------------------------------------ снаружи ---

## Добавить новую строку. prefer_object — объект, который выбрать слева.
func open_add(reg: GdeRegistry, doc: GdeSheetDocument, kind: String,
		prefer_object: String = "", accent: Color = Color(1, 0.78, 0.42)) -> void:
	_edit_inst = {}
	title = "Добавить условие" if kind == "conditions" else "Добавить действие"
	ok_button_text = "Добавить"
	_open(reg, doc, kind, prefer_object, accent)
	_editor.clear_editor()
	get_ok_button().disabled = true
	_search.grab_focus()


## Править существующую строку: условие уже выбрано, поля заполнены.
func open_edit(reg: GdeRegistry, doc: GdeSheetDocument, kind: String,
		inst: Dictionary, accent: Color = Color(1, 0.78, 0.42)) -> void:
	_edit_inst = inst.duplicate(true)
	title = "Условие" if kind == "conditions" else "Действие"
	ok_button_text = "Применить"
	var id := str(inst.get("id", ""))
	# Список инструкций нужен раньше, чем откроется окно: по нему узнаём,
	# какой параметр строки — объект, и на нём открываемся.
	_reg = reg
	_kind = kind
	_all = _collect()
	_open(reg, doc, kind, _object_in(id, inst.get("params", [])), accent)
	_select_id(id)
	_editor.focus_first_field()


func _open(reg: GdeRegistry, doc: GdeSheetDocument, kind: String,
		prefer_object: String, accent: Color) -> void:
	_reg = reg
	_doc = doc
	_kind = kind
	_accent = accent
	_current_entry = {}
	_all = _collect()
	_scan_behaviors()
	_quiet = true
	_search.text = ""
	_quiet = false
	_fill_objects(prefer_object)
	_rebuild_tree(false)
	GdeUi.popup_fit(self, Vector2i(1280, 720))


## Первый параметр-объект строки — на нём окно и откроется.
func _object_in(id: String, params: Array) -> String:
	var def := _def_of(id)
	var defs: Array = def.get("params", [])
	for i in range(mini(defs.size(), params.size())):
		if str((defs[i] as Dictionary).get("kind", "")) == "object":
			return str(params[i])
	return ""


func _def_of(id: String) -> Dictionary:
	var e := _entry_by_id(id)
	return e.get("def", {}) if not e.is_empty() else {}


# ---------------------------------------------------------------- объекты ---

## Какие поведения реально стоят на каждом объекте — только их инструкции
## имеет смысл предлагать.
func _scan_behaviors() -> void:
	_installed.clear()
	if _doc == null:
		return
	for o: Dictionary in _doc.objects():
		var nm := str(o.get("name", ""))
		var scene := str(o.get("scene", ""))
		if nm.is_empty() or scene.is_empty():
			continue
		_installed[nm] = GdeBehaviorInstaller.installed(scene)


func _collect() -> Array:
	var out: Array = []
	var builtin: Dictionary = _reg.conditions if _kind == "conditions" else _reg.actions
	for id: String in builtin:
		out.append({"id": id, "def": builtin[id], "behavior": ""})
	for bname: String in _reg.behaviors:
		var table: Dictionary = (_reg.behaviors[bname] as Dictionary).get(_kind, {})
		for m: String in table:
			out.append({"id": "%s::%s" % [bname, m], "def": table[m], "behavior": bname})
	return out


func _fill_objects(prefer: String) -> void:
	_objects.clear()
	_objects.add_item("Общие", GdeIcons.get_icon("system"))
	_objects.set_item_metadata(0, GENERAL)
	_objects.set_item_tooltip(0, "Клавиатура, мышь, переменные, таймеры, сцена")

	var select := 0
	if _doc != null:
		var names := _doc.object_names()
		for i in range(names.size()):
			var nm := str(names[i])
			var idx := _objects.add_item(nm, _object_icon(nm))
			_objects.set_item_metadata(idx, nm)
			if nm == prefer:
				select = idx
	_objects.select(select)
	_current_object = str(_objects.get_item_metadata(select))


## Миниатюра объекта из его сцены; у групп объектов — общий значок.
func _object_icon(nm: String) -> Texture2D:
	for o: Dictionary in _doc.objects():
		if str(o.get("name", "")) == nm:
			return GdeThumbs.icon_for(str(o.get("scene", "")))
	return GdeIcons.get_icon("group")


## Сменили объект слева. Если выбранное условие подходит и новому объекту —
## остаётся выбранным, с новым объектом и уже введёнными значениями.
func _on_object_selected(idx: int) -> void:
	var keep_id := str(_current_entry.get("id", ""))
	var keep_values := _editor.current_values() if _editor.has_instruction() else []
	var keep_flags := _editor.current_flags() if _editor.has_instruction() else {}
	var old_object := _current_object
	_current_object = str(_objects.get_item_metadata(idx))
	_rebuild_tree(false)
	if keep_id.is_empty():
		return
	var entry := _entry_by_id(keep_id)
	if entry.is_empty() or not _applies(entry):
		_current_entry = {}
		_editor.clear_editor()
		get_ok_button().disabled = true
		return
	var values := _swap_object(entry["def"], keep_values, old_object)
	_select_id(keep_id, values, keep_flags)


func _swap_object(def: Dictionary, values: Array, old_object: String) -> Array:
	var out := values.duplicate()
	var defs: Array = def.get("params", [])
	for i in range(mini(defs.size(), out.size())):
		if str((defs[i] as Dictionary).get("kind", "")) == "object" and str(out[i]) == old_object:
			out[i] = "" if _current_object == GENERAL else _current_object
			break
	return out


## Подходит ли инструкция выбранной слева строке.
func _applies(entry: Dictionary) -> bool:
	var def: Dictionary = entry["def"]
	var has_object := false
	for p: Dictionary in def.get("params", []):
		if str(p.get("kind", "")) == "object":
			has_object = true
			break
	if _current_object == GENERAL:
		return not has_object
	if not has_object:
		return false
	var beh := str(entry["behavior"])
	if beh.is_empty():
		return true
	var list: Array = _installed.get(_current_object, [])
	return list.has(beh)


# ------------------------------------------------------------------ дерево ---

## select_first — выделить первое найденное: при поиске так Enter сразу
## берёт лучший вариант. При обычном открытии ничего не выделяется —
## иначе легко добавить не то, не глядя.
func _rebuild_tree(select_first: bool) -> void:
	if _quiet:
		return
	_tree.clear()
	var root := _tree.create_item()
	var needle := _search.text.strip_edges().to_lower()
	var searching := not needle.is_empty()

	var groups: Dictionary = {}
	var first: TreeItem = null

	if not searching:
		var recent_group: TreeItem = null
		for id: String in (_recent.get(_kind, []) as Array):
			var entry := _entry_by_id(id)
			if entry.is_empty() or not _applies(entry):
				continue
			if recent_group == null:
				recent_group = _tree.create_item(root)
				recent_group.set_text(0, "Недавние")
				recent_group.set_icon(0, GdeIcons.get_icon("timer"))
				recent_group.set_icon_max_width(0, 16)
				recent_group.set_selectable(0, false)
				recent_group.set_custom_color(0, Color(0.88, 0.8, 0.55))
			var ritem := _tree.create_item(recent_group)
			_fill_item(ritem, entry)
			if first == null:
				first = ritem

	# Внутри группы сначала осмысленные инструкции (weight 0),
	# потом автоматические для свойств поведений — их много и они редко нужны.
	var sorted := _all.duplicate()
	sorted.sort_custom(func(a, b):
		var da: Dictionary = a["def"]
		var db: Dictionary = b["def"]
		var ga := str(da.get("group", ""))
		var gb := str(db.get("group", ""))
		if ga != gb:
			return ga < gb
		var wa := int(da.get("weight", 0))
		var wb := int(db.get("weight", 0))
		if wa != wb:
			return wa < wb
		return GdeText.with_labels(da) < GdeText.with_labels(db))

	for entry: Dictionary in sorted:
		if not searching and not _applies(entry):
			continue
		var def: Dictionary = entry["def"]
		var text := GdeText.with_labels(def, _shown_object())
		if searching and not text.to_lower().contains(needle) \
				and not str(entry["id"]).to_lower().contains(needle):
			continue
		var gname := str(def.get("group", "Прочее"))
		if not groups.has(gname):
			var gi := _tree.create_item(root)
			gi.set_text(0, gname)
			gi.set_icon(0, GdeIcons.for_group(gname))
			gi.set_icon_max_width(0, 16)
			gi.set_selectable(0, false)
			gi.set_custom_color(0, Color(0.62, 0.72, 0.88))
			groups[gname] = gi
		var item := _tree.create_item(groups[gname])
		_fill_item(item, entry)
		if first == null:
			first = item

	_update_behavior_note()
	if searching and select_first and first != null:
		_select_item(first)
	elif first == null:
		_beh_note.text = "НИЧЕГО НЕ НАЙДЕНО"


func _fill_item(item: TreeItem, entry: Dictionary) -> void:
	var def: Dictionary = entry["def"]
	item.set_text(0, GdeText.with_labels(def, _shown_object()))
	item.set_icon(0, GdeIcons.for_instruction(def, _kind))
	item.set_icon_max_width(0, 16)
	item.set_metadata(0, entry)
	var desc := str(def.get("description", ""))
	if not desc.is_empty():
		item.set_tooltip_text(0, desc)


func _shown_object() -> String:
	return "" if _current_object == GENERAL else _current_object


func _update_behavior_note() -> void:
	if _current_object == GENERAL:
		_beh_note.text = "ОБЩИЕ — НЕ ПРИВЯЗАНЫ К ОБЪЕКТУ"
		return
	var list: Array = _installed.get(_current_object, [])
	if list.is_empty():
		_beh_note.text = "%s — поведений нет. Добавить: кнопка «Объекты» в панели." % _current_object.to_upper()
		return
	# В списке — русские названия: английские имена нужны только коду.
	var titles: Array[String] = []
	for b: Variant in list:
		var d: Variant = _reg.behaviors.get(str(b)) if _reg != null else null
		titles.append(str((d as Dictionary).get("title", b)) if d != null else str(b))
	_beh_note.text = "%s — поведения: %s" % [_current_object.to_upper(), ", ".join(titles)]


# --------------------------------------------------------------- выбор ---

func _on_instruction_selected() -> void:
	if _quiet:
		return
	var item := _tree.get_selected()
	if item == null:
		return
	var entry: Variant = item.get_metadata(0)
	if entry is Dictionary:
		_show(entry as Dictionary, [], {})


## Показать настройки. Значения по умолчанию: объект — выбранный слева,
## знаки — «=», остальное пусто. У правящейся строки — её собственные.
func _show(entry: Dictionary, values: Array, flags: Dictionary) -> void:
	_current_entry = entry
	var id := str(entry["id"])
	var params := values
	var f := flags
	if params.is_empty():
		if not _edit_inst.is_empty() and str(_edit_inst.get("id", "")) == id:
			params = _edit_inst.get("params", [])
			f = {"inverted": _edit_inst.get("inverted", false),
					"disabled": _edit_inst.get("disabled", false)}
		else:
			params = _default_params(entry["def"])
	_editor.edit(id, entry["def"], params, _doc.object_names() if _doc != null else [],
			_accent, _reg, _doc, _kind, f)
	get_ok_button().disabled = false
	GdeUi.refit(self)


func _default_params(def: Dictionary) -> Array:
	var out: Array = []
	var names: Array = _doc.object_names() if _doc != null else []
	var first_object := true
	for pd: Dictionary in def.get("params", []):
		match str(pd.get("kind", "number")):
			"object", "objname":
				var v := _shown_object()
				if v.is_empty() or not first_object:
					v = str(names[0]) if not names.is_empty() else ""
				out.append(v)
				first_object = false
			"cmpop", "modop":
				out.append("=")
			_:
				out.append("")
	return out


func _select_id(id: String, values: Array = [], flags: Dictionary = {}) -> void:
	var item := _find_item(_tree.get_root(), id)
	var entry := _entry_by_id(id)
	if item != null:
		_quiet = true
		item.select(0)
		_quiet = false
		_tree.scroll_to_item(item)
	if not entry.is_empty():
		_show(entry, values, flags)


func _select_item(item: TreeItem) -> void:
	_quiet = true
	item.select(0)
	_quiet = false
	_tree.scroll_to_item(item)
	var entry: Variant = item.get_metadata(0)
	if entry is Dictionary:
		_show(entry as Dictionary, [], {})


func _find_item(from: TreeItem, id: String) -> TreeItem:
	if from == null:
		return null
	var entry: Variant = from.get_metadata(0)
	if entry is Dictionary and str((entry as Dictionary).get("id", "")) == id:
		return from
	var c := from.get_first_child()
	while c != null:
		var r := _find_item(c, id)
		if r != null:
			return r
		c = c.get_next()
	return null


func _entry_by_id(id: String) -> Dictionary:
	for e: Dictionary in _all:
		if str(e["id"]) == id:
			return e
	return {}


## Enter в поиске: без полей — сразу добавить, с полями — перейти к первому.
func _search_enter() -> void:
	if _current_entry.is_empty():
		return
	if _editor.has_fields():
		_editor.focus_first_field()
	else:
		_confirm()


## Двойной щелчок по условию — добавить сразу, с тем, что уже в полях.
func _on_activated() -> void:
	if not _current_entry.is_empty():
		_confirm()


func _confirm() -> void:
	if _current_entry.is_empty():
		return
	_emit_choice()
	hide()


func _emit_choice() -> void:
	if _current_entry.is_empty():
		return
	var id := str(_current_entry["id"])
	var list: Array = _recent.get(_kind, [])
	list.erase(id)
	list.push_front(id)
	if list.size() > RECENT_MAX:
		list.resize(RECENT_MAX)
	_recent[_kind] = list
	chosen.emit(id, _editor.current_values(), _editor.current_flags())
