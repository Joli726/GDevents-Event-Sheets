## Главная вкладка редактора событий.
##
## Держит документ, реестр и все диалоги. Строки событий дёргают его
## методы напрямую — для редактора это проще и прозрачнее цепочки сигналов.
@tool
class_name GdeEventSheetPanel
extends VBoxContainer

const DEFAULT_ACCENT := Color(1, 0.78, 0.42)
## События, у которых условия можно соединить через «или».
const ANY_TYPES := ["standard", "foreach", "while"]
## События, у которых бывают локальные переменные.
const LOCALS_TYPES := ["standard", "foreach", "repeat", "while"]

## Выбран другой язык — плагин перестроит панель на нём.
signal language_changed(code: String)

var doc: GdeSheetDocument
var registry: GdeRegistry
var accent: Color = DEFAULT_ACCENT

## Автосохранение. Выключается только инструментами: тесты и снимки
## гонят панель на настоящих листах проекта, и записывать туда свои правки они не вправе.
var autosave_enabled: bool = true

var _sheets: OptionButton
var _rows: VBoxContainer
var _scroll: ScrollContainer
var _status: RichTextLabel
var _lang: OptionButton
var _save_btn: Button
var _undo_btn: Button
var _redo_btn: Button

var _picker: GdeInstructionPicker
var _objects: GdeObjectsDialog
var _new_file: FileDialog
var _bind_file: FileDialog
var _warn_bar: PanelContainer
var _warn_label: Label
var _inst_menu: PopupMenu
var _event_menu: PopupMenu
var _autosave: Timer
var _problems_btn: Button
var _first_problem: String = ""

var _sheet_paths: Array[String] = []
var _menu_path: Array = []
var _menu_kind: String = ""
var _menu_index: int = 0
var _pending_add: Array = []
var _pending_kind: String = ""
var _editing: Array = []

## Что сейчас выделено: "" — ничего, "instruction" или "event".
var _sel_what: String = ""
var _sel_path: Array = []
var _sel_kind: String = ""
var _sel_index: int = -1

## Буфер обмена общий на все листы — иначе перенести событие между листами
## было бы нечем. static, чтобы пережить пересоздание панели.
static var _clip_instruction: Dictionary = {}
static var _clip_inst_kind: String = ""
static var _clip_event: Dictionary = {}

## Ошибки листа, найденные на лету: ключ — путь события строкой,
## значение — [{"text", "inst"}]. Считаются при каждой перерисовке,
## поэтому сломанная строка краснеет сразу, а не при запуске игры.
var _live_errors: Dictionary = {}
var _live_error_count: int = 0


func _ready() -> void:
	accent = _editor_accent()
	registry = GdeRegistry.load_default()
	_build_ui()

	# Автосохранение. Кнопка «Сохранить» осталась, но забыть про неё больше
	# не страшно: через секунду после последней правки лист ляжет на диск сам.
	_autosave = Timer.new()
	_autosave.one_shot = true
	_autosave.wait_time = 1.0
	_autosave.timeout.connect(_autosave_now)
	add_child(_autosave)

	refresh_sheet_list()


# --------------------------------------------------------------- интерфейс ---

func _icon_button(icon: String, tip: String, cb: Callable, label: String = "") -> Button:
	var b := Button.new()
	b.icon = GdeIcons.get_icon(icon)
	b.tooltip_text = tip
	if not label.is_empty():
		b.text = "  " + label
	b.pressed.connect(cb)
	return b


func _build_ui() -> void:
	add_theme_constant_override("separation", 0)
	# Фокус нужен горячим клавишам, PASS — чтобы сцену из файловой
	# системы можно было бросить куда угодно в панель, а не в одну точку.
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Панель инструментов переносится на вторую строку, а не распирает окно.
	# Когда она была одной строкой, её минимальная ширина доросла до 1700 px:
	# в редакторе с доками панель вылезала за край, и справа обрезалось всё —
	# в том числе кнопки «дублировать / выключить / удалить» у событий.
	var bar := HFlowContainer.new()
	bar.add_theme_constant_override("h_separation", 6)
	bar.add_theme_constant_override("v_separation", 6)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	m.add_child(bar)
	add_child(m)

	_sheets = OptionButton.new()
	_sheets.custom_minimum_size = Vector2(250, 0)
	_sheets.tooltip_text = GdeI18n.t("Лист событий")
	_sheets.item_selected.connect(_on_sheet_selected)
	bar.add_child(_sheets)

	bar.add_child(_icon_button("refresh", GdeI18n.t("Перечитать поведения и список листов"), _reload))
	bar.add_child(_icon_button("newfile", GdeI18n.t("Создать новый лист"), func():
		GdeUi.popup_fit(_new_file, Vector2i(900, 620))))

	bar.add_child(_sep())

	var add_menu := MenuButton.new()
	add_menu.text = GdeI18n.t("  Добавить событие")
	add_menu.icon = GdeIcons.get_icon("plus")
	var am := add_menu.get_popup()
	am.add_icon_item(GdeIcons.get_icon("action"), GdeI18n.t("Обычное событие"), 0)
	am.add_icon_item(GdeIcons.get_icon("comment"), GdeI18n.t("Комментарий"), 1)
	am.add_icon_item(GdeIcons.get_icon("foreach"), GdeI18n.t("Для каждого объекта"), 2)
	am.add_icon_item(GdeIcons.get_icon("repeat"), GdeI18n.t("Повторить N раз"), 3)
	am.add_icon_item(GdeIcons.get_icon("refresh"), GdeI18n.t("Пока выполняется"), 4)
	am.add_icon_item(GdeIcons.get_icon("group"), GdeI18n.t("Группа"), 5)
	am.add_icon_item(GdeIcons.get_icon("link"), GdeI18n.t("Подключить лист"), 6)
	am.set_item_tooltip(am.item_count - 1, GdeI18n.t("События другого листа — управление игроком, пауза, счёт — собираются здесь, как будто их скопировали. Правка общего листа доходит до всех, кто его подключил"))
	am.id_pressed.connect(_on_add_root_event)
	bar.add_child(add_menu)

	bar.add_child(_icon_button("object", GdeI18n.t("Объекты листа и их поведения"), func():
		if doc != null:
			_objects.open_for(doc, registry), GdeI18n.t("Объекты")))

	# Проблемы в сценах объектов: тело без формы, пустой спрайт, анимация
	# с опечаткой. Godot о них молчит, поэтому кнопка видна всегда, пока
	# есть что исправить, и ведёт прямо к объекту с проблемой.
	_problems_btn = _icon_button("warning", "", func():
		if doc != null:
			_objects.open_on_problem(doc, registry, _first_problem), "")
	_problems_btn.visible = false
	bar.add_child(_problems_btn)

	bar.add_child(_sep())

	_undo_btn = _icon_button("undo", GdeI18n.t("Отменить"), func():
		if doc != null:
			doc.undo())
	bar.add_child(_undo_btn)
	_redo_btn = _icon_button("redo", GdeI18n.t("Повторить"), func():
		if doc != null:
			doc.redo())
	bar.add_child(_redo_btn)

	_save_btn = _icon_button("save",
			GdeI18n.t("Сохранить лист (Ctrl+S). Лист и так сохраняется сам через секунду после правки"),
			save_sheet, GdeI18n.t("Сохранить"))
	bar.add_child(_save_btn)
	bar.add_child(_icon_button("build",
			GdeI18n.t("Собрать GDScript сейчас (Ctrl+B). Перед запуском игры сборка идёт сама"),
			save_and_build, GdeI18n.t("Собрать")))

	# Статус занимает остаток строки. Жёсткий минимум в 440 px убран: длинное
	# сообщение переносится внутри, а не толкает панель за край окна.
	# Статус — всегда одна строка: длинное сообщение с переносом растягивало
	# по высоте всю панель инструментов. Что не влезло — в подсказке.
	_status = RichTextLabel.new()
	_status.bbcode_enabled = true
	_status.fit_content = false
	_status.scroll_active = false
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.clip_contents = true
	_status.custom_minimum_size = Vector2(220, 24)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_status)

	# Язык плагина — на виду, в конце панели инструментов. Смену выполняет
	# плагин: всё, что построено на старом языке, строится заново.
	_lang = OptionButton.new()
	for i in range(GdeI18n.LANGUAGES.size()):
		_lang.add_item(str(GdeI18n.NAMES[GdeI18n.LANGUAGES[i]]), i)
	_lang.select(maxi(0, GdeI18n.LANGUAGES.find(GdeI18n.language())))
	_lang.tooltip_text = "Language / Язык"  # i18n: как есть
	_lang.item_selected.connect(func(i: int) -> void:
		var code: String = GdeI18n.LANGUAGES[i]
		if code != GdeI18n.language():
			language_changed.emit(code))
	bar.add_child(_lang)
	# Кнопки не тянутся по высоте строки, даже если соседу понадобилось больше.
	for c: Node in bar.get_children():
		(c as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER

	add_child(HSeparator.new())

	# Полоса «лист ни к чему не привязан» — самая частая причина
	# «собрал, запустил, ничего не происходит».
	_warn_bar = PanelContainer.new()
	var warn_sb := StyleBoxFlat.new()
	warn_sb.bg_color = Color(0.85, 0.62, 0.25, 0.18)
	warn_sb.border_color = Color(0.85, 0.62, 0.25, 0.55)
	warn_sb.border_width_left = 3
	warn_sb.set_content_margin_all(8)
	_warn_bar.add_theme_stylebox_override("panel", warn_sb)
	_warn_bar.visible = false
	add_child(_warn_bar)

	var warn_row := HBoxContainer.new()
	warn_row.add_theme_constant_override("separation", 10)
	_warn_bar.add_child(warn_row)

	_warn_label = Label.new()
	_warn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_warn_label.clip_text = true
	warn_row.add_child(_warn_label)

	var bind_btn := Button.new()
	bind_btn.text = GdeI18n.t("  Привязать к сцене…")
	bind_btn.icon = GdeIcons.get_icon("scene")
	bind_btn.pressed.connect(func(): GdeUi.popup_fit(_bind_file, Vector2i(900, 620)))
	warn_row.add_child(bind_btn)

	# Шапка колонок — чтобы сразу было видно, где что.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 24)
	hm.add_theme_constant_override("margin_right", 16)
	hm.add_theme_constant_override("margin_top", 6)
	hm.add_theme_constant_override("margin_bottom", 2)
	hm.add_child(head)
	add_child(hm)
	head.add_child(_column_caption(GdeI18n.t("УСЛОВИЯ"), 0.45))
	head.add_child(_column_caption(GdeI18n.t("ДЕЙСТВИЯ"), 0.55))

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 2)
	pad.add_theme_constant_override("margin_bottom", 60)
	_scroll.add_child(pad)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 5)
	pad.add_child(_rows)

	_picker = GdeInstructionPicker.new()
	_picker.chosen.connect(_on_picker_chosen)
	add_child(_picker)

	_objects = GdeObjectsDialog.new()
	# Поведения пишутся в .tscn сразу, поэтому и список объектов
	# сохраняем сразу — иначе они разъедутся.
	_objects.objects_changed.connect(func():
		_rebuild()
		save_sheet()
		check_objects())
	# Своя копия поведения или новое поведение — у листа тот же реестр, что
	# и у окна, иначе в списке действий осталось бы старое.
	_objects.library_changed.connect(func(reg: GdeRegistry):
		registry = reg
		_rebuild()
		check_objects())
	add_child(_objects)

	_new_file = FileDialog.new()
	_new_file.title = GdeI18n.t("Новый лист событий")
	_new_file.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_new_file.access = FileDialog.ACCESS_RESOURCES
	_new_file.filters = PackedStringArray([GdeI18n.t("*.gdes.json ; Листы событий")])
	_new_file.current_file = "events.gdes.json"
	_new_file.file_selected.connect(_create_sheet)
	add_child(_new_file)

	_bind_file = FileDialog.new()
	_bind_file.title = GdeI18n.t("К какой сцене привязать лист")
	_bind_file.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_bind_file.access = FileDialog.ACCESS_RESOURCES
	_bind_file.filters = PackedStringArray([GdeI18n.t("*.tscn ; Сцены")])
	_bind_file.file_selected.connect(_attach_to_scene)
	add_child(_bind_file)

	_inst_menu = PopupMenu.new()
	_inst_menu.id_pressed.connect(_on_inst_menu)
	add_child(_inst_menu)

	_event_menu = PopupMenu.new()
	_event_menu.id_pressed.connect(_on_event_menu)
	add_child(_event_menu)


func _sep() -> VSeparator:
	var s := VSeparator.new()
	s.modulate = Color(1, 1, 1, 0.3)
	return s


func _column_caption(text: String, ratio: float) -> Label:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_stretch_ratio = ratio
	l.add_theme_font_size_override("font_size", 10)
	l.modulate = Color(1, 1, 1, 0.35)
	return l


## Панель должна строиться и вне редактора — это даёт возможность гонять
## безголовый тест. has_singleton() здесь не сторож: он отвечает true даже
## там, где get_singleton() уже ругается.
func _editor_singleton() -> Object:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return null
	return Engine.get_singleton("EditorInterface")


func _editor_accent() -> Color:
	var ei := _editor_singleton()
	if ei == null:
		return DEFAULT_ACCENT
	var theme: Theme = ei.call("get_editor_theme")
	if theme != null and theme.has_color("accent_color", "Editor"):
		return theme.get_color("accent_color", "Editor")
	return DEFAULT_ACCENT


# ------------------------------------------------------------------- листы ---

func refresh_sheet_list() -> void:
	var keep := doc.path if doc != null else ""
	_sheet_paths = GdeBuild.find_sheets("res://")
	_sheets.clear()
	if _sheet_paths.is_empty():
		_sheets.add_item(GdeI18n.t("— листов нет —"), 0)
		_sheets.disabled = true
		_set_status(GdeI18n.t("Нет ни одного листа. Нажмите иконку «Создать новый лист»."), true)
		return
	_sheets.disabled = false
	var select := 0
	var found := false
	for i in range(_sheet_paths.size()):
		_sheets.add_item(_sheet_paths[i].replace("res://", ""), i)
		if _sheet_paths[i] == keep:
			select = i
			found = true
	_sheets.selected = select

	# Переоткрываем только если документа ещё нет или его файл пропал.
	# Раньше здесь был безусловный open_sheet(), и каждый возврат
	# на вкладку тихо терял несохранённые правки.
	if doc == null or not found:
		open_sheet(_sheet_paths[select])


func _on_sheet_selected(i: int) -> void:
	if i < 0 or i >= _sheet_paths.size():
		return
	if doc != null and _sheet_paths[i] == doc.path:
		return
	# Перед уходом на другой лист сохраняем: кнопки «отменить и не сохранять»
	# в редакторе нет, а молча терять работу хуже.
	if doc != null and doc.is_dirty():
		var err := doc.save()
		if not err.is_empty():
			_set_status(err, true)
			return
	open_sheet(_sheet_paths[i])


## Перечитать поведения и список листов. Лист перечитывается с диска
## только если в нём нет несохранённых правок.
func _reload() -> void:
	registry = GdeRegistry.load_default()
	if doc != null and doc.is_dirty():
		refresh_sheet_list()
		_rebuild()
		_set_status(GdeI18n.t("Поведения обновлены. Лист не перечитан — есть несохранённые правки."), false)
		return
	var keep := doc.path if doc != null else ""
	doc = null
	refresh_sheet_list()
	if not keep.is_empty() and _sheet_paths.has(keep):
		open_sheet(keep)


## Листы, которые можно подключить к открытому: все, кроме него самого.
func includable_sheets() -> Array[String]:
	var out: Array[String] = []
	for p: String in _sheet_paths:
		if doc == null or p != doc.path:
			out.append(p)
	return out


## Перейти к другому листу, сохранив правки этого — как при выборе в списке.
func go_to_sheet(p: String) -> void:
	var i := _sheet_paths.find(p)
	if i < 0:
		_set_status(GdeI18n.t("листа %s нет") % p, true)
		return
	_sheets.select(i)
	_on_sheet_selected(i)


func open_sheet(p: String) -> void:
	var d := GdeSheetDocument.new()
	var err := d.load_from(p)
	if not err.is_empty():
		_set_status(err, true)
		return
	doc = d
	doc.changed.connect(_rebuild)
	_rebuild()
	check_objects()
	_set_status(GdeI18n.t("Открыт %s") % p.get_file(), false)
	_check_binding()


## Путь к GDScript, который собирается из текущего листа.
func _script_path() -> String:
	if doc == null or doc.path.is_empty():
		return ""
	return doc.path.trim_suffix(GdeBuild.SHEET_SUFFIX) + ".gd"


## Лист без сцены не исполняется вообще — об этом надо говорить громко.
## Проверить сцены всех объектов листа и показать итог на кнопке.
func check_objects() -> void:
	if _problems_btn == null:
		return
	_first_problem = ""
	var errs := 0
	var warns := 0
	if doc != null:
		for o: Dictionary in doc.objects():
			var found := GdeSceneCheck.check(str(o.get("scene", "")), registry, doc.object_names())
			var e := GdeSceneCheck.count(found, "error")
			var w := GdeSceneCheck.count(found, "warn")
			if (e > 0 or w > 0) and _first_problem.is_empty():
				_first_problem = str(o.get("name", ""))
			errs += e
			warns += w
	_problems_btn.visible = errs + warns > 0
	if errs > 0:
		_problems_btn.text = GdeI18n.t("  Ошибок в объектах: %d") % errs
		_problems_btn.modulate = Color(1, 0.6, 0.6)
	else:
		_problems_btn.text = GdeI18n.t("  Поправить в объектах: %d") % warns
		_problems_btn.modulate = Color(1, 0.85, 0.55)
	_problems_btn.tooltip_text = GdeI18n.t("В сценах объектов есть то, из-за чего игра поведёт себя не так, как задумано. Нажмите — откроется объект с находками и кнопками исправления.")


func _check_binding() -> void:
	if _warn_bar == null:
		return
	var sp := _script_path()
	if sp.is_empty():
		_warn_bar.visible = false
		return
	if not ResourceLoader.exists(sp):
		_warn_label.text = GdeI18n.t("Лист ещё не собран. Нажмите «Собрать», а потом привяжите к сцене.")
		_warn_bar.visible = true
		return
	var scenes := GdeSheetBinder.users(sp)
	if scenes.is_empty():
		_warn_label.text = GdeI18n.t("Этот лист ни к одной сцене не привязан — в игре он не работает.")
		_warn_bar.visible = true
	else:
		_warn_bar.visible = false


func _attach_to_scene(scene_path: String) -> void:
	if doc == null:
		return
	var err := GdeSheetBinder.attach(scene_path, _script_path(), doc.path)
	if not err.is_empty():
		_set_status(err, true)
		return
	_set_status(GdeI18n.t("Лист привязан к %s — теперь события будут исполняться") % scene_path.get_file(), false)
	var ei := _editor_singleton()
	if ei != null:
		var fs: Object = ei.call("get_resource_filesystem")
		if fs != null:
			fs.call("scan")
	_check_binding()


## Имя обязано оканчиваться на .gdes.json — именно по этому суффиксу
## сборщик находит листы и вычисляет имя соседнего .gd.
func _create_sheet(p: String) -> void:
	if not p.ends_with(GdeBuild.SHEET_SUFFIX):
		p = p.trim_suffix(".json").trim_suffix(".gdes") + GdeBuild.SHEET_SUFFIX
	if FileAccess.file_exists(p):
		_set_status(GdeI18n.t("Файл %s уже есть — выберите другое имя") % p.get_file(), true)
		return
	var d := GdeSheetDocument.create_empty(p.get_file().trim_suffix(GdeBuild.SHEET_SUFFIX))
	d.path = p
	var err := d.save()
	if not err.is_empty():
		_set_status(err, true)
		return
	doc = null
	refresh_sheet_list()
	for i in range(_sheet_paths.size()):
		if _sheet_paths[i] == p:
			_sheets.selected = i
			open_sheet(p)
			break
	_set_status(GdeI18n.t("Создан %s — добавьте объекты кнопкой «Объекты»") % p.get_file(), false)


func save_sheet() -> void:
	if doc == null:
		return
	var err := doc.save()
	if err.is_empty():
		_set_status(GdeI18n.t("Сохранён %s") % doc.path.get_file(), false)
		_refresh_buttons()
	else:
		_set_status(err, true)


func save_and_build() -> void:
	if doc == null:
		return
	var err := doc.save()
	if not err.is_empty():
		_set_status(err, true)
		return
	_refresh_buttons()
	var report := GdeBuild.build_all()
	for line: String in report["log"]:
		print(line)
	if report["failed"] > 0:
		_set_status(GdeI18n.t("Сборка не удалась — подробности в консоли (%d лист.)") % report["failed"], true)
	else:
		_set_status(GdeI18n.t("Собрано листов: %d") % report["ok"], false)
	_check_binding()
	var ei := _editor_singleton()
	if ei != null:
		var fs: Object = ei.call("get_resource_filesystem")
		if fs != null:
			fs.call("scan")


# ---------------------------------------------------------------- отрисовка ---

## recheck=false — только перерисовка (смена выделения): лист не менялся,
## и прогонять генератор на каждый щелчок незачем.
func _rebuild(recheck: bool = true) -> void:
	if _rows == null or _scroll == null:
		return
	var scroll_y := _scroll.scroll_vertical
	for c: Node in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	if doc == null:
		return
	if recheck:
		if _autosave != null and autosave_enabled:
			_autosave.start()
		_live_check()
	var events: Array = doc.data.get("events", [])
	for i in range(events.size()):
		var row := GdeEventRow.new()
		_rows.add_child(row)
		row.setup(self, [i], events[i], accent)
	if events.is_empty():
		_rows.add_child(_empty_state())
	_refresh_buttons()
	await get_tree().process_frame
	_scroll.scroll_vertical = scroll_y


## Собрать лист в памяти и разложить ошибки по строкам. Генератор быстрый,
## а знать об ошибке в момент правки несравнимо удобнее, чем при запуске.
func _live_check() -> void:
	_live_errors.clear()
	_live_error_count = 0
	if doc == null or registry == null:
		return
	var res := GdeGenerator.generate(doc.data, registry, doc.path)
	for item: Dictionary in res.get("error_items", []):
		var key := str(item.get("path", []))
		if not _live_errors.has(key):
			_live_errors[key] = []
		(_live_errors[key] as Array).append(item)
		_live_error_count += 1
	if _live_error_count > 0:
		_set_status(GdeI18n.t("Ошибок в листе: %d — строки подсвечены красным, наведите для подробностей")
				% _live_error_count, true)


## Все ошибки события — для подсветки карточки.
func event_errors(p: Array) -> Array[String]:
	var out: Array[String] = []
	for item: Dictionary in _live_errors.get(str(p), []):
		out.append(str(item["text"]))
	return out


## Ошибка конкретной строки или пустая строка.
func instruction_error(p: Array, kind: String, index: int) -> String:
	for item: Dictionary in _live_errors.get(str(p), []):
		var inst: Array = item.get("inst", [])
		if inst.size() == 2 and str(inst[0]) == kind and int(inst[1]) == index:
			return str(item["text"])
	return ""


func _empty_state() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 40)
	m.add_child(box)

	var t := Label.new()
	t.text = GdeI18n.t("Лист пуст")
	t.add_theme_font_size_override("font_size", 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)

	var s := Label.new()
	s.text = GdeI18n.t("1. «Объекты» — добавьте сцены, из которых состоит игра.\n") \
			+ GdeI18n.t("2. «Добавить событие» — создайте первое событие.\n") \
			+ GdeI18n.t("3. «+ Условие» и «+ Действие» внутри события.\n") \
			+ GdeI18n.t("4. «Собрать» — и запускайте сцену.")
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.modulate = Color(1, 1, 1, 0.5)
	box.add_child(s)
	return m


func _refresh_buttons() -> void:
	if doc == null or _save_btn == null:
		return
	_undo_btn.disabled = not doc.can_undo()
	_redo_btn.disabled = not doc.can_redo()
	_save_btn.text = GdeI18n.t("  Сохранить *") if doc.is_dirty() else GdeI18n.t("  Сохранить")


func _set_status(text: String, is_error: bool) -> void:
	if _status == null:
		return
	var color := "#d98b8b" if is_error else "#8fbf8f"
	_status.text = "[right][color=%s]%s[/color][/right]" % [color, text]
	_status.tooltip_text = text


# ------------------------------------------------ сохранение и сборка ---

## Молча положить лист на диск, если он изменился. Зовётся и по таймеру,
## и из плагина — перед запуском игры и при Ctrl+S в редакторе.
func save_if_dirty() -> void:
	if doc == null or not doc.is_dirty():
		return
	var err := doc.save()
	if err.is_empty():
		_set_status(GdeI18n.t("Сохранено"), false)
		_refresh_buttons()
	else:
		_set_status(err, true)


func _autosave_now() -> void:
	if autosave_enabled:
		save_if_dirty()


func report_build_failure(report: Dictionary) -> void:
	_set_status(GdeI18n.t("Сборка не удалась (%d лист.) — подробности в консоли") % report["failed"], true)


# -------------------------------------------------- вызовы из строк ---

func object_names() -> Array:
	return doc.object_names() if doc != null else []


func instruction_def(kind: String, id: String) -> Variant:
	if registry == null:
		return null
	return registry.condition(id) if kind == "conditions" else registry.action(id)


func set_event_field(p: Array, key: String, value: Variant) -> void:
	if doc != null:
		doc.set_event_field(p, key, value)


## Объект, с которым событие уже работает — пикер откроется сразу на нём.
func _preferred_object(p: Array) -> String:
	var e: Variant = doc.event_at(p)
	if e == null:
		return ""
	var d: Dictionary = e
	if str(d.get("type", "")) == "foreach":
		return str(d.get("object", ""))
	for kind: String in ["conditions", "actions"]:
		for inst: Dictionary in d.get(kind, []):
			var def: Variant = instruction_def(kind, str(inst.get("id", "")))
			if def == null:
				continue
			var defs: Array = (def as Dictionary).get("params", [])
			var raw: Array = inst.get("params", [])
			for i in range(mini(defs.size(), raw.size())):
				if str((defs[i] as Dictionary).get("kind", "")) == "object":
					return str(raw[i])
	return ""


func add_instruction(p: Array, kind: String) -> void:
	if doc == null:
		return
	_pending_add = p
	_pending_kind = kind
	_editing = []
	_picker.open_add(registry, doc, kind, _preferred_object(p), accent)


## Правка строки — в том же окне, где её выбирали: условие уже выбрано,
## поля заполнены, и его можно заменить другим, как в GDevelop.
func edit_instruction(p: Array, kind: String, index: int) -> void:
	var list := doc.instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	var inst: Dictionary = list[index]
	if instruction_def(kind, str(inst.get("id", ""))) == null:
		_set_status(GdeI18n.t("Инструкция «%s» больше не существует") % str(inst.get("id", "")), true)
		return
	_editing = [p, kind, index]
	_picker.open_edit(registry, doc, kind, inst, accent)


## Окно выбора вернуло готовую строку. Строка попадает в лист только здесь —
## раньше она добавлялась до ввода параметров, и «Отмена» оставляла в листе
## недозаполненную.
func _on_picker_chosen(id: String, params: Array, flags: Dictionary) -> void:
	var inst := {"id": id, "params": params}
	for key: String in ["inverted", "disabled"]:
		if bool(flags.get(key, false)):
			inst[key] = true
	if _editing.size() == 3:
		doc.replace_instruction(_editing[0], _editing[1], _editing[2], inst)
		select_instruction(_editing[0], _editing[1], _editing[2])
		_editing = []
		return
	doc.insert_instruction(_pending_add, _pending_kind, 9999, inst)
	var idx := doc.instructions_of(_pending_add, _pending_kind).size() - 1
	select_instruction(_pending_add, _pending_kind, idx)


# ------------------------------------------------------------- выделение ---
#
# Выделение нужно горячим клавишам: Delete, Ctrl+C и Ctrl+V должны понимать,
# с чем работают. Раньше выделения не было вовсе, и всё шло через меню.

func select_instruction(p: Array, kind: String, index: int) -> void:
	_sel_what = "instruction"
	_sel_path = p.duplicate()
	_sel_kind = kind
	_sel_index = index
	grab_focus()
	_refresh_selection()


func select_event(p: Array) -> void:
	_sel_what = "event"
	_sel_path = p.duplicate()
	_sel_kind = ""
	_sel_index = -1
	grab_focus()
	_refresh_selection()


## Перекрасить выделение на месте, не пересобирая строки.
##
## Раньше выделение перерисовывало весь лист. Выделяется строка по нажатию
## кнопки мыши — и строка, на которой кнопку зажали, тут же уничтожалась.
## Перетаскивание начинается только после нажатия, поэтому оно не начиналось
## никогда: ни у условий с действиями, ни у событий за ручку.
func _refresh_selection() -> void:
	_apply_selection(_rows)


func _apply_selection(n: Node) -> void:
	for c: Node in n.get_children():
		if c is GdeInstructionItem:
			var it := c as GdeInstructionItem
			it.set_selected(is_instruction_selected(it.path, it.kind, it.index))
		elif c is GdeEventCard:
			var card := c as GdeEventCard
			card.set_selected(is_event_selected(card.path))
		_apply_selection(c)


## Во время перетаскивания линия «встанет сюда» горит только у одной строки:
## строка, с которой курсор ушёл, гасит свою по этому вызову.
var _drop_marked: Node = null


func mark_drop(item: Node) -> void:
	if is_instance_valid(_drop_marked) and _drop_marked != item:
		_drop_marked.call("clear_drop_mark")
	_drop_marked = item


func is_event_selected(p: Array) -> bool:
	return _sel_what == "event" and _sel_path == p


func is_instruction_selected(p: Array, kind: String, index: int) -> bool:
	return _sel_what == "instruction" and _sel_path == p \
			and _sel_kind == kind and _sel_index == index


## Короткая подпись события — для подсказки при перетаскивании.
func event_summary(p: Array) -> String:
	var e: Variant = doc.event_at(p) if doc != null else null
	if e == null:
		return GdeI18n.t("Событие")
	var d: Dictionary = e
	var title := GdeText.event_title(d)
	if not title.is_empty():
		return title
	var conds: Array = d.get("conditions", [])
	var acts: Array = d.get("actions", [])
	if not conds.is_empty():
		var first: Dictionary = conds[0]
		var def: Variant = instruction_def("conditions", str(first.get("id", "")))
		if def != null:
			return GdeText.with_labels(def as Dictionary)
	return GdeI18n.t("Событие: условий %d, действий %d") % [conds.size(), acts.size()]


# --------------------------------------------------------- правки из строк ---

func invert_instruction(p: Array, kind: String, index: int) -> void:
	if doc != null:
		doc.toggle_instruction_inverted(p, kind, index)


func remove_instruction(p: Array, kind: String, index: int) -> void:
	if doc == null:
		return
	doc.remove_instruction(p, kind, index)
	if is_instruction_selected(p, kind, index):
		_sel_what = ""


func duplicate_event(p: Array) -> void:
	if doc != null:
		doc.duplicate_event(p)


## «Любое из условий»: условия события соединяются через «или».
func toggle_event_any(p: Array) -> void:
	if doc == null:
		return
	var e: Variant = doc.event_at(p)
	if e == null:
		return
	var on := not bool((e as Dictionary).get("any", false))
	if on:
		doc.set_event_field(p, "any", true)
	else:
		doc.erase_event_field(p, "any")


## Локальные переменные события — строками «имя = значение».
func edit_event_locals(p: Array) -> void:
	if doc == null or doc.event_at(p) == null:
		return
	var e: Dictionary = doc.event_at(p)
	var dlg := ConfirmationDialog.new()
	dlg.title = GdeI18n.t("Локальные переменные события")
	var box := VBoxContainer.new()
	var hint := Label.new()
	hint.text = GdeI18n.t("По одной на строке: имя = значение. Текст — в кавычках.\nЖивут только в этом событии и его подсобытиях и обнуляются при каждом его запуске.")
	hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(hint)
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(420, 160)
	te.text = locals_to_text(e.get("locals", {}))
	te.placeholder_text = "count = 0\nname = \"Bob\""
	box.add_child(te)
	var err := Label.new()
	err.add_theme_color_override("font_color", Color(0.85, 0.55, 0.55))
	box.add_child(err)
	dlg.add_child(box)
	dlg.get_ok_button().text = GdeI18n.t("Сохранить")
	# Окно не закрывается при ошибке: иначе набранное пропало бы.
	dlg.get_ok_button().pressed.connect(func():
		var parsed := text_to_locals(te.text)
		if str(parsed["error"]) != "":
			err.text = parsed["error"]
			dlg.show.call_deferred()
			return
		set_event_locals(p, parsed["locals"])
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


func set_event_locals(p: Array, locals: Dictionary) -> void:
	if doc == null:
		return
	if locals.is_empty():
		doc.erase_event_field(p, "locals")
	else:
		doc.set_event_field(p, "locals", locals)


static func locals_to_text(locals: Variant) -> String:
	var lines: Array[String] = []
	if locals is Dictionary:
		for k: Variant in (locals as Dictionary):
			var v: Variant = (locals as Dictionary)[k]
			lines.append("%s = %s" % [k, JSON.stringify(v) if v is String else str(GdeSheetDocument._normalize(v))])
	return "\n".join(lines)


## {"locals": Dictionary, "error": ""}
static func text_to_locals(text: String) -> Dictionary:
	var out: Dictionary = {}
	var n := 0
	for raw: String in text.split("\n"):
		n += 1
		var line := raw.strip_edges()
		if line.is_empty():
			continue
		var eq := line.find("=")
		if eq < 0:
			return {"locals": {}, "error": GdeI18n.t("строка %d: нужно «имя = значение»") % n}
		var name := line.substr(0, eq).strip_edges()
		var val := line.substr(eq + 1).strip_edges()
		if not name.is_valid_ascii_identifier():
			return {"locals": {}, "error": GdeI18n.t("строка %d: имя «%s» — латинские буквы, цифры и _, не с цифры") % [n, name]}
		if val.length() >= 2 and val.begins_with("\"") and val.ends_with("\""):
			out[name] = val.substr(1, val.length() - 2)
		elif val.is_valid_float():
			out[name] = GdeSheetDocument._normalize(val.to_float())
		elif val.is_empty():
			out[name] = 0
		else:
			return {"locals": {}, "error": GdeI18n.t("строка %d: «%s» — не число; текст пишите в кавычках") % [n, val]}
	return {"locals": out, "error": ""}


func toggle_event_disabled(p: Array) -> void:
	if doc != null:
		doc.toggle_disabled(p)


func remove_event(p: Array) -> void:
	if doc == null:
		return
	doc.remove_event(p)
	if _sel_what == "event" and _sel_path == p:
		_sel_what = ""


# ----------------------------------------------------------- перетаскивание ---

## Строку бросили в колонку. Ctrl зажат — копия, иначе перенос.
func drop_instruction(data: Dictionary, to_path: Array, kind: String, to_index: int) -> void:
	if doc == null:
		return
	var from_path: Array = data.get("path", [])
	var from_index := int(data.get("index", -1))
	var copy := Input.is_key_pressed(KEY_CTRL)

	if not copy and from_path == to_path:
		doc.move_instruction(from_path, kind, from_index, to_index)
		_sel_what = ""
		return
	var payload: Dictionary = (data.get("data", {}) as Dictionary).duplicate(true)
	if not copy:
		doc.remove_instruction(from_path, kind, from_index)
		# Изъятие строки выше сдвигает цель на единицу вверх.
		if from_path == to_path and from_index < to_index:
			to_index -= 1
	doc.insert_instruction(to_path, kind, to_index, payload)
	_sel_what = ""


## Событие бросили на другую карточку.
func drop_event(data: Dictionary, on_path: Array, where: int) -> void:
	if doc == null:
		return
	var from: Array = data.get("path", [])
	if from.is_empty() or from == on_path:
		return
	var parent := on_path.slice(0, on_path.size() - 1)
	var idx: int = on_path[on_path.size() - 1]
	match where:
		GdeEventCard.Where.BEFORE:
			doc.move_event(from, parent, idx)
		GdeEventCard.Where.AFTER:
			doc.move_event(from, parent, idx + 1)
		GdeEventCard.Where.INSIDE:
			doc.move_event(from, on_path, 9999)
	_sel_what = ""


## Сцену принесли из файловой системы — добавляем объект листа.
func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return doc != null and not GdeSceneDrop.scenes_in(data).is_empty()


func _drop_data(_at: Vector2, data: Variant) -> void:
	var added: Array[String] = []
	for p: String in GdeSceneDrop.scenes_in(data):
		var nm := GdeBehaviorInstaller.pascal(p.get_file().get_basename())
		var base := nm
		var i := 2
		while doc.object_names().has(nm):
			nm = "%s%d" % [base, i]
			i += 1
		doc.add_object(nm, p)
		added.append(nm)
	if added.is_empty():
		return
	save_sheet()
	_set_status(GdeI18n.t("Добавлено в лист: %s") % ", ".join(added), false)


# --------------------------------------------------------- буфер обмена ---

func copy_instruction(p: Array, kind: String, index: int) -> void:
	var list := doc.instructions_of(p, kind) if doc != null else []
	if index < 0 or index >= list.size():
		return
	_clip_instruction = (list[index] as Dictionary).duplicate(true)
	_clip_inst_kind = kind
	_set_status(GdeI18n.t("Скопировано — «Вставить» появится у «+ %s»")
			% (GdeI18n.t("Условие") if kind == "conditions" else GdeI18n.t("Действие")), false)


## Что лежит в буфере: "conditions", "actions" или "" — для кнопки «Вставить».
func clipboard_kind() -> String:
	return "" if _clip_instruction.is_empty() else _clip_inst_kind


## Фраза скопированной строки — подсказка на кнопке «Вставить».
func clipboard_text() -> String:
	if _clip_instruction.is_empty():
		return ""
	var def: Variant = instruction_def(_clip_inst_kind, str(_clip_instruction.get("id", "")))
	if def == null:
		return str(_clip_instruction.get("id", ""))
	var params: Array = _clip_instruction.get("params", [])
	var defs: Array = (def as Dictionary).get("params", [])
	var s := str((def as Dictionary).get("sentence", ""))
	for i in range(defs.size()):
		var v := str(params[i]) if i < params.size() else ""
		s = s.replace("_PARAM%d_" % i, v if not v.is_empty() else "‹%s›" % str((defs[i] as Dictionary).get("label", "…")))
	if _clip_instruction.get("inverted", false):
		s = GdeI18n.t("НЕ ") + s
	return s


## Вставить строку из буфера в конец колонки события. Буфер не очищается —
## одно и то же можно вставить в несколько событий подряд.
func paste_instruction_into(p: Array, kind: String) -> void:
	if doc == null or clipboard_kind() != kind:
		return
	doc.insert_instruction(p, kind, 9999, _clip_instruction.duplicate(true))
	var idx := doc.instructions_of(p, kind).size() - 1
	select_instruction(p, kind, idx)
	_set_status(GdeI18n.t("Вставлено"), false)


func cut_instruction(p: Array, kind: String, index: int) -> void:
	copy_instruction(p, kind, index)
	remove_instruction(p, kind, index)


func copy_event(p: Array) -> void:
	var e: Variant = doc.event_at(p) if doc != null else null
	if e == null:
		return
	_clip_event = (e as Dictionary).duplicate(true)
	_set_status(GdeI18n.t("Событие скопировано. Ctrl+V вставит его после выделенного"), false)


func paste() -> void:
	if doc == null:
		return
	# Выделена строка или событие — вставляем инструкцию туда же.
	if not _clip_instruction.is_empty() and _sel_what != "":
		var target: Array = _sel_path
		var kind := _clip_inst_kind
		var at := 9999
		if _sel_what == "instruction" and _sel_kind == kind:
			at = _sel_index + 1
		doc.insert_instruction(target, kind, at, _clip_instruction.duplicate(true))
		_set_status(GdeI18n.t("Вставлено"), false)
		return
	if not _clip_event.is_empty():
		var parent: Array = []
		var idx := 9999
		if _sel_what != "" and not _sel_path.is_empty():
			parent = _sel_path.slice(0, _sel_path.size() - 1)
			idx = int(_sel_path[_sel_path.size() - 1]) + 1
		doc.insert_event(parent, idx, _clip_event.duplicate(true))
		_set_status(GdeI18n.t("Событие вставлено"), false)
		return
	_set_status(GdeI18n.t("Буфер пуст — сначала Ctrl+C"), true)


# ------------------------------------------------------------ горячие клавиши ---

## Клавиши работают, только пока вкладка событий открыта и фокус не в поле
## ввода: иначе Delete внутри LineEdit удалял бы событие целиком.
func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or doc == null:
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit or focus is SpinBox:
		return

	var ctrl := k.ctrl_pressed or k.meta_pressed
	if ctrl:
		match k.keycode:
			KEY_S:
				accept_event()
				save_sheet()
			KEY_B:
				accept_event()
				save_and_build()
			KEY_Z:
				accept_event()
				if k.shift_pressed:
					doc.redo()
				else:
					doc.undo()
			KEY_Y:
				accept_event()
				doc.redo()
			KEY_C:
				accept_event()
				_copy_selection()
			KEY_X:
				accept_event()
				_cut_selection()
			KEY_V:
				accept_event()
				paste()
			KEY_D:
				accept_event()
				if _sel_what == "event":
					duplicate_event(_sel_path)
			KEY_N:
				accept_event()
				doc.add_event([], 9999, "standard")
		return

	if k.alt_pressed and (k.keycode == KEY_UP or k.keycode == KEY_DOWN):
		accept_event()
		_move_selection(-1 if k.keycode == KEY_UP else 1)
		return

	match k.keycode:
		KEY_DELETE:
			accept_event()
			_delete_selection()
		KEY_ENTER, KEY_KP_ENTER:
			if _sel_what == "instruction":
				accept_event()
				edit_instruction(_sel_path, _sel_kind, _sel_index)
		KEY_ESCAPE:
			if _sel_what != "":
				accept_event()
				_sel_what = ""
				_refresh_selection()


## Сдвинуть выделенную строку или событие на одну позицию, не теряя выделения.
func _move_selection(dir: int) -> void:
	match _sel_what:
		"instruction":
			var list := doc.instructions_of(_sel_path, _sel_kind)
			var to := _sel_index + dir
			if to < 0 or to >= list.size():
				return
			doc.move_instruction(_sel_path, _sel_kind, _sel_index, to if dir < 0 else to + 1)
			_sel_index = to
			_refresh_selection()
		"event":
			var parent := _sel_path.slice(0, _sel_path.size() - 1)
			var idx: int = _sel_path[_sel_path.size() - 1]
			var siblings := doc.container_of(_sel_path)
			var to2 := idx + dir
			if to2 < 0 or to2 >= siblings.size():
				return
			var np := doc.move_event(_sel_path, parent, to2 if dir < 0 else to2 + 1)
			if not np.is_empty():
				_sel_path = np
			_refresh_selection()


func _copy_selection() -> void:
	match _sel_what:
		"instruction": copy_instruction(_sel_path, _sel_kind, _sel_index)
		"event": copy_event(_sel_path)


func _cut_selection() -> void:
	match _sel_what:
		"instruction": cut_instruction(_sel_path, _sel_kind, _sel_index)
		"event":
			copy_event(_sel_path)
			remove_event(_sel_path)


func _delete_selection() -> void:
	match _sel_what:
		"instruction": remove_instruction(_sel_path, _sel_kind, _sel_index)
		"event": remove_event(_sel_path)
		_: _set_status(GdeI18n.t("Сначала выберите условие, действие или событие"), true)


# ------------------------------------------------------------------- меню ---

func instruction_menu(p: Array, kind: String, index: int, at: Vector2) -> void:
	_menu_path = p
	_menu_kind = kind
	_menu_index = index
	_inst_menu.clear()
	_inst_menu.add_icon_item(GdeIcons.get_icon("edit"), GdeI18n.t("Редактировать…"), 0)
	if kind == "conditions":
		_inst_menu.add_icon_item(GdeIcons.get_icon("invert"), GdeI18n.t("Инвертировать (НЕ)"), 1)
	var off: bool = (doc.instructions_of(p, kind)[index] as Dictionary).get("disabled", false) \
			if index < doc.instructions_of(p, kind).size() else false
	_inst_menu.add_icon_item(GdeIcons.get_icon("disabled"), GdeI18n.t("Включить") if off else GdeI18n.t("Выключить"), 8)
	_inst_menu.add_separator()
	_inst_menu.add_icon_item(GdeIcons.get_icon("up"), GdeI18n.t("Выше	Alt+↑"), 2)
	_inst_menu.add_icon_item(GdeIcons.get_icon("down"), GdeI18n.t("Ниже	Alt+↓"), 3)
	_inst_menu.add_separator()
	_inst_menu.add_icon_item(GdeIcons.get_icon("copy"), GdeI18n.t("Копировать	Ctrl+C"), 5)
	_inst_menu.add_icon_item(GdeIcons.get_icon("copy"), GdeI18n.t("Вырезать	Ctrl+X"), 6)
	_inst_menu.add_icon_item(GdeIcons.get_icon("plus"), GdeI18n.t("Вставить	Ctrl+V"), 7)
	_inst_menu.add_separator()
	_inst_menu.add_icon_item(GdeIcons.get_icon("trash"), GdeI18n.t("Удалить	Delete"), 4)
	_inst_menu.position = Vector2i(at)
	_inst_menu.reset_size()
	_inst_menu.popup()


func _on_inst_menu(id: int) -> void:
	match id:
		0: edit_instruction(_menu_path, _menu_kind, _menu_index)
		1: invert_instruction(_menu_path, _menu_kind, _menu_index)
		2: doc.move_instruction(_menu_path, _menu_kind, _menu_index, _menu_index - 1)
		3: doc.move_instruction(_menu_path, _menu_kind, _menu_index, _menu_index + 2)
		4: remove_instruction(_menu_path, _menu_kind, _menu_index)
		5: copy_instruction(_menu_path, _menu_kind, _menu_index)
		6: cut_instruction(_menu_path, _menu_kind, _menu_index)
		7: paste()
		8: doc.toggle_instruction_disabled(_menu_path, _menu_kind, _menu_index)


func event_menu(p: Array, at: Vector2) -> void:
	_menu_path = p
	var e: Variant = doc.event_at(p)
	var disabled: bool = (e as Dictionary).get("disabled", false) if e != null else false
	_event_menu.clear()
	_event_menu.add_icon_item(GdeIcons.get_icon("plus"), GdeI18n.t("Событие после"), 0)
	_event_menu.add_icon_item(GdeIcons.get_icon("indent"), GdeI18n.t("Подсобытие"), 1)
	_event_menu.add_icon_item(GdeIcons.get_icon("comment"), GdeI18n.t("Комментарий после"), 2)
	_event_menu.add_separator()
	if e != null and str((e as Dictionary).get("type", "standard")) in ANY_TYPES:
		_event_menu.add_check_item(GdeI18n.t("Любое из условий (ИЛИ)"), 12)
		_event_menu.set_item_checked(_event_menu.item_count - 1, bool((e as Dictionary).get("any", false)))
		_event_menu.set_item_tooltip(_event_menu.item_count - 1,
				GdeI18n.t("Событие сработает, если выполнено хотя бы одно условие, а не все сразу"))
		_event_menu.add_separator()
	if e != null and str((e as Dictionary).get("type", "standard")) in LOCALS_TYPES:
		_event_menu.add_icon_item(GdeIcons.get_icon("variable"), GdeI18n.t("Локальные переменные…"), 13)
		_event_menu.add_separator()
	_event_menu.add_icon_item(GdeIcons.get_icon("up"), GdeI18n.t("Выше	Alt+↑"), 3)
	_event_menu.add_icon_item(GdeIcons.get_icon("down"), GdeI18n.t("Ниже	Alt+↓"), 4)
	_event_menu.add_icon_item(GdeIcons.get_icon("indent"), GdeI18n.t("Вложить в предыдущее"), 5)
	_event_menu.add_icon_item(GdeIcons.get_icon("outdent"), GdeI18n.t("На уровень выше"), 6)
	_event_menu.add_separator()
	_event_menu.add_icon_item(GdeIcons.get_icon("copy"), GdeI18n.t("Дублировать	Ctrl+D"), 7)
	_event_menu.add_icon_item(GdeIcons.get_icon("copy"), GdeI18n.t("Копировать	Ctrl+C"), 10)
	_event_menu.add_icon_item(GdeIcons.get_icon("plus"), GdeI18n.t("Вставить	Ctrl+V"), 11)
	_event_menu.add_icon_item(GdeIcons.get_icon("disabled"),
			GdeI18n.t("Включить") if disabled else GdeI18n.t("Выключить"), 8)
	_event_menu.add_icon_item(GdeIcons.get_icon("trash"), GdeI18n.t("Удалить	Delete"), 9)
	_event_menu.position = Vector2i(at)
	_event_menu.reset_size()
	_event_menu.popup()


func _on_event_menu(id: int) -> void:
	var p := _menu_path
	if p.is_empty():
		return
	var parent := p.slice(0, p.size() - 1)
	var idx: int = p[p.size() - 1]
	match id:
		0: doc.add_event(parent, idx + 1, "standard")
		1: doc.add_event(p, 9999, "standard")
		2: doc.add_event(parent, idx + 1, "comment")
		3: doc.move_event(p, parent, idx - 1)
		4: doc.move_event(p, parent, idx + 2)
		5:
			if idx > 0:
				doc.move_event(p, parent + [idx - 1], 9999)
			else:
				_set_status(GdeI18n.t("Некуда вложить: событие первое в списке"), true)
		6:
			if p.size() > 1:
				doc.move_event(p, p.slice(0, p.size() - 2), p[p.size() - 2] + 1)
			else:
				_set_status(GdeI18n.t("Событие уже на верхнем уровне"), true)
		7: duplicate_event(p)
		8: toggle_event_disabled(p)
		9: remove_event(p)
		10: copy_event(p)
		11: paste()
		12: toggle_event_any(p)
		13: edit_event_locals(p)


func _on_add_root_event(id: int) -> void:
	if doc == null:
		return
	var types := ["standard", "comment", "foreach", "repeat", "while", "group", "include"]
	if id < 0 or id >= types.size():
		return
	doc.add_event([], 9999, types[id])
