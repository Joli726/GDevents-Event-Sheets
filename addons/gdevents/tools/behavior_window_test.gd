## Безголовый тест окна поведения — настроек и всего, что рядом:
##   godot --headless --quit-after 2000 res://addons/gdevents/tools/behavior_window_test.tscn
##
## Окно пишет в сцену объекта, и ошибиться тут легко незаметно: форма
## показывает одно, а в файле другое. Поэтому каждая проверка правки
## перечитывает сцену с диска.
##
## Сценой, а не через --script: без автозагрузки Gde скрипты поведений не
## компилируются, и у поведений не было бы ни одной настройки.
extends Node

const SCENE := "user://gde_behavior_window_test.tscn"
## Своя копия переключает сцены проекта — значит, нужна сцена в res://.
## Папка временная, тест убирает её за собой.
const LIB_DIR := "res://__gdevents_library_test"
const LIB_SCENE := LIB_DIR + "/hero.tscn"
const BULLET := "res://addons/gdevents/tests/bullet.tscn"

var _fails: int = 0
var _checks: int = 0
var _reg: GdeRegistry


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	_reg = GdeRegistry.load_default()
	await _make_scene()
	print("—— реестр: названия и описания настроек ——")
	_test_registry_meta()
	print("—— чтение поведения из сцены ——")
	_test_describe()
	print("—— форма настроек ——")
	await _test_form()
	print("—— пресет ——")
	await _test_preset()
	print("—— код поведения ——")
	_test_code()
	print("—— окно объектов ——")
	await _test_dialog()
	print("—— сравнение текстов ——")
	_test_diff()
	print("—— своя копия и возврат к встроенной ——")
	await _test_library()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCENE))
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


## Сцена объекта с телом и спрайтом, на которую ставим поведения установщиком.
func _make_scene() -> void:
	var root := Node2D.new()
	root.name = "Герой"
	var body := CharacterBody2D.new()
	body.name = "Тело"
	root.add_child(body)
	body.owner = root
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	body.add_child(shape)
	shape.owner = root
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Спрайт"
	var frames := SpriteFrames.new()
	frames.add_animation("Idle")
	frames.add_animation("Run")
	sprite.sprite_frames = frames
	body.add_child(sprite)
	sprite.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	root.free()
	ResourceSaver.save(ps, SCENE)
	GdeBehaviorInstaller.invalidate()
	for b: String in ["Shoot", "Follow", "Platformer"]:
		var d: Dictionary = _reg.behaviors[b]
		await GdeBehaviorInstaller.add(SCENE, b, str(d["path"]),
				{"target": d.get("target", ""), "needs": d.get("needs", [])})


func _test_registry_meta() -> void:
	var s: Dictionary = (_reg.behaviors["Shoot"] as Dictionary).get("settings", {})
	_eq(str((s.get("bullet_speed", {}) as Dictionary).get("label", "")), "Скорость снаряда",
			"русское название настройки из комментария")
	_eq(str((s.get("bullet_speed", {}) as Dictionary).get("group", "")), "Снаряд", "и её группа")
	_ok(str((s.get("preset", {}) as Dictionary).get("doc", "")).begins_with("Готовый набор"),
			"описание есть и у @export_enum на отдельной строке")
	_ok(bool((s.get("apply_preset", {}) as Dictionary).get("internal", false)),
			"служебная галочка пресета помечена как внутренняя")
	_ok(s.has("bullet_scene"), "сцена снаряда тоже настройка, хоть в события и не попадает")
	_ok(not (_reg.behaviors["Shoot"] as Dictionary)["conditions"].has("is_preset"),
			"библиотека событий не пополнилась лишним «пресетом»")


func _test_describe() -> void:
	var info := GdeBehaviorInstaller.describe(SCENE, "Shoot")
	_ok(not info.is_empty(), "поведение прочитано из сцены")
	var p := _prop(info, "bullet_speed")
	_eq(str(p.get("group", "")), "Снаряд", "свойство знает свою группу")
	_ok(int(p.get("hint", 0)) == PROPERTY_HINT_RANGE, "и пределы из @export_range")
	_ok(GdeBehaviorSettings.same_value(p.get("default"), 520.0), "значение по умолчанию взято из скрипта")
	# Платформеру нужно тело, и он встаёт внутрь него, а не на корень.
	_eq(str(GdeBehaviorInstaller.describe(SCENE, "Platformer").get("node", "")), "Тело/Platformer",
			"видно, на каком узле висит поведение")
	_ok((info.get("animations", []) as Array).has("Run"), "анимации сцены собраны для подсказок")


func _test_form() -> void:
	var form := GdeBehaviorSettings.new()
	add_child(form)
	await form.show_behavior(SCENE, "Shoot", _reg, ["Hero", "Enemy"])
	_ok(_labels(form).has("Скорость снаряда"), "в форме русские названия")
	_ok(not _labels(form).has("Apply preset"), "служебная галочка пресета не показана")
	_ok(_labels(form).has("СНАРЯД"), "настройки разбиты по группам")

	var spin := _find_editor(form, "bullet_speed") as SpinBox
	_ok(spin != null and is_equal_approx(spin.value, 520.0), "поле скорости показывает значение из сцены")
	var reset := _reset_of(form, "bullet_speed")
	_ok(reset != null and reset.disabled, "пока значение по умолчанию — кнопки сброса нет")
	spin.value = 777.0
	_ok(reset != null and not reset.disabled, "после правки появилась кнопка сброса")
	_ok(form.has_pending(), "правка ждёт записи, а не пишет сцену на каждое нажатие")
	await form.flush()
	_ok(GdeBehaviorSettings.same_value(_disk("Shoot", "bullet_speed"), 777.0), "правка записана в файл сцены")

	reset.pressed.emit()
	await form.flush()
	_ok(GdeBehaviorSettings.same_value(_disk("Shoot", "bullet_speed"), 520.0), "сброс вернул значение по умолчанию и в файле")
	_ok(is_equal_approx(spin.value, 520.0), "и в поле")

	var cb := _find_editor(form, "auto_move") as CheckBox
	cb.button_pressed = false
	await form.flush()
	_eq(_disk("Shoot", "auto_move"), false, "галочка записана")

	form.set_value("bullet_scene", load(BULLET))
	await form.flush()
	var sc: Variant = _disk("Shoot", "bullet_scene")
	_eq((sc as Resource).resource_path if sc is Resource else "", BULLET, "сцена снаряда выбрана и записана")

	# Несохранённая правка не теряется при переходе к другому поведению.
	spin = _find_editor(form, "fire_rate") as SpinBox
	spin.value = 0.5
	await form.show_behavior(SCENE, "Follow", _reg, ["Hero", "Enemy"])
	_ok(GdeBehaviorSettings.same_value(_disk("Shoot", "fire_rate"), 0.5), "при смене поведения правка дописалась")
	var target := _choices_of(form, "target_object")
	_ok(target != null and _menu_items(target).has("Enemy"), "цель выбирается из объектов листа")

	await form.show_behavior(SCENE, "Platformer", _reg, [])
	var anim := _choices_of(form, "idle_animation")
	_ok(anim != null and _menu_items(anim).has("Run"), "анимация выбирается из спрайта объекта")
	form.queue_free()


func _test_preset() -> void:
	var form := GdeBehaviorSettings.new()
	add_child(form)
	await form.show_behavior(SCENE, "Shoot", _reg, [])
	var ob := _find_editor(form, "preset") as OptionButton
	_ok(ob != null, "пресет — выпадающий список")
	if ob == null:
		return
	ob.select(ob.get_item_index(2))
	ob.item_selected.emit(ob.get_item_index(2))
	await form.apply_preset()
	_eq(_disk("Shoot", "pellets"), 7, "«Применить» записал настройки пресета «Дробовик»")
	_eq(_disk("Shoot", "magazine"), 6, "все, а не одну")
	var spin := _find_editor(form, "pellets") as SpinBox
	_ok(spin != null and int(spin.value) == 7, "форма перечитала новые значения")
	form.reset_all_values()
	await form.flush()
	_eq(_disk("Shoot", "pellets"), 1, "«Вернуть все по умолчанию» вернуло и дробь")
	form.queue_free()


func _test_code() -> void:
	var panel := GdeBehaviorPanel.new()
	add_child(panel)
	var path := str((_reg.behaviors["Shoot"] as Dictionary)["path"])
	panel.show_behavior(SCENE, "Shoot", _reg, [], "Shoot", path)
	var code := panel.code
	_ok(code.source().contains("extends GdeBehavior"), "на вкладке «Код» — исходник поведения")
	_ok(not code._code.editable, "только для чтения: правка — в редакторе скриптов")
	var items: Array[String] = []
	var pop := code._jump.get_popup()
	for i in range(pop.item_count):
		if not pop.is_item_separator(i):
			items.append(pop.get_item_text(i))
	var fire := -1
	for i in range(items.size()):
		if items[i] == "Выстрелить из ‹Объект›":
			fire = i
	_ok(fire >= 0, "«Перейти к…» называет действия фразами из листа: %s" % [items.slice(0, 3)])
	_ok(not items.has("Изменить «Скорость снаряда» у ‹Объект› (Выстрел): ‹Знак› ‹Значение›"),
			"и не путает их с настройками — у тех нет своей функции")
	if fire >= 0:
		code._on_jump(fire)
		var line := code._code.get_line(code.caret_line())
		_ok(line.begins_with("func fire"), "переход ставит курсор на функцию: %s" % line.strip_edges())
	panel.queue_free()


func _test_dialog() -> void:
	var doc := GdeSheetDocument.create_empty("тест окна")
	doc.add_object("Hero", SCENE)
	var dlg := GdeObjectsDialog.new()
	add_child(dlg)
	dlg.open_for(doc, _reg)
	await get_tree().process_frame
	var first := str((GdeBehaviorInstaller.scan(SCENE)[0] as Dictionary)["name"])
	_eq(dlg._selected_behavior, first, "при открытии выбрано первое поведение")
	_eq(dlg._beh_panel.settings.behavior, first, "и справа его настройки")
	var d: Dictionary = _reg.behaviors["Health"]
	await dlg._install_behavior("Health", str(d["path"]))
	_eq(dlg._selected_behavior, "Health", "только что добавленное поведение выбрано само")
	_eq(dlg._beh_panel.settings.behavior, "Health", "и его настройки открыты, как в GDevelop")
	_ok(dlg._tabs.get_tab_title(1).begins_with("Проверка сцены"), "проверка сцены — на своей вкладке")
	dlg._select_behavior("Follow")
	_eq(dlg._beh_panel.settings.behavior, "Follow", "щелчок по поведению переключает настройки")
	dlg.hide()
	dlg.queue_free()


func _test_library() -> void:
	var copy := GdeBehaviorLibrary.copy_path_for(str(_reg.behaviors["Rotate"]["path"]))
	var derived := "res://behaviors/wobble/wobble.gd"
	if FileAccess.file_exists(copy) or FileAccess.file_exists(derived):
		print("  — пропущено: в проекте уже есть своя копия «Вращения» или поведение Wobble")
		return
	var had_user_dir := DirAccess.dir_exists_absolute("res://behaviors")

	# Объект с «Вращением» и изменённой настройкой — она должна пережить всё.
	var root := Node2D.new()
	root.name = "Крутилка"
	var ps := PackedScene.new()
	ps.pack(root)
	root.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LIB_DIR))
	ResourceSaver.save(ps, LIB_SCENE)
	GdeBehaviorInstaller.invalidate()
	var builtin := str(_reg.behaviors["Rotate"]["path"])
	await GdeBehaviorInstaller.add(LIB_SCENE, "Rotate", builtin, {})
	await GdeBehaviorInstaller.set_property(LIB_SCENE, "Rotate", "degrees_per_second", 123.0)
	_eq(GdeBehaviorLibrary.kind_of(_reg.behaviors["Rotate"]), "builtin", "«Вращение» пока встроенное")

	var res: Dictionary = await GdeBehaviorLibrary.make_copy("Rotate", _reg)
	_eq(str(res.get("error", "")), "", "копия сделана без ошибок")
	_ok(FileAccess.file_exists(copy), "копия лежит в %s" % copy)
	_eq(FileAccess.get_file_as_string(copy), FileAccess.get_file_as_string(builtin),
			"в копии тот же код, что во встроенном")
	_ok(FileAccess.file_exists(GdeBehaviorLibrary.meta_dir_for(copy).path_join("base.gd.txt")),
			"рядом запомнена встроенная версия на момент копирования")
	var reg := GdeRegistry.load_default()
	_eq(str(reg.behaviors["Rotate"]["path"]), copy, "реестр берёт копию вместо встроенного")
	_eq(str(reg.behaviors["Rotate"]["builtin_path"]), builtin, "и помнит, где встроенное")
	_eq(reg.errors.size(), 0, "копия не считается дублем: %s" % [reg.errors])
	_eq(GdeBehaviorLibrary.kind_of(reg.behaviors["Rotate"]), "copy", "поведение — своя копия")
	_ok(FileAccess.get_file_as_string(LIB_SCENE).contains("path=\"%s\"" % copy), "сцена объекта переключена на копию")
	_ok(not FileAccess.get_file_as_string(LIB_SCENE).contains("path=\"%s\"" % builtin), "и больше не ссылается на встроенное")
	_ok(GdeBehaviorSettings.same_value(_prop(GdeBehaviorInstaller.describe(LIB_SCENE, "Rotate"), "degrees_per_second").get("value"), 123.0),
			"настройка объекта пережила переключение")
	var inst := (ResourceLoader.load(LIB_SCENE, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	add_child(inst)
	_ok(Gde.behavior(inst, "Rotate", true) != null, "в игре поведение находится по тому же имени")
	inst.queue_free()

	var src := FileAccess.get_file_as_string(copy)
	_ok(not GdeBehaviorLibrary.is_broken(copy), "рабочая копия не помечена сломанной")
	GdeBehaviorLibrary._write(copy, src + "\nfunc сломано(:\n")
	_ok(GdeBehaviorLibrary.is_broken(copy), "копия с ошибкой помечена сломанной")
	GdeBehaviorLibrary._write(copy, src)
	ResourceLoader.load(copy, "Script", ResourceLoader.CACHE_MODE_REPLACE)

	res = await GdeBehaviorLibrary.reset_to_builtin("Rotate", reg)
	_eq(str(res.get("error", "")), "", "возврат к встроенному без ошибок")
	_ok(not FileAccess.file_exists(copy), "файл копии убран")
	_ok(FileAccess.get_file_as_string(LIB_SCENE).contains("path=\"%s\"" % builtin), "сцена снова на встроенном")
	_ok(GdeBehaviorSettings.same_value(_prop(GdeBehaviorInstaller.describe(LIB_SCENE, "Rotate"), "degrees_per_second").get("value"), 123.0),
			"и настройка на месте")
	var versions := GdeBehaviorLibrary.list_versions(copy)
	_eq(versions.size(), 1, "копия ушла в историю версий, а не пропала")
	if not versions.is_empty():
		_eq(FileAccess.get_file_as_string(str(versions[0]["path"])), src, "в истории — её код целиком")
	reg = GdeRegistry.load_default()
	_eq(GdeBehaviorLibrary.kind_of(reg.behaviors["Rotate"]), "builtin", "реестр снова видит встроенное")

	# Новое поведение на основе — отдельное, со своим именем.
	_ok(not GdeBehaviorLibrary.name_problem("wobble", reg).is_empty(), "имя с маленькой буквы не принимается")
	_ok(not GdeBehaviorLibrary.name_problem("Rotate", reg).is_empty(), "занятое имя не принимается")
	_ok(not GdeBehaviorLibrary.name_problem("Enemy Shoot", reg).is_empty(), "имя с пробелом — тоже")
	res = await GdeBehaviorLibrary.create_from("Rotate", "Wobble", "Качалка", reg)
	_eq(str(res.get("error", "")), "", "новое поведение создано")
	reg = GdeRegistry.load_default()
	_ok(reg.behaviors.has("Wobble") and reg.behaviors.has("Rotate"), "появилось рядом со старым, а не вместо")
	_eq(str((reg.behaviors.get("Wobble", {}) as Dictionary).get("title", "")), "Качалка", "с новым названием")
	_eq(GdeBehaviorLibrary.kind_of(reg.behaviors.get("Wobble", {})), "own", "и считается своим")
	var node := Node.new()
	node.set_script(load(derived))
	_eq((node as GdeBehavior).behavior_name() if node is GdeBehavior else "", "Wobble",
			"рантайм выводит то же имя из имени файла")
	node.free()

	# То же самое кнопками окна объектов.
	var doc := GdeSheetDocument.create_empty("тест копий")
	doc.add_object("Spinner", LIB_SCENE)
	var dlg := GdeObjectsDialog.new()
	add_child(dlg)
	var got: Array = []
	dlg.library_changed.connect(func(r: GdeRegistry) -> void: got.append(r))
	dlg.open_for(doc, reg)
	await get_tree().process_frame
	var code := dlg._beh_panel.code
	_eq(code.kind, "builtin", "вкладка «Код» знает, что поведение встроенное")
	_ok(code._btn_copy.visible and not code._btn_reset.visible and not code._open.visible,
			"у встроенного — «Изменить поведение…», а в редактор скриптов его не открыть")
	await dlg._make_copy("Rotate")
	_eq(got.size(), 1, "лист событий получил новый реестр")
	_eq(dlg._beh_panel.code.kind, "copy", "после «Изменить» — своя копия")
	_ok(dlg._beh_panel.code._btn_reset.visible, "и появилась «Вернуть встроенную…»")
	_ok(_labels(dlg._behaviors).has("копия"), "в списке поведений пометка «копия»")
	await dlg._reset_copy("Rotate")
	_eq(dlg._beh_panel.code.kind, "builtin", "«Вернуть встроенную» вернула встроенное")
	_ok(not _labels(dlg._behaviors).has("копия"), "и пометка пропала")
	dlg.hide()
	dlg.queue_free()

	await _test_versions(copy, LIB_SCENE)

	# «Выстрел» выдаёт пуле «Прямолинейное движение» — своё, если есть копия.
	var lm := "res://addons/gdevents/behaviors/linear_move/linear_move.gd"
	_eq(GdeBehavior.resolve(lm).resource_path, lm, "без копии пуля получает встроенное движение")
	await GdeBehaviorLibrary.make_copy("LinearMove", reg)
	_eq(GdeBehavior.resolve(lm).resource_path, GdeBehaviorLibrary.copy_path_for(lm), "с копией — копию")

	# Убрать за собой всё, что создал тест.
	_rmdir(LIB_DIR)
	for d: String in ["res://behaviors/rotate", "res://behaviors/wobble", "res://behaviors/linear_move"]:
		_rmdir(d)
	if not had_user_dir:
		_rmdir("res://behaviors")


func _test_diff() -> void:
	var ops := GdeDiff.lines("a\nb\nc", "a\nx\nc")
	_eq(ops, [[" ", "a"], ["-", "b"], ["+", "x"], [" ", "c"]], "замена строки — одна убрана, одна добавлена")
	_eq(GdeDiff.stats(ops), {"added": 1, "removed": 1}, "и счёт сходится")
	_eq(GdeDiff.lines("a\nb", "a\nb"), [[" ", "a"], [" ", "b"]], "одинаковые тексты — без отличий")
	var long_a := "\n".join(range(40).map(func(i: int) -> String: return "строка %d" % i))
	var long_b := long_a.replace("строка 20", "строка 20!")
	var h := GdeDiff.hunks(GdeDiff.lines(long_a, long_b), 2)
	_eq(h.size(), 8, "длинный файл свёрнут до правки и пары строк вокруг")
	_eq(str((h[0] as Array)[0]), "…", "а начало без изменений — одной строкой-заглушкой")


## Версии своей копии: запомнить, восстановить, сравнить со встроенной,
## заметить обновление встроенной, вернуть копию после возврата к встроенной.
func _test_versions(copy: String, scene: String) -> void:
	var reg := GdeRegistry.load_default()
	await GdeBehaviorLibrary.make_copy("Rotate", reg)
	reg = GdeRegistry.load_default()
	var entry: Dictionary = reg.behaviors["Rotate"]
	var before := GdeBehaviorLibrary.list_versions(copy).size()
	_eq(GdeBehaviorLibrary.remember(entry, "стабильная"), "", "версия «стабильная» запомнена")
	var stable := FileAccess.get_file_as_string(copy)
	var vs := GdeBehaviorLibrary.list_versions(copy)
	_eq(vs.size(), before + 1, "и появилась в истории")
	_eq(str((vs[0] as Dictionary).get("title", "")), "стабильная", "новые версии — сверху")

	GdeBehaviorLibrary._write(copy, stable + "\n## моя правка\n")
	var res: Dictionary = await GdeBehaviorLibrary.restore_version("Rotate", reg, str(vs[0]["path"]), "стабильная")
	_eq(str(res.get("error", "")), "", "восстановление без ошибок")
	_eq(FileAccess.get_file_as_string(copy), stable, "в копии снова стабильная версия")
	vs = GdeBehaviorLibrary.list_versions(copy)
	_ok(str((vs[0] as Dictionary).get("title", "")).begins_with("Перед восстановлением"),
			"а правка перед этим сама ушла в историю, не пропала")

	GdeBehaviorLibrary._write(copy, stable + "\n## моя правка\n")
	var code := GdeBehaviorCode.new()
	add_child(code)
	code.show_script(copy, entry)
	_ok(code._btn_compare.visible, "у копии есть «Сравнить со встроенной»")
	code.show_compare()
	_ok(code.marked_lines("+").has("+ ## моя правка"), "своя правка подсвечена как добавленная")
	_eq(code.source(), stable + "\n## моя правка\n", "а код поведения не подменён сравнением")
	code.show_current()
	_eq(code.mode, "code", "«К текущему коду» возвращает код")

	_ok(not GdeBehaviorLibrary.builtin_changed(entry), "пока встроенная не менялась — напоминания нет")
	var info_path := GdeBehaviorLibrary.meta_dir_for(copy).path_join("copy.json")
	var info: Dictionary = GdeBehaviorLibrary._read_json(info_path, {})
	info["base_md5"] = "как будто плагин обновился"
	GdeBehaviorLibrary._write_json(info_path, info)
	_ok(GdeBehaviorLibrary.builtin_changed(entry), "обновление встроенной замечено")
	code.show_script(copy, entry)
	_ok(code._update_box.visible, "и о нём сказано на вкладке «Код»")
	GdeBehaviorLibrary.accept_builtin(entry)
	_ok(not GdeBehaviorLibrary.builtin_changed(entry), "«Учтено» убирает напоминание")
	code.queue_free()

	# Вернули встроенное — а потом захотели свою стабильную обратно.
	await GdeBehaviorLibrary.reset_to_builtin("Rotate", reg)
	reg = GdeRegistry.load_default()
	var builtin_entry: Dictionary = reg.behaviors["Rotate"]
	var old := GdeBehaviorLibrary.list_versions(GdeBehaviorLibrary.history_path(builtin_entry))
	var stable_v: Dictionary = {}
	for v: Dictionary in old:
		if str(v.get("title", "")) == "стабильная":
			stable_v = v
	_ok(not stable_v.is_empty(), "у встроенного видны прошлые копии")
	res = await GdeBehaviorLibrary.restore_version("Rotate", reg, str(stable_v.get("path", "")), "стабильная")
	_eq(str(res.get("error", "")), "", "копия восстановлена из версии")
	_eq(FileAccess.get_file_as_string(copy), stable, "с кодом стабильной версии")
	_ok(FileAccess.get_file_as_string(scene).contains("path=\"%s\"" % copy), "и сцена снова на копии")
	await GdeBehaviorLibrary.reset_to_builtin("Rotate", GdeRegistry.load_default())


func _rmdir(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	d.include_hidden = true
	d.list_dir_begin()
	var nm := d.get_next()
	while nm != "":
		var full := path.path_join(nm)
		if d.current_is_dir():
			_rmdir(full)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(full))
		nm = d.get_next()
	d.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ---------------------------------------------------------------- помощники ---

func _prop(info: Dictionary, nm: String) -> Dictionary:
	for p: Dictionary in info.get("props", []):
		if str(p["name"]) == nm:
			return p
	return {}


## Значение прямо из файла сцены — не из формы.
func _disk(bname: String, prop: String) -> Variant:
	GdeBehaviorInstaller.invalidate()
	return _prop(GdeBehaviorInstaller.describe(SCENE, bname), prop).get("value")


func _labels(n: Node) -> Array[String]:
	var out: Array[String] = []
	if n is Label:
		out.append((n as Label).text)
	for c: Node in n.get_children():
		out.append_array(_labels(c))
	return out


func _find_editor(form: GdeBehaviorSettings, prop: String) -> Control:
	var line := _line_of(form, prop)
	if line == null:
		return null
	var ed := line.get_child(1)
	if ed is HBoxContainer:
		return ed.get_child(0) as Control
	return ed as Control


func _reset_of(form: GdeBehaviorSettings, prop: String) -> Button:
	var row: Dictionary = form._rows.get(prop, {})
	return row.get("reset") as Button


func _choices_of(form: GdeBehaviorSettings, prop: String) -> MenuButton:
	var line := _line_of(form, prop)
	if line == null:
		return null
	for c: Node in line.get_child(1).get_children():
		if c is MenuButton:
			return c as MenuButton
	return null


func _line_of(form: GdeBehaviorSettings, prop: String) -> HBoxContainer:
	var reset := _reset_of(form, prop)
	return reset.get_parent() as HBoxContainer if reset != null else null


func _menu_items(mb: MenuButton) -> Array[String]:
	var out: Array[String] = []
	var pop := mb.get_popup()
	for i in range(pop.item_count):
		out.append(pop.get_item_text(i))
	return out


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
