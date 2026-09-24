## Безголовый тест языков:
##   godot --headless --script res://addons/gdevents/tools/i18n_test.gd
##
## Интерфейс плагина двуязычный: исходный текст в коде — русский, перевод —
## в i18n/<язык>.json. Забытый перевод не ломает ничего явно: в английском
## интерфейсе просто всплывает русская строка. Поэтому проверяется всё:
##   — у каждой строки GdeI18n.t("…") есть перевод на каждый язык;
##   — в переводе те же подстановки (%s, %d) в том же порядке;
##   — в коде плагина не осталось русских строк мимо GdeI18n.t().
## Строка, которую переводить нельзя (ключ, имя узла), помечается
## комментарием «# i18n: …» в конце.
extends SceneTree

const ROOT := "res://addons/gdevents/"
## Где живёт код, который показывает текст человеку.
const DIRS := ["editor", "codegen", "expr", "registry", "runtime", "behaviors", "extensions"]
const FILES := ["plugin.gd", "tools/check.gd", "tools/instruction_check.gd", "tools/library_list.gd"]

var _fails: int = 0
var _checks: int = 0


func _initialize() -> void:
	print("—— строки и переводы ——")
	var sources := _sources()
	var ids := _msgids(sources)
	_ok(ids.size() > 300, "найдено строк для перевода: %d" % ids.size())
	for lang: String in GdeI18n.LANGUAGES:
		if lang == GdeI18n.SOURCE:
			continue
		var cat := GdeI18n.catalog(lang)
		var missing: Array[String] = []
		var broken: Array[String] = []
		for id: String in ids:
			var v: Variant = cat.get(id)
			if not (v is String) or (v as String).is_empty():
				missing.append("%s  (%s)" % [id.replace("\n", "\\n"), ids[id]])
			elif _placeholders(id) != _placeholders(v):
				broken.append("%s → %s" % [id.replace("\n", "\\n"), (v as String).replace("\n", "\\n")])
		_ok(missing.is_empty(), "%s: у каждой строки есть перевод%s" % [lang, _list(missing)])
		_ok(broken.is_empty(), "%s: подстановки %%s/%%d совпадают%s" % [lang, _list(broken)])

	print("—— библиотека событий и поведения ——")
	_test_library()

	print("—— строки мимо перевода ——")
	var bare := _bare_russian(sources)
	_ok(bare.is_empty(), "в коде нет русских строк без GdeI18n.t()%s" % _list(bare))

	print("—— переключение ——")
	GdeI18n.set_language("en", false)
	_eq(GdeI18n.t("Собрать"), "Build", "по-английски — перевод")
	_eq(GdeI18n.t("строки нет в словаре"), "строки нет в словаре", "чего нет в словаре — как есть")
	GdeI18n.set_language("ru", false)
	_eq(GdeI18n.t("Собрать"), "Собрать", "по-русски — исходный текст")
	_eq(GdeI18n.pick({"": "по умолчанию", "en": "English"}, "en"), "English", "перевод из файла поведения")
	_eq(GdeI18n.pick({"": "по умолчанию", "en": "English"}, "ru"), "по умолчанию", "а без него — текст по умолчанию")
	GdeI18n.set_language("xx", false)
	_eq(GdeI18n.language(), GdeI18n.DEFAULT, "неизвестный язык — язык по умолчанию")

	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


## Встроенная библиотека (builtin.json) переводится по общему словарю, а
## поведения — метками в своём файле (@title.en, @action.en, ## @en …).
func _test_library() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(GdeRegistry.BUILTIN_PATH))
	var texts: Array[String] = []
	for sec: String in ["conditions", "actions"]:
		for id: String in (data[sec] as Dictionary):
			var def: Dictionary = data[sec][id]
			for f: String in ["sentence", "description", "group"]:
				if def.has(f):
					texts.append(str(def[f]))
			for p: Variant in def.get("params", []):
				if p is Dictionary and (p as Dictionary).has("label"):
					texts.append(str((p as Dictionary)["label"]))
	for sec2: String in ["expressions", "object_expressions"]:
		for id2: String in (data[sec2] as Dictionary):
			if (data[sec2][id2] as Dictionary).has("description"):
				texts.append(str(data[sec2][id2]["description"]))
	var param_re := RegEx.create_from_string("_PARAM\\d+_")
	for lang: String in GdeI18n.LANGUAGES:
		if lang == GdeI18n.SOURCE:
			continue
		var cat := GdeI18n.catalog(lang)
		var missing: Array[String] = []
		var params_bad: Array[String] = []
		var cyr := RegEx.create_from_string("[А-Яа-яЁё]")
		for t: String in texts:
			if cyr.search(t) == null:
				continue  # «X», «0…1» — переводить нечего
			if not cat.has(t):
				missing.append(t)
			else:
				var a: Array[String] = []
				var b: Array[String] = []
				for m: RegExMatch in param_re.search_all(t):
					a.append(m.get_string())
				for m2: RegExMatch in param_re.search_all(str(cat[t])):
					b.append(m2.get_string())
				a.sort()
				b.sort()
				if a != b:
					params_bad.append("%s → %s" % [t, cat[t]])
		_ok(missing.is_empty(), "%s: у всей встроенной библиотеки есть перевод%s" % [lang, _list(missing)])
		_ok(params_bad.is_empty(), "%s: в переводе фраз те же _PARAMn_%s" % [lang, _list(params_bad)])

		GdeI18n.set_language(lang, false)
		var reg := GdeRegistry.load_default()
		var gaps: Array[String] = []
		for b: String in reg.behaviors:
			var e: Dictionary = reg.behaviors[b]
			if not str(e["path"]).begins_with(GdeRegistry.BEHAVIOR_DIRS[0]):
				continue
			for what: Variant in ((e["untranslated"] as Dictionary).get(lang, []) as Array):
				gaps.append("%s: %s" % [b, what])
		_ok(gaps.is_empty(), "%s: у встроенных поведений переведено всё%s" % [lang, _list(gaps)])
		var ext_gaps: Array[String] = []
		for x: String in reg.extensions:
			var xe: Dictionary = reg.extensions[x]
			if not str(xe["path"]).begins_with(GdeRegistry.EXTENSION_DIRS[0]):
				continue
			for what2: Variant in ((xe["untranslated"] as Dictionary).get(lang, []) as Array):
				ext_gaps.append("%s: %s" % [x, what2])
		_ok(not reg.extensions.is_empty() and ext_gaps.is_empty(),
				"%s: у встроенных расширений переведено всё%s" % [lang, _list(ext_gaps)])
		GdeI18n.set_language(GdeI18n.SOURCE, false)


func _sources() -> Array[String]:
	var out: Array[String] = []
	for d: String in DIRS:
		out.append_array(_gd_files(ROOT + d))
	for f: String in FILES:
		out.append(ROOT + f)
	return out


func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var nm := d.get_next()
	while nm != "":
		if d.current_is_dir():
			if not nm.begins_with("."):
				out.append_array(_gd_files(dir.path_join(nm)))
		elif nm.ends_with(".gd"):
			out.append(dir.path_join(nm))
		nm = d.get_next()
	return out


## Строка -> файл, где она встретилась впервые.
func _msgids(sources: Array[String]) -> Dictionary:
	var re := RegEx.create_from_string("GdeI18n\\.t\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	var out: Dictionary = {}
	for f: String in sources:
		for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(f)):
			var id := m.get_string(1).c_unescape()
			if not out.has(id):
				out[id] = f.trim_prefix(ROOT)
	return out


func _placeholders(s: String) -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string("%(?:\\.\\d+)?[sdfv]")
	for m: RegExMatch in re.search_all(s):
		out.append(m.get_string())
	return out


## Русские строковые литералы в коде, не обёрнутые в GdeI18n.t().
func _bare_russian(sources: Array[String]) -> Array[String]:
	var out: Array[String] = []
	var lit := RegEx.create_from_string("\"((?:[^\"\\\\\\n]|\\\\.)*)\"")
	var cyr := RegEx.create_from_string("[А-Яа-яЁё]")
	for f: String in sources:
		var lines := FileAccess.get_file_as_string(f).split("\n")
		for i in range(lines.size()):
			var line := lines[i]
			var st := line.strip_edges()
			if st.begins_with("#") or st.begins_with("@") or line.contains("# i18n:"):
				continue
			var code := line.substr(0, _comment_at(line))
			for m: RegExMatch in lit.search_all(code):
				if cyr.search(m.get_string()) == null:
					continue
				if code.substr(0, m.get_start()).strip_edges(false, true).ends_with("GdeI18n.t("):
					continue
				out.append("%s:%d  %s" % [f.trim_prefix(ROOT), i + 1, st.left(90)])
	return out


## Где начинается комментарий — «#» вне строки.
static func _comment_at(line: String) -> int:
	var q := ""
	var i := 0
	while i < line.length():
		var c := line[i]
		if not q.is_empty():
			if c == "\\":
				i += 2
				continue
			if c == q:
				q = ""
		elif c == "\"" or c == "'":
			q = c
		elif c == "#":
			return i
		i += 1
	return line.length()


func _list(items: Array[String]) -> String:
	if items.is_empty():
		return ""
	var shown := items.slice(0, 15)
	return ":\n      " + "\n      ".join(shown) + ("\n      … и ещё %d" % (items.size() - 15) if items.size() > 15 else "")


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
