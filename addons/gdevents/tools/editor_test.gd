## Безголовый тест редактора:
##   godot --headless --script res://addons/gdevents/tools/editor_test.gd
##
## Проверяет модель документа и реальную сборку Control-дерева панели.
## Графики нет, но все конструкторы, подписки и обращения к API отрабатывают
## по-настоящему — опечатки и null-обращения всплывают здесь, а не у пользователя.
extends SceneTree

## Панель ищет листы по всему проекту и открывает первый попавшийся.
## Опираться на листы пользователя нельзя: он их создаёт, чистит и правит
## прямо сейчас — тест то проходил, то падал на пустом листе. Поэтому тест
## кладёт рядом свой лист, работает с ним и убирает за собой.
const TEST_SHEET := "res://__gdevents_selftest.gdes.json"

var _fails: int = 0
var _checks: int = 0
var _step: int = 0
var _panel: GdeEventSheetPanel


func _initialize() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	print("—— модель документа ——")
	_test_document()
	print("—— буфер и вставка ——")
	_test_clipboard()
	print("—— поиск поведений в сцене ——")
	_test_installer()
	print("—— понятные названия ——")
	_test_labels()
	print("—— ошибки прямо в листе ——")
	_test_live_errors()
	print("—— сборка интерфейса ——")
	_make_test_sheet()
	_panel = GdeEventSheetPanel.new()
	# Тест гоняет панель на настоящих файлах — записывать что-либо
	# в листы пользователя он не имеет права.
	_panel.autosave_enabled = false
	root.add_child(_panel)


## Лист с заведомо известным содержимым: два объекта, два события,
## условие и действие. Все проверки ниже считают именно его.
func _make_test_sheet() -> void:
	var doc := GdeSheetDocument.create_empty("тест")
	doc.path = TEST_SHEET
	doc.add_object("Player", "res://addons/gdevents/tests/bullet.tscn")
	doc.add_object("Enemy", "res://addons/gdevents/tests/enemy.tscn")
	doc.add_event([], 0, "standard")
	doc.add_instruction([0], "conditions", "key.pressed", ["Space"])
	doc.add_instruction([0], "actions", "object.x", ["Player", "+", "5"])
	doc.add_event([], 1, "standard")
	doc.add_instruction([1], "conditions", "object.collision", ["Player", "Enemy"])
	doc.add_instruction([1], "conditions", "system.at_start", [])
	doc.save()


func _drop_test_sheet() -> void:
	for p: String in [TEST_SHEET, TEST_SHEET.trim_suffix(GdeBuild.SHEET_SUFFIX) + ".gd"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _process(_delta: float) -> bool:
	_step += 1
	if _step == 2:
		_panel.refresh_sheet_list()
		_panel.open_sheet(TEST_SHEET)
	if _step == 4:
		_test_panel()
	if _step == 6:
		# Каркас проверяем отдельным шагом: установщик асинхронный,
		# а в _initialize ждать кадра ещё некого.
		print("—— каркас сцены ——")
		_run_scaffold()
	if _step == 9:
		print("—— проверка сцен ——")
		_run_scene_check()
	if _step == 12:
		print("—— тумблеры условий и действий ——")
		_test_toggles()
	if _step >= 18:
		_drop_test_sheet()
		_report()
		return true
	return false


func _run_scaffold() -> void:
	await _test_scaffold()


# ------------------------------------------------------------------ модель ---

func _test_document() -> void:
	var doc := GdeSheetDocument.create_empty("Тест")
	doc.add_object("Player", "res://demo/demo_player.tscn")
	doc.add_object("Enemy", "res://demo/enemy.tscn")
	_eq(doc.object_names().size(), 2, "два объекта зарегистрированы")

	var a := doc.add_event([], 0, "standard")
	var b := doc.add_event([], 1, "standard")
	var c := doc.add_event([], 2, "comment")
	_eq((doc.data["events"] as Array).size(), 3, "три события в корне")
	_eq(a, [0], "путь первого события")

	doc.add_instruction(b, "conditions", "key.pressed", ["Space"])
	doc.add_instruction(b, "actions", "object.x", ["Player", "+", "5"])
	_eq(doc.instructions_of(b, "conditions").size(), 1, "условие добавлено")
	_eq(doc.instructions_of(b, "actions").size(), 1, "действие добавлено")

	doc.set_instruction_params(b, "actions", 0, ["Enemy", "-", "10"])
	_eq((doc.instructions_of(b, "actions")[0] as Dictionary)["params"], ["Enemy", "-", "10"],
			"параметры перезаписаны")

	doc.toggle_instruction_inverted(b, "conditions", 0)
	_eq((doc.instructions_of(b, "conditions")[0] as Dictionary).get("inverted", false), true,
			"инверсия включилась")

	# Вложить второе событие в первое.
	var moved := doc.move_event(b, [0], 9999)
	_eq(moved, [0, 0], "событие стало подсобытием")
	_eq((doc.data["events"] as Array).size(), 2, "в корне осталось два")
	_eq(doc.instructions_of(moved, "conditions").size(), 1, "содержимое переехало вместе с ним")

	# Внутрь самого себя — запрещено.
	_eq(doc.move_event([0], [0, 0], 0), [], "перенос внутрь себя отклонён")

	# Поднять обратно на верхний уровень.
	var raised := doc.move_event([0, 0], [], 1)
	_eq(raised, [1], "событие вернулось наверх")
	_eq((doc.data["events"] as Array).size(), 3, "снова три в корне")

	var before := JSON.stringify(doc.data, "", false)
	doc.remove_event([2])
	_eq((doc.data["events"] as Array).size(), 2, "событие удалено")
	doc.undo()
	_eq(JSON.stringify(doc.data, "", false), before, "отмена восстановила состояние")
	doc.redo()
	_eq((doc.data["events"] as Array).size(), 2, "повтор снова удалил")

	doc.toggle_disabled([0])
	_eq((doc.event_at([0]) as Dictionary).get("disabled", false), true, "событие выключено")

	_eq(GdeSheetDocument.is_inside([0, 1, 2], [0, 1]), true, "is_inside вложенного")
	_eq(GdeSheetDocument.is_inside([1], [0]), false, "is_inside чужого")
	_ok(c.size() == 1, "комментарий создан")


# ----------------------------------------------------------------- панель ---

func _test_panel() -> void:
	_ok(_panel.registry != null, "реестр загружен")
	_ok(_panel.registry.behaviors.has("Shoot"), "поведение Shoot видно редактору")
	_ok(_panel.doc != null, "лист открылся автоматически")
	if _panel.doc == null:
		return

	_ok(_panel.object_names().size() > 0, "у листа есть объекты")
	_ok(_panel.instruction_def("conditions", "key.pressed") != null, "условие находится")
	_ok(_panel.instruction_def("actions", "Shoot::fire") != null, "действие поведения находится")

	var rows := _count_rows(_panel)
	var events: int = (_panel.doc.data.get("events", []) as Array).size()
	_ok(rows >= events and events > 0, "строки событий построены (%d на %d событий)" % [rows, events])
	_ok(_count_items(_panel) > 0, "строки условий/действий построены")

	# Мутация через панель должна пересобрать дерево без ошибок.
	_panel.doc.add_event([], 9999, "foreach")
	_ok(_count_rows(_panel) > rows, "после добавления события дерево перестроилось")
	_panel.doc.undo()

	# «Любое из условий»: ключ появляется, подпись видна, выключение убирает ключ.
	_panel.toggle_event_any([0])
	var ev0: Dictionary = _panel.doc.event_at([0])
	_ok(ev0.get("any", false) == true, "«Любое из условий» включается из меню события")
	_ok(_find_label(_panel, GdeI18n.t("Любое из условий (ИЛИ)")), "на событии видна подпись «Любое из условий»")
	_panel.toggle_event_any([0])
	_ok(not (_panel.doc.event_at([0]) as Dictionary).has("any"), "выключение убирает ключ из листа")
	_panel.doc.undo()
	_panel.doc.undo()

	# Локальные переменные: разбор строк, запись в событие, подпись на карточке.
	var parsed: Dictionary = GdeEventSheetPanel.text_to_locals("count = 0\nname = \"Bob\"\n\nspeed = 2.5")
	_eq(parsed["error"], "", "локальные: строки разбираются")
	_eq(str(parsed["locals"]), str({"count": 0, "name": "Bob", "speed": 2.5}), "локальные: числа и текст")
	_ok(str(GdeEventSheetPanel.text_to_locals("2x = 1")["error"]) != "", "локальные: плохое имя — ошибка")
	_ok(str(GdeEventSheetPanel.text_to_locals("a = bob")["error"]) != "", "локальные: текст без кавычек — ошибка")
	_eq(GdeEventSheetPanel.locals_to_text(parsed["locals"]), "count = 0\nname = \"Bob\"\nspeed = 2.5", "локальные: обратно в строки")
	_panel.set_event_locals([0], parsed["locals"])
	_ok(_find_label_prefix(_panel, GdeI18n.t("Локальные: %s") % ""), "локальные: подпись на событии")
	_panel.set_event_locals([0], {})
	_ok(not (_panel.doc.event_at([0]) as Dictionary).has("locals"), "локальные: пустой список убирает ключ")
	_panel.doc.undo()
	_panel.doc.undo()

	# Подключение листа: карточка с выбором листа, без колонок условий.
	var before := _count_items(_panel)
	_panel.doc.add_event([], 9999, "include")
	var last: int = (_panel.doc.data["events"] as Array).size() - 1
	_ok(str((_panel.doc.event_at([last]) as Dictionary).get("sheet", "?")) == "", "«Подключить лист» создаётся пустым")
	_ok(_find_label(_panel, GdeI18n.t("Подключить лист")), "на карточке подключения — подпись и выбор листа")
	_ok(_count_items(_panel) == before, "у подключения нет своих строк условий и действий")
	_panel.doc.undo()

	_test_search_and_fold()
	_test_function_card()

	# Фразы рендерятся и с подписями, и со значениями.
	var def: Dictionary = _panel.instruction_def("actions", "object.x")
	_ok(GdeText.with_labels(def).contains("‹"), "фраза с подписями параметров")
	var rendered := GdeText.with_values(def, {"id": "object.x", "params": ["Player", "+", "5"]}, Color.WHITE)
	_ok(rendered.contains("Player") and rendered.contains("[color="), "фраза со значениями и подсветкой")
	_ok(GdeText.with_values(null, {"id": "чушь"}, Color.WHITE).contains("неизвестная"),
			"исчезнувшая инструкция помечена, а не уронила редактор")

	_test_roundtrip()
	_test_unsaved_survives_refresh()


## Регрессия: возврат на вкладку вызывает refresh_sheet_list(), и раньше
## она безусловно перечитывала лист с диска — только что добавленный
## объект пропадал без всякого предупреждения.
func _test_unsaved_survives_refresh() -> void:
	if _panel.doc == null:
		return
	var before := _panel.object_names().size()
	_panel.doc.add_object("ТестОбъект", "res://demo/enemy.tscn")
	_eq(_panel.object_names().size(), before + 1, "объект добавлен в память")
	_ok(_panel.doc.is_dirty(), "лист помечен как изменённый")

	_panel.refresh_sheet_list()
	_eq(_panel.object_names().size(), before + 1,
			"несохранённый объект пережил обновление списка листов")
	_ok(_panel.object_names().has("ТестОбъект"), "именно тот же объект на месте")

	# Вернём лист к состоянию на диске, чтобы тест ничего не портил.
	_panel.doc.undo()


# ------------------------------------------------------- буфер обмена ---

func _test_clipboard() -> void:
	var doc := GdeSheetDocument.create_empty("Буфер")
	doc.add_event([], 0, "standard")
	doc.add_event([], 1, "standard")
	doc.add_instruction([0], "actions", "system.quit", [])

	var copied: Dictionary = (doc.instructions_of([0], "actions")[0] as Dictionary).duplicate(true)
	doc.insert_instruction([1], "actions", 0, copied)
	_eq(doc.instructions_of([1], "actions").size(), 1, "строка вставлена в другое событие")
	_eq(doc.instructions_of([0], "actions").size(), 1, "в исходном событии осталась своя")

	# Вставлять надо копию: общая ссылка связала бы две строки в одну.
	(doc.instructions_of([1], "actions")[0] as Dictionary)["params"] = ["чужое"]
	_eq((doc.instructions_of([0], "actions")[0] as Dictionary).get("params", []).size(), 0,
			"правка копии не тронула оригинал")

	var e: Dictionary = (doc.event_at([0]) as Dictionary).duplicate(true)
	doc.insert_event([], 9999, e)
	_eq((doc.data["events"] as Array).size(), 3, "событие вставлено из буфера")
	doc.undo()
	_eq((doc.data["events"] as Array).size(), 2, "вставку события можно отменить")


# --------------------------------------------------- поведения в сцене ---

## Регрессия на главную жалобу: в живой сцене поведение лежит не на
## корне, а внутри — и раньше редактор его просто не видел.
func _test_installer() -> void:
	var scene := "res://addons/gdevents/tests/bullet.tscn"
	var found := GdeBehaviorInstaller.scan(scene)
	_eq(found.size(), 1, "поведение найдено внутри поддерева, а не только на корне")
	if not found.is_empty():
		_eq(str((found[0] as Dictionary)["name"]), "LinearMove", "имя поведения распознано")
		_ok(str((found[0] as Dictionary)["node"]).contains("Body"),
				"видно, на каком именно узле оно висит")
	_ok(GdeBehaviorInstaller.installed(scene).has("LinearMove"),
			"короткий список имён тоже работает")


## То, чего ждал пользователь: пустая сцена плюс поведение равно готовый
## каркас — тело, форма столкновения и спрайт появляются сами.
func _test_scaffold() -> void:
	var path := "user://gde_scaffold_test.tscn"
	var root := Node2D.new()
	root.name = "Пустая"
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, path)
	root.free()
	GdeBehaviorInstaller.invalidate()

	var reg := GdeRegistry.load_default()
	var b: Dictionary = reg.behaviors["Platformer"]
	var res: Dictionary = await GdeBehaviorInstaller.add(path, "Platformer",
			str(b["path"]), {"target": b["target"], "needs": b["needs"]})
	_eq(str(res.get("error", "")), "", "поведение встало в пустую сцену")
	_ok((res.get("created", []) as Array).size() >= 3,
			"каркас создан: %s" % ", ".join(res.get("created", [])))

	GdeBehaviorInstaller.invalidate()
	var ps: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var r2 := ps.instantiate()
	_ok(_has_class(r2, "CharacterBody2D"), "тело появилось")
	_ok(_has_class(r2, "CollisionShape2D"), "форма столкновения появилась")
	_ok(_has_class(r2, "AnimatedSprite2D"), "спрайт появился")
	r2.free()

	_ok(GdeBehaviorInstaller.installed(path).has("Platformer"),
			"поставленное поведение сразу видно в списке")

	var again: Dictionary = await GdeBehaviorInstaller.add(path, "Platformer", str(b["path"]), {})
	_ok(not str(again.get("error", "")).is_empty(), "второй раз то же поведение не ставится")

	var err: String = await GdeBehaviorInstaller.remove(path, "Platformer")
	_eq(err, "", "поведение снимается")
	_eq(GdeBehaviorInstaller.installed(path).size(), 0, "после снятия список пуст")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _has_class(n: Node, cls: String) -> bool:
	if n.is_class(cls):
		return true
	for c: Node in n.get_children():
		if _has_class(c, cls):
			return true
	return false


# ------------------------------------------------------------ тумблеры ---

func _test_toggles() -> void:
	var pk: GdeInstructionPicker = _panel._picker
	var ed: GdeParamEditor = pk._editor

	# ---- добавление: щелчок сразу показывает настройки справа, в том же окне
	var before := _panel.doc.instructions_of([1], "conditions").size()
	_panel.add_instruction([1], "conditions")
	_ok(pk.visible, "окно выбора открылось")
	_ok(not ed.has_instruction() and pk.get_ok_button().disabled,
			"пока ничего не выбрано — справа подсказка, «Добавить» недоступно")
	pk._select_id("object.x")
	_ok(ed.has_instruction() and ed.instruction_id() == "object.x",
			"щелчок по условию показал его настройки в том же окне")
	_eq(str(ed.current_values()[0]), "Player", "объект подставлен из списка слева")
	_eq(_panel.doc.instructions_of([1], "conditions").size(), before,
			"пока не нажато «Добавить», в листе ничего не появилось")

	# ---- смена объекта слева: условие остаётся выбранным, объект меняется
	(ed._editors[2] as LineEdit).text = "150"
	pk._objects.select(2)
	pk._on_object_selected(2)
	_eq(ed.instruction_id(), "object.x", "смена объекта не сбросила выбранное условие")
	_eq(str(ed.current_values()[0]), "Enemy", "объект в параметрах сменился на выбранный")
	_eq(str(ed.current_values()[2]), "150", "введённое значение сохранилось")

	ed._invert.button_pressed = true
	_ok(ed._preview.text.contains("НЕ"), "перевёрнутое условие видно во фразе сразу")
	pk._confirm()
	var conds: Array = _panel.doc.instructions_of([1], "conditions")
	_eq(conds.size(), before + 1, "«Добавить» добавило строку")
	var added: Dictionary = conds[conds.size() - 1]
	_ok(str(added["id"]) == "object.x" and str(added["params"][0]) == "Enemy"
			and bool(added.get("inverted", false)),
			"строка добавлена со всеми параметрами и «НЕ»")
	_ok(not pk.visible, "окно закрылось")

	# ---- «Отмена» не оставляет следа
	_panel.add_instruction([1], "conditions")
	pk._select_id("object.visible")
	pk.hide()
	_eq(_panel.doc.instructions_of([1], "conditions").size(), before + 1,
			"«Отмена» ничего не добавила")

	# ---- правка: то же окно, условие выбрано, поля заполнены
	var idx := before
	_panel.edit_instruction([1], "conditions", idx)
	_ok(pk.visible and ed.instruction_id() == "object.x", "правка открыла то же окно с этим условием")
	_eq(str(pk._current_object), "Enemy", "слева выбран объект строки")
	_eq(str(ed.current_values()[2]), "150", "поля заполнены значениями строки")
	_ok(ed._invert.button_pressed, "тумблер «НЕ» показан включённым")
	ed._invert.button_pressed = false
	ed._disable.button_pressed = true
	pk._confirm()
	var c: Dictionary = _panel.doc.instructions_of([1], "conditions")[idx]
	_ok(not c.has("inverted") and bool(c.get("disabled", false)),
			"«НЕ» снят без следа в JSON, «Выключено» записано")
	_panel.doc.undo()
	c = _panel.doc.instructions_of([1], "conditions")[idx]
	_ok(bool(c.get("inverted", false)) and not c.has("disabled"),
			"параметры и тумблеры отменяются одним шагом")

	# ---- при правке можно сменить само условие на другое
	_panel.edit_instruction([1], "conditions", idx)
	pk._select_id("object.visible")
	pk._confirm()
	c = _panel.doc.instructions_of([1], "conditions")[idx]
	_eq(str(c["id"]), "object.visible", "при правке условие заменено другим")
	_eq(str(c["params"][0]), "Enemy", "и объект сохранился")

	# ---- условие без параметров: настройки всё равно есть — ради «НЕ»
	_panel.add_instruction([1], "conditions")
	pk._objects.select(0)
	pk._on_object_selected(0)
	pk._select_id("system.at_start")
	_ok(ed.has_instruction() and ed._invert.visible and not ed.has_fields(),
			"у условия без параметров есть тумблер «НЕ»")
	pk.hide()

	# У действия «НЕ» нет — перевернуть действие нельзя, а выключить можно.
	_panel.edit_instruction([0], "actions", 0)
	_ok(not ed._invert.visible and ed._disable.visible, "у действия только тумблер «Выключено»")
	pk.hide()

	# Генератор: выключенное не исполняется, перевёрнутое — через filter_not.
	var reg := GdeRegistry.load_default()
	var d := GdeSheetDocument.create_empty("тумблеры")
	d.add_object("Player", "res://addons/gdevents/tests/bullet.tscn")
	d.add_event([], 0, "standard")
	d.add_instruction([0], "conditions", "object.flipped_h", ["Player"])
	d.add_instruction([0], "conditions", "object.visible", ["Player"])
	d.add_instruction([0], "actions", "system.print", ["\"раз\""])
	d.add_instruction([0], "actions", "system.print", ["\"два\""])
	d.set_instruction([0], "conditions", 0, ["Player"], {"inverted": true})
	d.set_instruction([0], "conditions", 1, ["Player"], {"disabled": true})
	d.set_instruction([0], "actions", 1, ["\"два\""], {"disabled": true})
	var code := str(GdeGenerator.generate(d.data, reg, "")["code"])
	_ok(code.contains("filter_not") and code.contains("is_flipped_h"),
			"перевёрнутое условие собрано как «НЕ»")
	_ok(not code.contains("is_visible("), "выключенное условие в код не попало")
	_ok(code.contains("print(\"раз\")") and not code.contains("print(\"два\")"),
			"выключенное действие не выполняется, соседнее — да")


# ------------------------------------------------------ ошибки в листе ---

## Ошибка сборки должна знать своё место: событие и строку. Иначе её
## нельзя подсветить в листе, а искать по тексту в консоли — мучение.
func _test_live_errors() -> void:
	var doc := GdeSheetDocument.create_empty("ошибки")
	doc.add_object("Player", "res://addons/gdevents/tests/bullet.tscn")
	doc.add_event([], 0, "standard")
	doc.add_event([], 1, "standard")
	doc.add_event([1], 0, "standard")
	doc.add_instruction([1, 0], "conditions", "key.pressed", ["Space"])
	doc.add_instruction([1, 0], "actions", "object.x", ["Player", "=", "Plaer.X() + 1"])
	var res := GdeGenerator.generate(doc.data, GdeRegistry.load_default(), "")
	var items: Array = res.get("error_items", [])
	_eq(items.size(), 1, "ровно одна ошибка — опечатка в имени объекта")
	if items.is_empty():
		return
	var it: Dictionary = items[0]
	_eq(str(it["path"]), str([1, 0]), "ошибка знает своё подсобытие")
	_eq(str(it["inst"]), str(["actions", 0]), "и свою строку")
	_ok(str(it["text"]).contains("Player"), "и подсказывает правильное имя: %s" % it["text"])
	_eq(GdeExpr.known_objects.size(), 0, "проверка имён не утекла за пределы сборки")

	# Выключенное событие не проверяется: выключают как раз то, что сломано.
	doc.toggle_disabled([1])
	var res2 := GdeGenerator.generate(doc.data, GdeRegistry.load_default(), "")
	_eq((res2.get("error_items", []) as Array).size(), 0, "выключенное событие не шумит ошибками")


# ------------------------------------------------------------ проверка сцен ---

func _run_scene_check() -> void:
	await _test_scene_check()


## Сцена с тем, на чём уже спотыкались: тело без формы, а форма рядом.
func _test_scene_check() -> void:
	var path := "user://gde_check_test.tscn"
	var root := Node2D.new()
	root.name = "Ящик"
	var shape := CollisionShape2D.new()
	shape.name = "Форма"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	shape.position = Vector2(10, 5)
	root.add_child(shape)
	shape.owner = root
	var body := RigidBody2D.new()
	body.name = "Тело"
	body.position = Vector2(4, 0)
	root.add_child(body)
	body.owner = root
	var empty := Sprite2D.new()
	empty.name = "Картинка"
	root.add_child(empty)
	empty.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, path)
	root.free()
	GdeSceneCheck.invalidate()
	GdeBehaviorInstaller.invalidate()

	var reg := GdeRegistry.load_default()
	var found := GdeSceneCheck.check(path, reg)
	var body_issue: Dictionary = {}
	for it: Dictionary in found:
		if str(it["node"]) == "Тело":
			body_issue = it
	_ok(not body_issue.is_empty(), "тело без формы найдено")
	_eq(str(body_issue.get("level", "")), "error", "и это ошибка, а не пожелание")
	var ids: Array[String] = []
	for f: Dictionary in body_issue.get("fixes", []):
		ids.append(str(f["id"]))
	_ok(ids.has("move_shape") and ids.has("delete_node"),
			"предложены оба пути: перенести форму и удалить пустое тело")
	var sprite_warned := false
	for it: Dictionary in found:
		if str(it["node"]) == "Картинка":
			sprite_warned = true
	_ok(sprite_warned, "спрайт без картинки замечен")

	var move_fix: Dictionary = {}
	for f: Dictionary in body_issue.get("fixes", []):
		if str(f["id"]) == "move_shape":
			move_fix = f
	var err: String = await GdeSceneCheck.fix(path, move_fix)
	_eq(err, "", "исправление применилось")

	var ps: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var r2 := ps.instantiate()
	var moved := r2.get_node_or_null("Тело/Форма") as CollisionShape2D
	_ok(moved != null, "форма теперь внутри тела")
	if moved != null:
		# Тело стоит в (4, 0), форма была в (10, 5): на экране она не должна сдвинуться.
		_eq(moved.position, Vector2(6, 5), "и осталась на том же месте на экране")
	r2.free()

	GdeSceneCheck.invalidate()
	var after := GdeSceneCheck.check(path, reg)
	var still := false
	for it: Dictionary in after:
		if str(it["node"]) == "Тело":
			still = true
	_ok(not still, "после исправления находка пропала")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ------------------------------------------------------- названия и описания ---

## В списке событий не должно быть ни голых имён из кода, ни строк
## без объяснения — именно на это была жалоба «ни о чём не говорят».
func _test_labels() -> void:
	var reg := GdeRegistry.load_default()
	var no_desc: Array[String] = []
	for table: Dictionary in [reg.conditions, reg.actions]:
		for id: String in table:
			if str((table[id] as Dictionary).get("description", "")).is_empty():
				no_desc.append(id)
	_eq(no_desc.size(), 0, "у каждой встроенной инструкции есть описание")

	var raw_names: Array[String] = []
	var untitled: Array[String] = []
	var undocumented: Array[String] = []
	for bname: String in reg.behaviors:
		var b: Dictionary = reg.behaviors[bname]
		if str(b.get("title", "")) == bname:
			untitled.append(bname)
		for table: String in ["actions", "conditions"]:
			var t: Dictionary = b[table]
			for id: String in t:
				var d: Dictionary = t[id]
				if str(d.get("description", "")).is_empty():
					undocumented.append("%s.%s" % [bname, id])
				# Имя свойства из кода внутри «» — значит, ##-описание не нашлось.
				if str(d.get("sentence", "")).contains("«%s»" % id.trim_prefix("set_").trim_prefix("is_")):
					raw_names.append("%s.%s" % [bname, id])
	_eq(untitled.size(), 0, "у каждого поведения есть русское название")
	_eq(undocumented.size(), 0, "у каждой инструкции поведений есть описание")
	_eq(raw_names.size(), 0, "нигде не протекло имя свойства из кода%s"
			% ("" if raw_names.is_empty() else ": " + ", ".join(raw_names)))
	# По-английски фразы длиннее, и короткое название из первой мысли
	# описания не получалось — в списке стояло «flip_sprite».
	GdeI18n.set_language("en", false)
	var reg_en := GdeRegistry.load_default()
	var raw_en: Array[String] = []
	for bname2: String in reg_en.behaviors:
		var t2: Dictionary = (reg_en.behaviors[bname2] as Dictionary)["actions"]
		for id2: String in t2:
			if str((t2[id2] as Dictionary).get("sentence", "")).contains("“%s”" % id2.trim_prefix("set_")):
				raw_en.append("%s.%s" % [bname2, id2])
	GdeI18n.set_language("ru", false)
	_eq(raw_en.size(), 0, "и по-английски имя свойства из кода не протекло%s"
			% ("" if raw_en.is_empty() else ": " + ", ".join(raw_en)))


## Лист, прошедший через редактор, должен остаться байт-в-байт тем же,
## если его не меняли. Иначе простое открытие шумело бы в гите.
func _test_roundtrip() -> void:
	var src := "res://addons/gdevents/tests/selftest.gdes.json"
	var tmp := "user://gde_roundtrip.gdes.json"
	var a := GdeSheetDocument.new()
	_ok(a.load_from(src).is_empty(), "лист для кругового теста загружен")
	a.path = tmp
	_ok(a.save().is_empty(), "лист сохранён во временный файл")

	var b := GdeSheetDocument.new()
	_ok(b.load_from(tmp).is_empty(), "сохранённый лист читается обратно")
	_eq(JSON.stringify(b.data, "", false), JSON.stringify(a.data, "", false),
			"содержимое пережило круг без изменений")

	# И самое важное: кодогенератор всё ещё понимает такой лист.
	var res := GdeGenerator.generate(b.data, _panel.registry, tmp)
	_eq((res["errors"] as Array).size(), 0, "лист после редактора собирается без ошибок")
	_ok(str(res["code"]).contains("pick_nearest"), "в сгенерированном коде есть сужение выборки")
	_ok(str(res["code"]).contains("filter("), "и поштучный отбор по условию")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))


## Поиск находит по видимому тексту, замена трогает только значения и
## отменяется одним шагом, свёрнутое событие прячет подсобытия.
func _test_search_and_fold() -> void:
	var evs := [
		{"type": "comment", "text": "Движение героя (hero)"},
		{"type": "standard", "conditions": [{"id": "key.pressed", "params": ["Left"]}],
			"actions": [{"id": "object.x", "params": ["Hero", "-", "5"]}],
			"children": [{"type": "standard", "conditions": [], "actions": [{"id": "object.x", "params": ["Enemy", "+", "1"]}]}]},
		{"type": "group", "name": "Враги", "children": []},
	]
	var reg: GdeRegistry = _panel.registry
	_eq(str(GdeSearch.find(evs, reg, "hero")), str([[0], [1]]), "поиск: без учёта регистра, в комментарии и в значении")
	_eq(str(GdeSearch.find(evs, reg, "enemy")), str([[1, 0]]), "поиск: находит в подсобытии")
	_eq(str(GdeSearch.find(evs, reg, "враги")), str([[2]]), "поиск: имя группы")
	_ok(not GdeSearch.find(evs, reg, GdeI18n.t("Изменить X у")).is_empty() or not GdeSearch.find(evs, reg, "X").is_empty(),
			"поиск: по фразе инструкции")
	var copy := evs.duplicate(true)
	_eq(GdeSearch.replace_all(copy, "Hero", "Player"), 1, "замена: одна замена в значении")
	_eq(str(copy[1]["actions"][0]["params"][0]), "Player", "замена: значение параметра заменено")
	_eq(str(copy[0]["text"]), "Движение героя (hero)", "замена: с учётом регистра — «hero» не тронуто")
	_eq(GdeSearch.replace_all(copy, "object.x", "zzz"), 0, "замена: id инструкции не трогается")

	# Через панель: поиск, переход, замена с отменой.
	var events: Array = _panel.doc.data["events"]
	var saved := events.duplicate(true)
	_panel.doc.data["events"] = evs.duplicate(true)
	_panel.doc.changed.emit()
	_panel.toggle_search(true)
	_panel._find_edit.text = "hero"
	_panel._run_search(false)
	_eq(_panel._found.size(), 2, "панель: найдено два события")
	_panel.find_next(1)
	_ok(_panel.is_event_selected([0]), "панель: переход к первому найденному")
	_panel._find_edit.text = "Hero"
	_panel._replace_edit.text = "Player"
	_panel.replace_all_found()
	_eq(str(_panel.doc.data["events"][1]["actions"][0]["params"][0]), "Player", "панель: «Заменить всё»")
	_panel.doc.undo()
	_eq(str(_panel.doc.data["events"][1]["actions"][0]["params"][0]), "Hero", "панель: замена отменяется одним шагом")

	# Сворачивание: подсобытие прячется, остаётся строка «свёрнуто».
	var rows_open := _count_rows(_panel)
	_panel.toggle_event_folded([1])
	_ok(_count_rows(_panel) < rows_open, "свёрнутое событие прячет подсобытия")
	_ok(_find_label_prefix(_panel, GdeI18n.t("свёрнуто подсобытий: %d") % 1), "на месте подсобытий — «свёрнуто: 1»")
	_panel._find_edit.text = "Enemy"
	_panel._run_search(true)
	_ok(not (_panel.doc.event_at([1]) as Dictionary).get("folded", false), "поиск разворачивает свёрнутое, чтобы показать найденное")
	_panel.toggle_search(false)
	_panel.doc.data["events"] = saved
	_panel.doc.changed.emit()


## Функция: карточка с именем, видом и параметрами; её вызов виден реестру.
func _test_function_card() -> void:
	var parsed: Dictionary = GdeEventSheetPanel.text_to_params("target: object: Кого\namount: number")
	_eq(parsed["error"], "", "параметры функции разбираются")
	_eq(str(parsed["params"]), str([{"name": "target", "kind": "object", "label": "Кого"}, {"name": "amount", "kind": "number"}]),
			"параметры функции: имя, вид, подпись")
	_ok(str(GdeEventSheetPanel.text_to_params("x: color")["error"]) != "", "неизвестный вид параметра — ошибка")
	_eq(GdeEventSheetPanel.params_to_text(parsed["params"]), "target: object: Кого\namount: number", "параметры обратно в строки")
	_panel.doc.add_event([], 9999, "function")
	var last: int = (_panel.doc.data["events"] as Array).size() - 1
	_panel.doc.set_event_field([last], "name", "Heal")
	_panel.doc.set_event_field([last], "params", parsed["params"])
	_ok(_panel.registry.action("fn.Heal") != null, "функция листа видна реестру — и окну выбора")
	_ok(_find_label_prefix(_panel, GdeI18n.t("Параметры: %s") % ""), "на карточке функции — её параметры")
	_panel.doc.set_event_field([last], "children", [{"type": "standard", "conditions": [], "actions": []}])
	_ok(_panel.doc.function_objects([last, 0]) == ["target"] and _panel.doc.function_objects([0]).is_empty(),
			"внутри функции её объект-параметр предлагается как объект")
	_panel.doc.undo()
	_panel.doc.undo()
	_panel.doc.undo()
	_panel.doc.undo()
	_ok(_panel.registry.action("fn.Heal") == null, "функция удалена — из реестра тоже")


func _find_label(n: Node, text: String) -> bool:
	if n is Label and (n as Label).text == text:
		return true
	for c: Node in n.get_children():
		if _find_label(c, text):
			return true
	return false


func _find_label_prefix(n: Node, prefix: String) -> bool:
	if n is Button and (n as Button).text.begins_with(prefix):
		return true
	for c: Node in n.get_children():
		if _find_label_prefix(c, prefix):
			return true
	return false


func _count_rows(n: Node) -> int:
	var c := 1 if n is GdeEventRow else 0
	for ch: Node in n.get_children():
		c += _count_rows(ch)
	return c


func _count_items(n: Node) -> int:
	var c := 1 if n is GdeInstructionItem else 0
	for ch: Node in n.get_children():
		c += _count_items(ch)
	return c


# ---------------------------------------------------------------- проверки ---

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	_checks += 1
	if str(got) == str(want):
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s — ожидалось %s, получено %s" % [what, want, got])


func _report() -> void:
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)
