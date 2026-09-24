## Проверка своего файла — поведения, расширения или листа событий:
##   godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://behaviors/enemy_shoot/enemy_shoot.gd
##   godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://extensions/weather/weather.gd
##   godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://events/level.gdes.json
##   godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn            # всё своё сразу
## Язык отчёта: -- --lang=ru (или en) после остальных аргументов.
##
## ✓ — всё хорошо, ✗ — ошибка (код выхода 1), ! — работает, но стоит поправить.
## Файл готов, когда ошибок нет. Каждая инструкция поведения и расширения
## не только компилируется, но и выполняется на живом объекте.
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node


## Ошибки разбора скрипта со строками — их Godot иначе пишет только в вывод.
class ParseCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(_function: String, _file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			var text := (rationale if rationale != "" else code).trim_prefix("Parse Error: ")
			errors.append(GdeI18n.t("строка %d: %s") % [line, text])

	func _log_message(_message: String, _error: bool) -> void:
		pass


var _errors: int = 0
var _warnings: int = 0
var _oks: int = 0
var _reg: GdeRegistry
var _chk: GdeInstructionCheck


func _ready() -> void:
	var targets: Array[String] = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			GdeI18n.set_language(a.trim_prefix("--lang="), false)
		elif not a.strip_edges().is_empty():
			targets.append(a.strip_edges())
	_reg = GdeRegistry.load_default()
	if targets.is_empty():
		targets = _own_files()
		if targets.is_empty():
			print(GdeI18n.t("Своих поведений, расширений и листов в проекте нет — проверять нечего."))
			get_tree().quit(0)
			return
	_chk = GdeInstructionCheck.new(_reg)
	add_child(_chk)
	await _chk.prepare()
	for t: String in targets:
		print("\n== %s" % t)
		if t.ends_with(".gdes.json"):
			_check_sheet(t)
		else:
			_check_script(t)
	_chk.finish()
	print("\n" + GdeI18n.t("—— итог: хорошо %d, ошибок %d, предупреждений %d") % [_oks, _errors, _warnings])
	if _errors == 0:
		print(GdeI18n.t("Готово: ошибок нет."))
	get_tree().quit(1 if _errors > 0 else 0)


## Всё своё: res://behaviors, res://extensions и листы вне addons/.
func _own_files() -> Array[String]:
	var out: Array[String] = []
	for d: String in [GdeRegistry.BEHAVIOR_DIRS[1], GdeRegistry.EXTENSION_DIRS[1]]:
		if DirAccess.dir_exists_absolute(d):
			out.append_array(_reg._gd_files(d))
	out.append_array(GdeBuild.find_sheets("res://"))
	return out


# ------------------------------------------------------ поведение, расширение ---

func _check_script(path: String) -> void:
	if not FileAccess.file_exists(path):
		_err(GdeI18n.t("файла нет"))
		return
	var src := FileAccess.get_file_as_string(path)
	var is_beh := src.contains("extends GdeBehavior")
	var is_ext := src.contains("extends GdeExtension")
	if not is_beh and not is_ext:
		_err(GdeI18n.t("это не поведение и не расширение: нужен extends GdeBehavior или extends GdeExtension"))
		return
	var catcher := ParseCatcher.new()
	OS.add_logger(catcher)
	var comp := GdeBuild.compile_error(src)
	OS.remove_logger(catcher)
	if not comp.is_empty():
		_err(GdeI18n.t("скрипт не компилируется:"))
		for e: String in catcher.errors:
			print("      " + e)
		return
	_ok(GdeI18n.t("скрипт компилируется"))

	var entry: Dictionary = {}
	var name := ""
	var table: Dictionary = _reg.behaviors if is_beh else _reg.extensions
	for n: String in table:
		if str((table[n] as Dictionary)["path"]) == path:
			entry = table[n]
			name = n
	for e: String in _reg.errors:
		if e.contains(path) or (not name.is_empty() and e.contains("«%s»" % name)):
			_err(e)
	if entry.is_empty():
		_err(GdeI18n.t("плагин не видит файл: поведение должно лежать в res://behaviors/<имя>/<имя>.gd, расширение — в res://extensions/<имя>/<имя>.gd"))
		return

	var file_name := GdeBehaviorInstaller.pascal(path.get_file().get_basename())
	if name != file_name:
		_err(GdeI18n.t("имя «%s» из @%s не совпадает с именем файла: в игре оно будет «%s». Назовите файл %s.gd или поменяйте имя")
				% [name, "behavior" if is_beh else "extension", file_name, GdeBehaviorLibrary.snake(name)])
	else:
		_ok(GdeI18n.t("имя «%s» совпадает с именем файла") % name)

	if RegEx.create_from_string("(?m)^class_name\\s").search(src) != null:
		_warn(GdeI18n.t("class_name не нужен и мешает: своя копия или второй файл с тем же классом не соберутся"))
	if is_beh:
		_check_behavior_source(src)
	_check_members(entry, name, is_beh)
	if is_beh:
		_check_settings(entry)
	_check_translations(entry)


func _check_behavior_source(src: String) -> void:
	if not src.contains("@tool"):
		_warn(GdeI18n.t("нет @tool: пресеты и настройки не будут работать в редакторе"))
	var ready := RegEx.create_from_string("(?ms)^func _ready\\(\\).*?(?=^func |\\z)").search(src)
	if ready != null and not ready.get_string().contains("super"):
		_err(GdeI18n.t("_ready() без super(): в редакторе поведение начнёт двигать объекты прямо в сцене"))
	if RegEx.create_from_string("preload\\(\"res://addons/gdevents/behaviors/").search(src) != null:
		_warn(GdeI18n.t("другое поведение подключено через preload по пути — своя копия его не подменит; используйте GdeBehavior.resolve(путь)"))


func _check_members(entry: Dictionary, name: String, is_beh: bool) -> void:
	var n := 0
	for m: String in (entry.get("conditions", {}) as Dictionary):
		n += 1
		_result(GdeI18n.t("условие %s") % m, _chk.condition("%s::%s" % [name, m]))
	for m: String in (entry.get("actions", {}) as Dictionary):
		n += 1
		if "%s::%s" % [name, m] in GdeInstructionCheck.SKIP:
			continue
		_result(GdeI18n.t("действие %s") % m, _chk.action("%s::%s" % [name, m]))
	for m: String in (entry.get("expressions", {}) as Dictionary):
		n += 1
		var def: Variant = _reg.behavior_expr(name, m) if is_beh else _reg.ext_expr(name, m)
		var call := ("%s.%s::%s" % [GdeInstructionCheck.HERO, name, m]) if is_beh else ("%s::%s" % [name, m])
		_result(GdeI18n.t("выражение %s") % m, _chk.expression(call, def) if def != null else GdeI18n.t("не найдено"))
	var bare: Array[String] = []
	var ident := RegEx.create_from_string("^[a-z_][a-z0-9_]*$")
	for table: String in ["conditions", "actions"]:
		for m2: String in (entry.get(table, {}) as Dictionary):
			for p: Dictionary in (entry[table][m2] as Dictionary).get("params", []):
				# Без @param подписью остаётся имя аргумента: ‹frames› вместо «Кадров».
				if ident.search(str(p.get("label", ""))) != null:
					bare.append("%s(%s)" % [m2, p["label"]])
	if not bare.is_empty():
		_warn(GdeI18n.t("у параметров нет подписи ## @param — в окне будут имена из кода: %s") % ", ".join(bare))
	if n == 0:
		_warn(GdeI18n.t("ни одного условия, действия или выражения: в листе событий с ним нечего делать — нет разметки ## @action / @condition / @expression над функциями?"))


func _check_settings(entry: Dictionary) -> void:
	var missing: Array[String] = []
	var settings: Dictionary = entry.get("settings", {})
	for p: String in settings:
		var m: Dictionary = settings[p]
		if not bool(m.get("internal", false)) and str(m.get("doc", "")).is_empty():
			missing.append(p)
	if missing.is_empty():
		_ok(GdeI18n.t("у всех настроек есть описание (%d)") % settings.size())
	else:
		_warn(GdeI18n.t("у настроек нет ##-описания — в окне будут голые имена: %s") % ", ".join(missing))


func _check_translations(entry: Dictionary) -> void:
	# Основной текст может быть на любом языке, а переводы — метками .en,
	# .ru рядом с ним. Без перевода файл работает, поэтому это предупреждение.
	var miss: Dictionary = entry.get("untranslated", {})
	var shown := false
	for lang: String in GdeI18n.LANGUAGES:
		var list: Array = miss.get(lang, [])
		if list.is_empty():
			continue
		_warn(GdeI18n.t("нет перевода на %s (%d): %s — добавьте метки .%s рядом с основным текстом")
				% [lang, list.size(), ", ".join(list.slice(0, 8)) + (" …" if list.size() > 8 else ""), lang])
		shown = true
	if not shown:
		_ok(GdeI18n.t("переведено на все языки"))


# ---------------------------------------------------------------- лист ---

func _check_sheet(path: String) -> void:
	if not FileAccess.file_exists(path):
		_err(GdeI18n.t("файла нет"))
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		_err(GdeI18n.t("некорректный JSON"))
		return
	var m := GdeSheetFormat.migrate(parsed)
	if str(m["error"]) != "":
		_err(str(m["error"]))
		return
	var sheet: Dictionary = m["data"]
	_check_structure(sheet)
	var names: Array = []
	for o: Variant in sheet.get("objects", []):
		var od: Dictionary = o
		names.append(str(od.get("name", "")))
		var scene := str(od.get("scene", ""))
		if not ResourceLoader.exists(scene):
			_err(GdeI18n.t("объект «%s»: сцены %s нет") % [od.get("name", ""), scene])
			continue
		for it: Dictionary in GdeSceneCheck.check(scene, _reg, []):
			var msg := GdeI18n.t("объект «%s»: %s") % [od.get("name", ""), it["text"]]
			if str(it["level"]) == "error":
				_err(msg)
			else:
				_warn(msg)
	var r := GdeGenerator.generate(sheet, _reg, path)
	for w: String in r["warnings"]:
		_warn(w)
	for it: Dictionary in r["error_items"]:
		_err("%s: %s" % [_where(it), it["text"]])
	if (r["errors"] as Array).is_empty():
		var comp := GdeBuild.compile_error(r["code"])
		if comp.is_empty():
			_ok(GdeI18n.t("лист собирается, событий: %d") % (sheet.get("events", []) as Array).size())
		else:
			_err(GdeI18n.t("собранный код не компилируется (%s) — это ошибка GDevents, сообщите о ней") % comp)


## Ключи, которые понимает генератор. Остальное он молча пропускает — а для
## автора это потерянная работа: «events» внутри события вместо «children»
## и подсобытия просто исчезают из игры.
const SHEET_KEYS := ["format", "name", "extends", "objects", "groups", "variables", "events"]
const EVENT_KEYS := {
	"standard": ["type", "disabled", "any", "locals", "conditions", "actions", "children"],
	"foreach": ["type", "disabled", "any", "locals", "object", "conditions", "actions", "children"],
	"repeat": ["type", "disabled", "locals", "count", "actions", "children"],
	"while": ["type", "disabled", "any", "locals", "conditions", "actions", "children"],
	"group": ["type", "disabled", "name", "children"],
	"comment": ["type", "disabled", "text"],
}
const COND_KEYS := ["id", "params", "inverted", "disabled"]
const ACT_KEYS := ["id", "params", "disabled"]
## Частые промахи -> как правильно.
const KEY_HINTS := {
	"events": "children", "sub_events": "children", "subevents": "children",
	"not": "inverted", "negate": "inverted", "invert": "inverted", "negated": "inverted",
	"args": "params", "parameters": "params", "arguments": "params",
	"action": "actions", "condition": "conditions", "enabled": "disabled",
}


func _check_structure(sheet: Dictionary) -> void:
	_unknown_keys(sheet, SHEET_KEYS, GdeI18n.t("лист"))
	for key: String in ["objects", "events"]:
		if sheet.has(key) and not (sheet[key] is Array):
			_err(GdeI18n.t("«%s» должен быть списком [...]") % key)
			return
	for key2: String in ["variables", "groups"]:
		if sheet.has(key2) and not (sheet[key2] is Dictionary):
			_err(GdeI18n.t("«%s» должен быть словарём {...}") % key2)
	for o: Variant in sheet.get("objects", []):
		if not (o is Dictionary):
			_err(GdeI18n.t("объект листа должен быть {\"name\": …, \"scene\": …}"))
			continue
		_unknown_keys(o, ["name", "scene"], GdeI18n.t("объект «%s»") % (o as Dictionary).get("name", ""))
	_check_events(sheet.get("events", []), [])


func _check_events(events: Variant, path: Array) -> void:
	if not (events is Array):
		_err(GdeI18n.t("%s: «children» должен быть списком [...]") % _where({"path": path}))
		return
	var i := 0
	for ev: Variant in events:
		var p := path.duplicate()
		p.append(i)
		i += 1
		var at := _where({"path": p})
		if not (ev is Dictionary):
			_err(GdeI18n.t("%s: событие должно быть словарём {...}") % at)
			continue
		var e: Dictionary = ev
		var type := str(e.get("type", "standard"))
		if not EVENT_KEYS.has(type):
			_err(GdeI18n.t("%s: неизвестный тип события «%s» — бывают: %s") % [at, type, ", ".join(EVENT_KEYS.keys())])
			continue
		_unknown_keys(e, EVENT_KEYS[type], at)
		for kind: String in ["conditions", "actions"]:
			if not e.has(kind):
				continue
			if not (e[kind] is Array):
				_err(GdeI18n.t("%s: «%s» должен быть списком [...]") % [at, kind])
				continue
			var j := 0
			for inst: Variant in e[kind]:
				j += 1
				var where := "%s, %s" % [at, (GdeI18n.t("условие %d") if kind == "conditions" else GdeI18n.t("действие %d")) % j]
				if not (inst is Dictionary):
					_err(GdeI18n.t("%s: должно быть {\"id\": …, \"params\": [...]}") % where)
					continue
				_unknown_keys(inst, COND_KEYS if kind == "conditions" else ACT_KEYS, where)
				var prm: Variant = (inst as Dictionary).get("params", [])
				if not (prm is Array):
					_err(GdeI18n.t("%s: «params» должен быть списком строк") % where)
				else:
					for v: Variant in prm:
						if not (v is String):
							var txt := str(int(v)) if v is float and is_equal_approx(v, roundf(v)) else str(v)
							_warn(GdeI18n.t("%s: параметр %s записан не строкой — пишите \"%s\"") % [where, txt, txt])
							break
		if e.has("children"):
			_check_events(e["children"], p)


func _unknown_keys(d: Dictionary, allowed: Array, where: String) -> void:
	for k: Variant in d:
		if allowed.has(k):
			continue
		var hint: String = KEY_HINTS.get(str(k), "")
		if not hint.is_empty() and allowed.has(hint):
			_err(GdeI18n.t("%s: ключ «%s» не читается — нужен «%s»") % [where, k, hint])
		else:
			_err(GdeI18n.t("%s: ключ «%s» не читается и будет пропущен — можно: %s") % [where, k, ", ".join(allowed)])


## «событие 2 › 1, условие 3» — где в листе ошибка.
func _where(it: Dictionary) -> String:
	var path: Array = it.get("path", [])
	var bits: Array[String] = []
	for i: Variant in path:
		bits.append(str(int(i) + 1))
	var s := GdeI18n.t("событие %s") % " › ".join(bits) if not bits.is_empty() else GdeI18n.t("лист")
	var inst: Array = it.get("inst", [])
	if inst.size() == 2:
		s += (GdeI18n.t(", условие %d") if str(inst[0]) == "conditions" else GdeI18n.t(", действие %d")) % (int(inst[1]) + 1)
	return s


# ---------------------------------------------------------------- вывод ---

func _result(what: String, why: String) -> void:
	if why.is_empty():
		_ok(what)
	else:
		_err("%s — %s" % [what, why])


func _ok(text: String) -> void:
	_oks += 1
	print("  ✓ " + text)


func _err(text: String) -> void:
	_errors += 1
	print("  ✗ " + text)


func _warn(text: String) -> void:
	_warnings += 1
	print("  ! " + text)
