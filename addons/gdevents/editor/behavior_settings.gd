## Настройки поведения на объекте — как панель поведения в GDevelop.
##
## Форма строится из самого скрипта поведения: какие у него @export, какого
## они типа, в каких группах и с какими пределами. Названия и описания —
## русские, из ##-комментариев над свойством (их собирает реестр). Отдельно
## для каждого поведения ничего рисовать не нужно: новое поведение получает
## своё окно настроек само.
##
## Значения пишутся в сцену объекта — в открытую вкладку или в файл — не на
## каждое нажатие клавиши, а пачкой, когда правка на миг затихла.
@tool
class_name GdeBehaviorSettings
extends VBoxContainer

## Правка записана в сцену объекта; error не пуст, если не записалась.
signal saved(error: String)

## Сколько ждать тишины после правки, прежде чем писать сцену.
const WRITE_DELAY := 0.4

var scene_path: String = ""
var behavior: String = ""

var _reg: GdeRegistry
var _object_names: Array = []
var _info: Dictionary = {}
var _values: Dictionary = {}
var _defaults: Dictionary = {}
## имя свойства -> {"reset": Button, "show": Callable(value)} — чтобы сброс
## мог обновить поле, не пересобирая всю форму.
var _rows: Dictionary = {}
var _pending: Dictionary = {}
var _writing: bool = false

var _scroll: ScrollContainer
var _form: VBoxContainer
var _timer: Timer
var _file: FileDialog
var _file_prop: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 6)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_form = VBoxContainer.new()
	_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_form.add_theme_constant_override("separation", 4)
	_scroll.add_child(_form)

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = WRITE_DELAY
	_timer.timeout.connect(flush)
	add_child(_timer)

	_file = FileDialog.new()
	_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file.access = FileDialog.ACCESS_RESOURCES
	_file.file_selected.connect(_on_file_selected)
	add_child(_file)


## Показать настройки поведения bname на объекте из scene. Несохранённые
## правки прошлого поведения сначала записываются — терять их нельзя.
func show_behavior(scene: String, bname: String, reg: GdeRegistry, object_names: Array = []) -> void:
	if not _pending.is_empty():
		await flush()
	scene_path = scene
	behavior = bname
	_reg = reg
	_object_names = object_names
	rebuild()


## Перечитать поведение из сцены и собрать форму заново.
func rebuild() -> void:
	for c: Node in _form.get_children():
		_form.remove_child(c)
		c.queue_free()
	_rows.clear()
	_values.clear()
	_defaults.clear()
	_info = GdeBehaviorInstaller.describe(scene_path, behavior) if not scene_path.is_empty() else {}
	if _info.is_empty():
		_form.add_child(_dim(GdeI18n.t("Поведение не найдено в сцене объекта.")))
		return

	var meta := _settings_meta()
	var props: Array = _info.get("props", [])
	var names: Array[String] = []
	for p: Dictionary in props:
		names.append(str(p["name"]))
		_values[str(p["name"])] = p["value"]
		_defaults[str(p["name"])] = p["default"]
	var has_preset := names.has("preset") and names.has("apply_preset")

	var shown := 0
	var last_group: Variant = null  # ещё ни одной группы
	for p: Dictionary in props:
		var nm := str(p["name"])
		var m: Dictionary = meta.get(nm, {})
		if bool(m.get("internal", false)) or (has_preset and nm == "apply_preset"):
			continue
		var group := str(p["group"])
		if group != last_group:
			_form.add_child(_group_caption(group if not group.is_empty() else GdeI18n.t("Основное")))
			last_group = group
		_form.add_child(_row(p, m, has_preset and nm == "preset"))
		shown += 1

	if shown == 0:
		_form.add_child(_dim(GdeI18n.t("У этого поведения нет настроек.")))
		return
	_form.add_child(HSeparator.new())
	var reset_all := Button.new()
	reset_all.text = GdeI18n.t("  Вернуть все настройки по умолчанию")
	reset_all.icon = GdeIcons.get_icon("undo")
	reset_all.alignment = HORIZONTAL_ALIGNMENT_LEFT
	reset_all.pressed.connect(reset_all_values)
	_form.add_child(reset_all)


func _settings_meta() -> Dictionary:
	if _reg == null:
		return {}
	var b: Variant = _reg.behaviors.get(behavior)
	if b == null:
		return {}
	return (b as Dictionary).get("settings", {})


# ------------------------------------------------------------------ строки ---

func _row(p: Dictionary, m: Dictionary, preset_row: bool) -> Control:
	var nm := str(p["name"])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	box.add_child(line)

	var label := Label.new()
	label.text = label_for(nm, m)
	label.custom_minimum_size = Vector2(240, 0)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = "%s\n\n(%s)" % [str(m.get("doc", label.text)), nm]
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	line.add_child(label)

	var editor := _editor_for(p)
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(editor)

	if preset_row:
		var apply := Button.new()
		apply.text = GdeI18n.t("Применить")
		apply.tooltip_text = GdeI18n.t("Записать настройки выбранного пресета в поведение")
		apply.pressed.connect(apply_preset)
		line.add_child(apply)

	var reset := Button.new()
	reset.flat = true
	reset.icon = GdeIcons.get_icon("undo")
	reset.pressed.connect(func() -> void: set_value(nm, _defaults.get(nm)))
	line.add_child(reset)
	(_rows[nm] as Dictionary)["reset"] = reset
	_update_reset(nm)

	var doc := str(m.get("doc", ""))
	if preset_row:
		# В комментариях поведений пресет «применяется галочкой ниже» — это
		# про инспектор Godot. Здесь вместо галочки кнопка.
		doc = GdeI18n.t("Выберите набор и нажмите «Применить» — его значения запишутся в настройки ниже.")
	if doc.length() > label.text.length() + 2:
		var desc := _dim(doc)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.clip_text = false
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.add_theme_font_size_override("font_size", 11)
		box.add_child(desc)
	return box


## Русское название из комментария, иначе — имя свойства по-человечески.
static func label_for(prop: String, meta: Dictionary) -> String:
	var l := str(meta.get("label", ""))
	if not l.is_empty():
		return l
	var s := prop.replace("_", " ")
	return s.substr(0, 1).to_upper() + s.substr(1)


# ---------------------------------------------------------------- редакторы ---

func _editor_for(p: Dictionary) -> Control:
	var nm := str(p["name"])
	var t := int(p["type"])
	var hint := int(p["hint"])
	var hs := str(p["hint_string"])
	_rows[nm] = {}

	if t == TYPE_BOOL:
		var cb := CheckBox.new()
		cb.text = GdeI18n.t("Да")
		cb.button_pressed = bool(_values[nm])
		cb.toggled.connect(func(on: bool) -> void: _changed(nm, on))
		_rows[nm]["show"] = func(v: Variant) -> void: cb.set_pressed_no_signal(bool(v))
		return cb

	if (t == TYPE_INT or t == TYPE_FLOAT) and hint == PROPERTY_HINT_ENUM:
		var ob := OptionButton.new()
		var ids := parse_enum(hs)
		for i in range(ids.size()):
			ob.add_item(str(ids[i][0]), int(ids[i][1]))
		ob.fit_to_longest_item = false
		var select := func(v: Variant) -> void:
			var idx := ob.get_item_index(int(v))
			if idx >= 0:
				ob.select(idx)
		select.call(_values[nm])
		ob.item_selected.connect(func(idx: int) -> void:
			var id := ob.get_item_id(idx)
			_changed(nm, id if t == TYPE_INT else float(id)))
		_rows[nm]["show"] = select
		return ob

	if t == TYPE_INT or t == TYPE_FLOAT:
		var sb := SpinBox.new()
		var r := parse_range(hs, t == TYPE_INT)
		sb.min_value = r["min"]
		sb.max_value = r["max"]
		sb.allow_greater = r["greater"]
		sb.allow_lesser = r["lesser"]
		# Шаг поля — мелкий, чтобы уже записанное значение не округлилось
		# при показе; шаг стрелок — тот, что задан в поведении.
		sb.step = 1.0 if t == TYPE_INT else 0.001
		sb.custom_arrow_step = r["step"]
		sb.suffix = r["suffix"]
		sb.select_all_on_focus = true
		sb.set_value_no_signal(float(_values[nm]))
		sb.value_changed.connect(func(v: float) -> void: _changed(nm, int(round(v)) if t == TYPE_INT else v))
		_rows[nm]["show"] = func(v: Variant) -> void: sb.set_value_no_signal(float(v))
		return sb

	if (t == TYPE_STRING or t == TYPE_STRING_NAME):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var le := LineEdit.new()
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.text = str(_values[nm])
		le.text_changed.connect(func(s: String) -> void: _changed(nm, s))
		row.add_child(le)
		_rows[nm]["show"] = func(v: Variant) -> void: le.text = str(v)
		var choices: Array = []
		var what := ""
		if nm.ends_with("_object") or nm == "target":
			choices = _object_names
			what = GdeI18n.t("Объекты листа")
		elif nm.ends_with("_animation"):
			choices = _info.get("animations", [])
			what = GdeI18n.t("Анимации из спрайта объекта")
		if hint == PROPERTY_HINT_FILE or hint == PROPERTY_HINT_GLOBAL_FILE:
			var browse := Button.new()
			browse.text = "…"
			browse.tooltip_text = GdeI18n.t("Выбрать файл")
			browse.pressed.connect(func() -> void: _pick_file(nm, hs))
			row.add_child(browse)
		elif not what.is_empty():
			row.add_child(_choices_button(nm, what, choices, le))
		return row

	if t == TYPE_OBJECT and hs.contains("PackedScene"):
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 4)
		var shown := LineEdit.new()
		shown.editable = false
		shown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(shown)
		var show_scene := func(v: Variant) -> void:
			var res := v as Resource
			shown.text = res.resource_path if res != null else ""
			shown.placeholder_text = GdeI18n.t("сцена не выбрана")
		show_scene.call(_values[nm])
		var pick := Button.new()
		pick.text = GdeI18n.t("Выбрать…")
		pick.pressed.connect(func() -> void: _pick_file(nm, "*.tscn,*.scn"))
		row2.add_child(pick)
		var clear := Button.new()
		clear.icon = GdeIcons.get_icon("close")
		clear.flat = true
		clear.tooltip_text = GdeI18n.t("Убрать сцену")
		clear.pressed.connect(func() -> void: set_value(nm, null))
		row2.add_child(clear)
		_rows[nm]["show"] = show_scene
		return row2

	# Точки пути, цвета и прочее — там, где их удобно править мышью.
	var row3 := HBoxContainer.new()
	var note := _dim(_complex_note(_values[nm]))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row3.add_child(note)
	var open := Button.new()
	open.text = GdeI18n.t("Открыть в инспекторе")
	open.disabled = not Engine.is_editor_hint()
	open.pressed.connect(open_in_inspector)
	row3.add_child(open)
	_rows[nm]["show"] = func(v: Variant) -> void: note.text = _complex_note(v)
	return row3


func _choices_button(nm: String, what: String, choices: Array, le: LineEdit) -> MenuButton:
	var mb := MenuButton.new()
	mb.text = "▾"
	mb.flat = false
	mb.tooltip_text = what
	var pop := mb.get_popup()
	if choices.is_empty():
		pop.add_item(GdeI18n.t("— нечего выбрать —"))
		pop.set_item_disabled(0, true)
	for i in range(choices.size()):
		pop.add_item(str(choices[i]), i)
	pop.id_pressed.connect(func(i: int) -> void:
		if i >= 0 and i < choices.size():
			le.text = str(choices[i])
			_changed(nm, str(choices[i])))
	return mb


static func _complex_note(v: Variant) -> String:
	if v is PackedVector2Array:
		return GdeI18n.t("Точек: %d — правятся в инспекторе") % (v as PackedVector2Array).size()
	return GdeI18n.t("Правится в инспекторе Godot")


## «Левая:1,Правая:2» -> [["Левая", 1], ["Правая", 2]]; без номеров — по порядку.
static func parse_enum(hs: String) -> Array:
	var out: Array = []
	var next := 0
	for part: String in hs.split(","):
		var s := part.strip_edges()
		if s.is_empty():
			continue
		var title := s
		var val := next
		var colon := s.rfind(":")
		if colon > 0 and s.substr(colon + 1).is_valid_int():
			title = s.substr(0, colon)
			val = int(s.substr(colon + 1))
		out.append([title, val])
		next = val + 1
	return out


## «0,3000,10,or_greater,suffix:px» -> пределы, шаг стрелок и подпись.
static func parse_range(hs: String, is_int: bool) -> Dictionary:
	var r := {"min": -1e9, "max": 1e9, "step": 1.0 if is_int else 0.1,
			"greater": true, "lesser": true, "suffix": ""}
	var parts := hs.split(",")
	if parts.size() >= 2 and parts[0].strip_edges().is_valid_float() and parts[1].strip_edges().is_valid_float():
		r["min"] = float(parts[0])
		r["max"] = float(parts[1])
		r["greater"] = false
		r["lesser"] = false
		if parts.size() >= 3 and parts[2].strip_edges().is_valid_float() and float(parts[2]) > 0.0:
			r["step"] = float(parts[2])
	for part: String in parts:
		var s := part.strip_edges()
		if s == "or_greater":
			r["greater"] = true
		elif s == "or_less":
			r["lesser"] = true
		elif s.begins_with("suffix:"):
			r["suffix"] = s.trim_prefix("suffix:")
	return r


# ------------------------------------------------------------------ правка ---

## Поставить значение и показать его в поле — для сброса и выбора файла.
func set_value(nm: String, v: Variant) -> void:
	var row: Dictionary = _rows.get(nm, {})
	if row.has("show"):
		(row["show"] as Callable).call(v)
	_changed(nm, v)


func value_of(nm: String) -> Variant:
	return _values.get(nm)


func _changed(nm: String, v: Variant) -> void:
	_values[nm] = v
	_pending[nm] = v
	_update_reset(nm)
	_timer.start()


func _update_reset(nm: String) -> void:
	var row: Dictionary = _rows.get(nm, {})
	var reset: Button = row.get("reset")
	if reset == null:
		return
	var same := same_value(_values.get(nm), _defaults.get(nm))
	reset.disabled = same
	reset.modulate.a = 0.0 if same else 1.0
	reset.tooltip_text = "" if same else GdeI18n.t("Вернуть значение по умолчанию: %s") % _show(_defaults.get(nm))


static func same_value(a: Variant, b: Variant) -> bool:
	var na := typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT
	var nb := typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT
	if na and nb:
		return is_equal_approx(float(a), float(b))
	if typeof(a) != typeof(b):
		return false
	return a == b


static func _show(v: Variant) -> String:
	if v == null:
		return GdeI18n.t("пусто")
	if v is bool:
		return GdeI18n.t("да") if v else GdeI18n.t("нет")
	if v is Resource:
		return (v as Resource).resource_path
	if v is String and (v as String).is_empty():
		return GdeI18n.t("пусто")
	return str(v)


## Записать накопленные правки в сцену объекта.
func flush() -> void:
	_timer.stop()
	if _writing or _pending.is_empty() or scene_path.is_empty():
		return
	_writing = true
	var sp := scene_path
	var bn := behavior
	while not _pending.is_empty():
		var batch := _pending.duplicate()
		_pending.clear()
		var err: String = await GdeBehaviorInstaller.edit_behavior(sp, bn, func(node: Node) -> String:
			for k: String in batch:
				node.set(k, batch[k])
			return "")
		saved.emit(err)
		if not err.is_empty():
			break
	_writing = false


func has_pending() -> bool:
	return not _pending.is_empty() or _writing


## Записать в поведение значения выбранного пресета. Пресеты в поведениях
## применяются галочкой apply_preset — здесь это одна кнопка.
func apply_preset() -> void:
	await flush()
	var preset: Variant = _values.get("preset")
	var err: String = await GdeBehaviorInstaller.edit_behavior(scene_path, behavior, func(node: Node) -> String:
		node.set("preset", preset)
		node.set("apply_preset", true)
		return "")
	saved.emit(err)
	rebuild()


func reset_all_values() -> void:
	var meta := _settings_meta()
	for nm: String in _values:
		if bool((meta.get(nm, {}) as Dictionary).get("internal", false)) or nm == "apply_preset":
			continue
		if not same_value(_values[nm], _defaults.get(nm)):
			set_value(nm, _defaults.get(nm))


# ---------------------------------------------------------------- файлы ---

func _pick_file(nm: String, filters: String) -> void:
	_file_prop = nm
	var list := PackedStringArray()
	for f: String in filters.split(","):
		if not f.strip_edges().is_empty():
			list.append(f.strip_edges())
	_file.filters = list
	_file.title = GdeI18n.t("Файл для «%s»") % label_for(nm, _settings_meta().get(nm, {}))
	GdeUi.popup_fit(_file, Vector2i(900, 620))


func _on_file_selected(path: String) -> void:
	var nm := _file_prop
	if nm.is_empty():
		return
	var p := _find_prop(nm)
	if int(p.get("type", TYPE_NIL)) == TYPE_OBJECT:
		var res := load(path)
		if res == null:
			saved.emit(GdeI18n.t("не загружается %s") % path)
			return
		set_value(nm, res)
	else:
		set_value(nm, path)


func _find_prop(nm: String) -> Dictionary:
	for p: Dictionary in _info.get("props", []):
		if str(p["name"]) == nm:
			return p
	return {}


## Открыть сцену объекта и выделить узел поведения — для того, что удобнее
## править в инспекторе Godot (точки пути, например).
func open_in_inspector() -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface") or scene_path.is_empty():
		return
	await flush()
	var ei: Object = Engine.get_singleton("EditorInterface")
	ei.call("open_scene_from_path", scene_path)
	var root: Node = ei.call("get_edited_scene_root")
	if root == null:
		return
	var node := root.get_node_or_null(NodePath(str(_info.get("node", ""))))
	if node != null:
		ei.call("edit_node", node)


# ---------------------------------------------------------------- мелочи ---

func _group_caption(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(1, 1, 1, 0.5)
	l.clip_text = true
	box.add_child(l)
	return box


func _dim(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.5)
	l.clip_text = true
	return l
