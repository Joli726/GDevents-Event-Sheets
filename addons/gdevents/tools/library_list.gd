## Справочник для тех, кто пишет листы событий руками или нейросетью:
## каждое условие, действие и выражение с точным id и видами параметров.
##   godot --headless --script res://addons/gdevents/tools/library_list.gd
##   godot --headless --script res://addons/gdevents/tools/library_list.gd -- Shoot
##   godot --headless --script res://addons/gdevents/tools/library_list.gd -- --lang=ru
## Слово после «--» отбирает строки, где оно встречается в id, группе или фразе.
## Язык по умолчанию — английский: id и параметры от языка не зависят.
extends SceneTree


func _init() -> void:
	var lang := "en"
	var only := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			lang = a.trim_prefix("--lang=")
		else:
			only = a.strip_edges()
	GdeI18n.set_language(lang, false)
	var reg := GdeRegistry.load_default()
	for e: String in reg.errors:
		print("! ", e)

	if only.is_empty():
		print(GdeI18n.t("Виды параметров: object — объект листа (его отобранные экземпляры); objname — имя объекта; number — числовое выражение; string — текстовое выражение, текст в кавычках: %s; raw — голый текст без кавычек (клавиша, анимация, таймер, путь к файлу); varname — имя переменной, можно hp или player.hp; cmpop — = ≠ < > ≤ ≥; modop — = + - * /.")
				% "\"\\\"Hi\\\"\"")
		print(GdeI18n.t("Каждый параметр в листе — строка JSON: %s.") % "[\"Player\", \"+\", \"10 * TimeDelta()\"]")

	_table(GdeI18n.t("Условия"), reg.conditions, only)
	_table(GdeI18n.t("Действия"), reg.actions, only)
	for b: String in reg.behaviors:
		var be: Dictionary = reg.behaviors[b]
		var rows: Dictionary = {}
		for kind: String in ["conditions", "actions"]:
			for m: String in (be[kind] as Dictionary):
				rows["%s::%s" % [b, m]] = be[kind][m]
		_table(GdeI18n.t("Поведение %s «%s»") % [b, be["title"]], rows, only)

	var lines: Array[String] = []
	for name: String in reg.expressions:
		lines.append(_expr(name, reg.expressions[name]))
	for name2: String in reg.object_expressions:
		lines.append(_expr(GdeI18n.t("Объект") + "." + name2, reg.object_expressions[name2]))
	for b2: String in reg.behaviors:
		var ex: Dictionary = (reg.behaviors[b2] as Dictionary)["expressions"]
		for name3: String in ex:
			lines.append(_expr("%s.%s::%s" % [GdeI18n.t("Объект"), b2, name3], ex[name3]))
	for key: String in reg.ext_expressions:
		lines.append(_expr(key, reg.ext_expressions[key]))
	_print_section(GdeI18n.t("Выражения"), lines, only)
	quit()


func _table(title: String, table: Dictionary, only: String) -> void:
	var lines: Array[String] = []
	for id: String in table:
		var d: Dictionary = table[id]
		var params: Array[String] = []
		for p: Dictionary in d.get("params", []):
			params.append("%s %s" % [p.get("kind", "number"), p.get("label", "")])
		var group := str(d.get("group", ""))
		lines.append("%s [%s] (%s) — %s%s" % [id, d.get("kind", "global"), ", ".join(params),
				d.get("sentence", ""), ("  ·%s" % group) if not group.is_empty() else ""])
	_print_section(title, lines, only)


func _expr(call: String, d: Dictionary) -> String:
	var kinds: Array[String] = []
	for k: Variant in d.get("params", []):
		kinds.append(str(k))
	return "%s(%s) -> %s — %s" % [call, ", ".join(kinds), d.get("type", "number"), d.get("description", "")]


func _print_section(title: String, lines: Array[String], only: String) -> void:
	var shown: Array[String] = []
	for l: String in lines:
		if only.is_empty() or l.containsn(only) or title.containsn(only):
			shown.append(l)
	if shown.is_empty():
		return
	print("\n== %s" % title)
	for l2: String in shown:
		print(l2)
