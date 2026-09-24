## Объекты листа и их поведения — аналог редактора объектов в GDevelop.
##
## Слева список объектов, справа выбранный: сцена, поведения и проверка.
## Кнопка «Добавить поведение» сама кладёт ноду в сцену объекта —
## вручную лезть в дерево сцены больше не нужно. Щелчок по поведению
## открывает рядом его настройки, как в GDevelop.
@tool
class_name GdeObjectsDialog
extends AcceptDialog

signal objects_changed

var _doc: GdeSheetDocument
var _reg: GdeRegistry

var _list: ItemList
var _title: Label
var _scene_label: LineEdit
var _behaviors: VBoxContainer
var _detail: VBoxContainer
var _empty_hint: Label

var _name_edit: LineEdit
var _scene_edit: LineEdit
var _file: FileDialog
var _error: Label

var _checks: VBoxContainer
var _checks_caption: Label

var _tabs: TabContainer
var _beh_panel: GdeBehaviorPanel
var _beh_group: ButtonGroup
var _selected_behavior: String = ""
## имя поведения -> путь его узла в сцене объекта
var _beh_nodes: Dictionary = {}
## имя поведения -> скрипт, который реально стоит на объекте
var _beh_scripts: Dictionary = {}

var _beh_picker: GdeBehaviorPicker
var _confirm_delete: ConfirmationDialog
var _selected: int = -1


func _init() -> void:
	title = "Объекты листа"
	ok_button_text = "Закрыть"

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	# Без автопереноса и с clip_text: автоперенос в контейнере раздувает
	# минимальную высоту и выталкивает низ диалога за край.
	var hint := _note("Тип объекта — сцена .tscn. Перетащите сцену из файловой системы в список слева.")
	box.add_child(hint)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 220
	box.add_child(split)

	# ---- слева: список объектов
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.custom_minimum_size = Vector2(200, 0)
	split.add_child(left)
	left.add_child(_caption("ОБЪЕКТЫ"))

	var drop := GdeSceneDrop.new()
	drop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drop.dropped.connect(_add_scenes)
	left.add_child(drop)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_object_selected)
	drop.add_child(_list)

	# ---- справа: подробности объекта
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _panel_style())
	split.add_child(right)

	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 10)
	right.add_child(_detail)

	_empty_hint = Label.new()
	_empty_hint.text = "Выберите объект слева или добавьте новый внизу."
	_empty_hint.modulate = Color(1, 1, 1, 0.45)
	_empty_hint.clip_text = true
	_detail.add_child(_empty_hint)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 17)
	_detail.add_child(_title)

	var scene_row := HBoxContainer.new()
	scene_row.add_theme_constant_override("separation", 6)
	_detail.add_child(scene_row)
	_scene_label = LineEdit.new()
	_scene_label.editable = false
	_scene_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_row.add_child(_scene_label)
	var open_btn := Button.new()
	open_btn.text = "Открыть сцену"
	open_btn.pressed.connect(_open_scene)
	scene_row.add_child(open_btn)

	# Две вкладки: поведения с их настройками и проверка сцены. Вместе на
	# одном экране им тесно — настройки «Выстрела» одни занимают три экрана.
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(_tabs)

	var beh_split := HSplitContainer.new()
	beh_split.name = "Поведения"
	_tabs.add_child(beh_split)

	var beh_col := VBoxContainer.new()
	beh_col.custom_minimum_size = Vector2(250, 0)
	beh_col.add_theme_constant_override("separation", 6)
	beh_split.add_child(beh_col)

	var beh_scroll := ScrollContainer.new()
	beh_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	beh_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	beh_col.add_child(beh_scroll)
	_behaviors = VBoxContainer.new()
	_behaviors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_behaviors.add_theme_constant_override("separation", 2)
	beh_scroll.add_child(_behaviors)

	var add_beh := Button.new()
	add_beh.text = "  Добавить поведение"
	add_beh.icon = GdeIcons.get_icon("plus")
	add_beh.alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_beh.pressed.connect(_open_behavior_picker)
	beh_col.add_child(add_beh)

	var beh_right := PanelContainer.new()
	beh_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	beh_right.add_theme_stylebox_override("panel", _panel_style())
	beh_split.add_child(beh_right)
	_beh_panel = GdeBehaviorPanel.new()
	_beh_panel.message.connect(func(text: String, is_error: bool) -> void:
		if is_error:
			_set_error(text)
		else:
			_set_note(text)
			_update_file(_current_scene()))
	_beh_panel.left_for_editor.connect(hide)
	beh_right.add_child(_beh_panel)

	var checks_tab := VBoxContainer.new()
	checks_tab.name = "Проверка сцены"
	checks_tab.add_theme_constant_override("separation", 6)
	_tabs.add_child(checks_tab)
	_checks_caption = _caption("ПРОВЕРКА СЦЕНЫ")
	checks_tab.add_child(_checks_caption)

	# Прокрутка обязательна: длинные пояснения с переносом иначе раздули бы
	# минимальную высоту диалога и вытолкнули его за край экрана.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 90)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	checks_tab.add_child(scroll)
	_checks = VBoxContainer.new()
	_checks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_checks.add_theme_constant_override("separation", 6)
	scroll.add_child(_checks)

	var del_obj := Button.new()
	del_obj.text = "  Удалить объект из листа"
	del_obj.icon = GdeIcons.get_icon("trash")
	del_obj.alignment = HORIZONTAL_ALIGNMENT_LEFT
	del_obj.pressed.connect(_remove_object)
	_detail.add_child(del_obj)

	# ---- внизу: добавление объекта
	box.add_child(HSeparator.new())
	box.add_child(_caption("НОВЫЙ ОБЪЕКТ"))

	var form := HBoxContainer.new()
	form.add_theme_constant_override("separation", 6)
	box.add_child(form)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Имя, например Enemy"
	_name_edit.custom_minimum_size = Vector2(170, 0)
	_name_edit.text_changed.connect(func(_t): _clear_error())
	_name_edit.text_submitted.connect(func(_t): _add_object())
	form.add_child(_name_edit)

	_scene_edit = LineEdit.new()
	_scene_edit.placeholder_text = "res://…/enemy.tscn"
	_scene_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_edit.text_changed.connect(func(_t): _clear_error())
	form.add_child(_scene_edit)

	var browse := Button.new()
	browse.text = "Выбрать…"
	browse.pressed.connect(func(): GdeUi.popup_fit(_file, Vector2i(900, 620)))
	form.add_child(browse)

	var add := Button.new()
	add.text = "Добавить"
	add.icon = GdeIcons.get_icon("plus")
	add.pressed.connect(_add_object)
	form.add_child(add)

	_error = Label.new()
	_error.add_theme_color_override("font_color", Color(0.92, 0.45, 0.45))
	_error.clip_text = true
	_error.custom_minimum_size = Vector2(0, 18)
	box.add_child(_error)

	_file = FileDialog.new()
	_file.title = "Сцена объекта"
	_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file.access = FileDialog.ACCESS_RESOURCES
	_file.filters = PackedStringArray(["*.tscn ; Сцены"])
	_file.file_selected.connect(func(p: String):
		_scene_edit.text = p
		_clear_error()
		if _name_edit.text.strip_edges().is_empty():
			_name_edit.text = GdeBehaviorInstaller.pascal(p.get_file().get_basename()))
	add_child(_file)

	_beh_picker = GdeBehaviorPicker.new()
	_beh_picker.picked.connect(_install_behavior)
	add_child(_beh_picker)

	# Удаление объекта ломает все события, которые на него ссылаются —
	# одного клика для такого мало.
	_confirm_delete = ConfirmationDialog.new()
	_confirm_delete.title = "Удалить объект"
	_confirm_delete.ok_button_text = "Удалить"
	_confirm_delete.cancel_button_text = "Отмена"
	_confirm_delete.confirmed.connect(_do_remove_object)
	add_child(_confirm_delete)

	# Окно закрыли, пока правка настройки ждала записи, — записать сейчас.
	visibility_changed.connect(func() -> void:
		if not visible and _beh_panel.settings.has_pending():
			_beh_panel.settings.flush())


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(1, 1, 1, 0.5)
	l.clip_text = true
	return l


func _note(text: String) -> Label:
	var l := _caption(text)
	l.modulate = Color(1, 1, 1, 0.6)
	return l


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.03)
	sb.set_content_margin_all(12)
	sb.set_corner_radius_all(5)
	return sb


func open_for(doc: GdeSheetDocument, reg: GdeRegistry) -> void:
	_doc = doc
	_reg = reg
	_clear_error()
	_name_edit.text = ""
	_scene_edit.text = ""
	_refresh_list()
	GdeUi.popup_fit(self, Vector2i(1200, 880))


# ------------------------------------------------------------------ список ---

func _refresh_list() -> void:
	_list.clear()
	if _doc == null:
		return
	for o: Dictionary in _doc.objects():
		var idx := _list.add_item(str(o.get("name", "")), GdeThumbs.icon_for(str(o.get("scene", ""))))
		var scene := str(o.get("scene", ""))
		_list.set_item_tooltip(idx, scene)
		if not ResourceLoader.exists(scene):
			_list.set_item_custom_fg_color(idx, Color(0.92, 0.45, 0.45))
			_list.set_item_tooltip(idx, "%s — файл не найден" % scene)
			continue
		var found := GdeSceneCheck.check(scene, _reg, _doc.object_names())
		var errs := GdeSceneCheck.count(found, "error")
		var warns := GdeSceneCheck.count(found, "warn")
		if errs > 0:
			_list.set_item_custom_fg_color(idx, Color(0.95, 0.5, 0.5))
			_list.set_item_tooltip(idx, "%s — ошибок в сцене: %d" % [scene, errs])
		elif warns > 0:
			_list.set_item_custom_fg_color(idx, Color(0.95, 0.75, 0.4))
			_list.set_item_tooltip(idx, "%s — есть что поправить: %d" % [scene, warns])
	if _list.item_count > 0:
		var pick: int = clampi(_selected, 0, _list.item_count - 1)
		_list.select(pick)
		_on_object_selected(pick)
	else:
		_selected = -1
		_show_detail(false)


func _show_detail(visible_: bool) -> void:
	_empty_hint.visible = not visible_
	for c: Node in _detail.get_children():
		if c != _empty_hint:
			(c as CanvasItem).visible = visible_


func _on_object_selected(idx: int) -> void:
	_selected = idx
	var list: Array = _doc.objects()
	if idx < 0 or idx >= list.size():
		_show_detail(false)
		return
	_show_detail(true)
	var o: Dictionary = list[idx]
	_title.text = str(o.get("name", ""))
	_scene_label.text = str(o.get("scene", ""))
	_refresh_behaviors()


# --------------------------------------------------------------- поведения ---

func _current_scene() -> String:
	var list: Array = _doc.objects() if _doc != null else []
	if _selected < 0 or _selected >= list.size():
		return ""
	return str((list[_selected] as Dictionary).get("scene", ""))


func _refresh_behaviors() -> void:
	for c: Node in _behaviors.get_children():
		_behaviors.remove_child(c)
		c.queue_free()
	_beh_nodes.clear()
	_beh_scripts.clear()
	_beh_group = ButtonGroup.new()

	_refresh_checks()
	var scene := _current_scene()
	if scene.is_empty() or not ResourceLoader.exists(scene):
		var miss := Label.new()
		miss.text = "Сцена объекта не найдена — поведения недоступны."
		miss.modulate = Color(0.92, 0.45, 0.45)
		miss.clip_text = true
		_behaviors.add_child(miss)
		_beh_panel.show_empty("")
		return

	var found := GdeBehaviorInstaller.scan(scene)
	if found.is_empty():
		var none := Label.new()
		none.text = "Поведений нет."
		none.modulate = Color(1, 1, 1, 0.45)
		_behaviors.add_child(none)
		_beh_panel.show_empty("У объекта пока нет поведений. Поведение — это готовая способность: " +
				"бегать и прыгать, стрелять, получать урон. Добавьте первое кнопкой слева внизу.")
		return

	var names: Array[String] = []
	for e: Dictionary in found:
		var bname := str(e["name"])
		names.append(bname)
		_beh_nodes[bname] = str(e["node"])
		_beh_scripts[bname] = str(e.get("script", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		var b: Variant = _reg.behaviors.get(bname) if _reg != null else null
		var pick := Button.new()
		pick.toggle_mode = true
		pick.button_group = _beh_group
		_style_pick(pick)
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		pick.clip_text = true
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.icon = GdeIcons.get_icon(str((b as Dictionary).get("icon", "behavior")) if b != null else "behavior")
		pick.set_meta("gde_behavior", bname)
		if b != null:
			pick.text = str((b as Dictionary).get("title", bname))
			pick.tooltip_text = "%s\n\nУзел в сцене: %s" \
					% [str((b as Dictionary).get("description", "")), str(e["node"])]
		else:
			pick.text = bname
			pick.modulate = Color(0.92, 0.65, 0.35)
			pick.tooltip_text = "Скрипт поведения не найден в проекте"
		pick.pressed.connect(_select_behavior.bind(bname))
		row.add_child(pick)

		var del := Button.new()
		del.icon = GdeIcons.get_icon("trash")
		del.tooltip_text = "Убрать поведение из сцены объекта"
		del.flat = true
		del.pressed.connect(_uninstall_behavior.bind(bname))
		row.add_child(del)

		_behaviors.add_child(row)

	# Выбранное поведение переживает обновление списка — и переход к другому
	# объекту с тем же поведением: сравнивать настройки так удобнее.
	_select_behavior(_selected_behavior if names.has(_selected_behavior) else names[0])


## Строка поведения: без рамки, пока не выбрана, и с подсветкой выбранной —
## у плоской кнопки Godot подсветки нажатия нет вовсе.
func _style_pick(b: Button) -> void:
	var none := StyleBoxEmpty.new()
	none.set_content_margin_all(4)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.05)
	hover.set_content_margin_all(4)
	hover.set_corner_radius_all(3)
	var on := StyleBoxFlat.new()
	on.bg_color = Color(0.36, 0.55, 0.9, 0.22)
	on.border_color = Color(0.45, 0.62, 0.95, 0.9)
	on.border_width_left = 3
	on.set_content_margin_all(4)
	on.set_corner_radius_all(3)
	b.add_theme_stylebox_override("normal", none)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Показать настройки поведения справа.
func _select_behavior(bname: String) -> void:
	_selected_behavior = bname
	for row: Node in _behaviors.get_children():
		for c: Node in row.get_children():
			if c is Button and c.has_meta("gde_behavior"):
				(c as Button).set_pressed_no_signal(str(c.get_meta("gde_behavior")) == bname)
	_beh_panel.show_behavior(_current_scene(), bname, _reg,
			_doc.object_names() if _doc != null else [], str(_beh_nodes.get(bname, "")),
			str(_beh_scripts.get(bname, "")))


## Находки проверки для выбранного объекта, с кнопками исправления.
func _refresh_checks() -> void:
	if _checks == null:
		return
	for c: Node in _checks.get_children():
		_checks.remove_child(c)
		c.queue_free()
	var scene := _current_scene()
	if scene.is_empty() or not ResourceLoader.exists(scene):
		_checks_caption.text = "ПРОВЕРКА СЦЕНЫ"
		_set_checks_tab(0)
		return
	var found := GdeSceneCheck.check(scene, _reg, _doc.object_names())
	_set_checks_tab(found.size())
	if found.is_empty():
		_checks_caption.text = "ПРОВЕРКА СЦЕНЫ — ВСЁ В ПОРЯДКЕ"
		var ok := Label.new()
		ok.text = "Тела с формами, спрайты с картинками, анимации на месте."
		ok.modulate = Color(0.6, 0.85, 0.6)
		ok.clip_text = true
		_checks.add_child(ok)
		return
	_checks_caption.text = "ПРОВЕРКА СЦЕНЫ — НАХОДОК: %d" % found.size()
	for it: Dictionary in found:
		_checks.add_child(_check_row(scene, it))


## Число находок — прямо на ярлычке вкладки: иначе их не видно, пока
## смотришь на поведения.
func _set_checks_tab(n: int) -> void:
	if _tabs == null or _tabs.get_tab_count() < 2:
		return
	_tabs.set_tab_title(1, "Проверка сцены" if n == 0 else "Проверка сцены · %d" % n)
	_tabs.set_tab_icon(1, GdeIcons.get_icon("warning") if n > 0 else null)


func _check_row(scene: String, it: Dictionary) -> Control:
	var err := str(it["level"]) == "error"
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	var c := Color(0.93, 0.36, 0.36) if err else Color(0.93, 0.7, 0.3)
	sb.bg_color = Color(c.r, c.g, c.b, 0.08)
	sb.border_color = Color(c.r, c.g, c.b, 0.7)
	sb.border_width_left = 3
	sb.set_content_margin_all(6)
	sb.set_corner_radius_all(3)
	pc.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pc.add_child(box)

	var text := Label.new()
	text.text = str(it["text"])
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(text)

	var fixes: Array = it.get("fixes", [])
	if fixes.is_empty():
		return pc
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	for f: Dictionary in fixes:
		if str(f["id"]) == "pick_prop":
			# Выбор из готового списка: имя берётся из спрайта, опечатке неоткуда взяться.
			var mb := MenuButton.new()
			mb.text = str(f["label"]) + " ▾"
			mb.flat = false
			var arg: Array = f["arg"]
			var names: Array = arg[2]
			for i in range(names.size()):
				mb.get_popup().add_item(str(names[i]), i)
			mb.get_popup().id_pressed.connect(func(i: int):
				_apply_fix(scene, {"id": "set_prop", "arg": [arg[0], arg[1], str(names[i])]}))
			row.add_child(mb)
		else:
			var b := Button.new()
			b.text = str(f["label"])
			b.pressed.connect(_apply_fix.bind(scene, f))
			row.add_child(b)
	return pc


func _apply_fix(scene: String, one_fix: Dictionary) -> void:
	var err: String = await GdeSceneCheck.fix(scene, one_fix)
	if not err.is_empty():
		_set_error(err)
		return
	_set_note("Исправлено: %s" % str(one_fix.get("label", "")))
	_rescan_filesystem()
	var keep := _selected
	_refresh_list()
	if keep >= 0 and keep < _list.item_count:
		_list.select(keep)
		_on_object_selected(keep)
	objects_changed.emit()


## Открыть окно сразу на объекте, у которого есть что исправить.
func open_on_problem(doc: GdeSheetDocument, reg: GdeRegistry, object_name: String) -> void:
	var list: Array = doc.objects()
	for i in range(list.size()):
		if str((list[i] as Dictionary).get("name", "")) == object_name:
			_selected = i
			break
	open_for(doc, reg)
	_tabs.current_tab = 1


func _open_behavior_picker() -> void:
	var scene := _current_scene()
	if scene.is_empty():
		_set_error("Сначала выберите объект")
		return
	if _reg == null or _reg.behaviors.is_empty():
		_set_error("В проекте нет ни одного поведения")
		return
	_beh_picker.open_for(_reg, GdeBehaviorInstaller.installed(scene))


func _install_behavior(bname: String, script_path: String) -> void:
	var scene := _current_scene()
	if scene.is_empty():
		return
	var spec: Dictionary = {}
	var b: Variant = _reg.behaviors.get(bname) if _reg != null else null
	if b != null:
		spec = {"target": (b as Dictionary).get("target", ""),
				"needs": (b as Dictionary).get("needs", [])}
	await _beh_panel.settings.flush()
	var res := await GdeBehaviorInstaller.add(scene, bname, script_path, spec)
	var err := str(res.get("error", ""))
	if not err.is_empty():
		_set_error(err)
		return
	_clear_error()
	# Как в GDevelop: поставил поведение — сразу видишь его настройки.
	_selected_behavior = bname
	_tabs.current_tab = 0
	_refresh_behaviors()
	_rescan_filesystem()
	var created: Array = res.get("created", [])
	if not created.is_empty():
		_set_note("Поведение добавлено, настройки — справа. Для него в сцену добавлено: %s" % ", ".join(created))
	else:
		_set_note("Поведение добавлено, его настройки — справа")


func _uninstall_behavior(bname: String) -> void:
	var scene := _current_scene()
	if scene.is_empty():
		return
	# Недописанная правка настроек не должна прилететь в уже снятое поведение.
	await _beh_panel.settings.flush()
	var err := await GdeBehaviorInstaller.remove(scene, bname)
	if not err.is_empty():
		_set_error(err)
		return
	_clear_error()
	_refresh_behaviors()
	_rescan_filesystem()


# ------------------------------------------------------------------ объекты ---

func _add_object() -> void:
	if _doc == null:
		return
	var n := _name_edit.text.strip_edges()
	var s := _scene_edit.text.strip_edges()
	if n.is_empty():
		_set_error("Укажите имя объекта")
		return
	if not _is_valid_name(n):
		_set_error("Имя: латинские буквы, цифры и _, не начиная с цифры")
		return
	if _doc.object_names().has(n):
		_set_error("Объект «%s» уже есть в листе" % n)
		return
	if not s.begins_with("res://") or not s.ends_with(".tscn"):
		_set_error("Выберите сцену .tscn внутри проекта")
		return
	if not ResourceLoader.exists(s):
		_set_error("Файл %s не найден" % s)
		return
	_doc.add_object(n, s)
	_name_edit.text = ""
	_scene_edit.text = ""
	_clear_error()
	_selected = _doc.objects().size() - 1
	_refresh_list()
	objects_changed.emit()


func _remove_object() -> void:
	if _doc == null or _selected < 0:
		_set_error("Сначала выберите объект")
		return
	var list: Array = _doc.objects()
	var nm := str((list[_selected] as Dictionary).get("name", "")) if _selected < list.size() else ""
	_confirm_delete.dialog_text = \
			"Убрать объект «%s» из листа?\nСобытия, ссылающиеся на него, перестанут собираться.\nСама сцена не удаляется." % nm
	GdeUi.popup_fit(_confirm_delete, Vector2i(460, 320))


func _do_remove_object() -> void:
	if _doc == null or _selected < 0:
		return
	_doc.remove_object(_selected)
	_selected = maxi(0, _selected - 1)
	_clear_error()
	_refresh_list()
	objects_changed.emit()


func _open_scene() -> void:
	var scene := _current_scene()
	if scene.is_empty() or not _in_editor():
		return
	var ei: Object = Engine.get_singleton("EditorInterface")
	ei.call("open_scene_from_path", scene)
	hide()


## Сообщить редактору, что файл сцены переписан, — без полного пересканирования.
func _update_file(path: String) -> void:
	if path.is_empty() or not _in_editor():
		return
	var ei: Object = Engine.get_singleton("EditorInterface")
	var fs: Object = ei.call("get_resource_filesystem")
	if fs != null:
		fs.call("update_file", path)


func _rescan_filesystem() -> void:
	if not _in_editor():
		return
	var ei: Object = Engine.get_singleton("EditorInterface")
	var fs: Object = ei.call("get_resource_filesystem")
	if fs != null:
		fs.call("scan")


## Сцены принесли мышью. Имя объекта берём из имени файла и, если
## такое уже занято, добавляем номер — молча терять брошенное нельзя.
func _add_scenes(paths: Array) -> void:
	if _doc == null:
		return
	var added: Array[String] = []
	for p: Variant in paths:
		var scene := str(p)
		if not ResourceLoader.exists(scene):
			continue
		var nm := GdeBehaviorInstaller.pascal(scene.get_file().get_basename())
		var base := nm
		var i := 2
		while _doc.object_names().has(nm):
			nm = "%s%d" % [base, i]
			i += 1
		_doc.add_object(nm, scene)
		added.append(nm)
	if added.is_empty():
		return
	_selected = _doc.objects().size() - 1
	_refresh_list()
	objects_changed.emit()
	_set_note("Добавлено: %s" % ", ".join(added))


func _set_error(text: String) -> void:
	_error.add_theme_color_override("font_color", Color(0.92, 0.45, 0.45))
	_error.text = text


## Добрая весть в той же строке, что и ошибки: глаз уже туда смотрит.
func _set_note(text: String) -> void:
	_error.add_theme_color_override("font_color", Color(0.55, 0.78, 0.55))
	_error.text = text


func _clear_error() -> void:
	_error.text = ""


## Engine.has_singleton("EditorInterface") верит и вне редактора, а
## get_singleton тогда падает — в запущенной сцене (тестах) окно тоже живёт.
static func _in_editor() -> bool:
	return Engine.is_editor_hint() and Engine.has_singleton("EditorInterface")


static func _is_valid_name(n: String) -> bool:
	if n.is_empty() or (n[0] >= "0" and n[0] <= "9"):
		return false
	for c: String in n:
		var ok := (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
				or (c >= "0" and c <= "9") or c == "_"
		if not ok:
			return false
	return true
