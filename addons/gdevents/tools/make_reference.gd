## Справочник всех инструкций: docs/REFERENCE.md (английский) и
## docs/REFERENCE.ru.md (русский) — собираются из библиотеки, руками их не правят.
##   godot --headless --script res://addons/gdevents/tools/make_reference.gd            — записать
##   godot --headless --script res://addons/gdevents/tools/make_reference.gd -- --check — сверить
## Сверку запускают тесты: справочник, отставший от библиотеки, — провал.
extends SceneTree

const DOCS := "res://addons/gdevents/docs/"
const FILES := {"en": "REFERENCE.md", "ru": "REFERENCE.ru.md"}


func _initialize() -> void:
	var check := OS.get_cmdline_user_args().has("--check")
	var stale: Array[String] = []
	for lang: String in FILES:
		GdeI18n.set_language(lang, false)
		var text := build(GdeRegistry.load_default())
		var path := DOCS + str(FILES[lang])
		if check:
			var cur := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
			if cur != text:
				stale.append(path)
		else:
			var f := FileAccess.open(path, FileAccess.WRITE)
			f.store_string(text)
			f.close()
			print("✓ %s" % path)
	if check:
		GdeI18n.set_language("ru", false)
		if stale.is_empty():
			print(GdeI18n.t("  ✓ справочник совпадает с библиотекой"))
		else:
			print(GdeI18n.t("  ✗ справочник отстал от библиотеки: %s — пересоберите: godot --headless --script res://addons/gdevents/tools/make_reference.gd") % ", ".join(stale))
		print(GdeI18n.t("—— проверок: 1, провалено: %d") % (0 if stale.is_empty() else 1))
	quit(1 if not stale.is_empty() else 0)


static func build(reg: GdeRegistry) -> String:
	var out: Array[String] = []
	out.append(GdeI18n.t("# Справочник инструкций GDevents"))
	out.append("")
	out.append(GdeI18n.t("Собран из библиотеки командой `tools/make_reference.gd` — не правьте его руками. Во всех параметрах текст пишется в кавычках, числа и выражения — как есть. Точный id нужен, когда лист пишут текстом или просят нейросеть."))
	out.append("")
	out.append(GdeI18n.t("- [Условия](#%s)") % _anchor(GdeI18n.t("Условия")))
	out.append(GdeI18n.t("- [Действия](#%s)") % _anchor(GdeI18n.t("Действия")))
	out.append(GdeI18n.t("- [Выражения](#%s)") % _anchor(GdeI18n.t("Выражения")))
	out.append(GdeI18n.t("- [Поведения](#%s)") % _anchor(GdeI18n.t("Поведения")))
	out.append("")
	_instructions(out, GdeI18n.t("Условия"), reg.conditions)
	_instructions(out, GdeI18n.t("Действия"), reg.actions)

	out.append("## %s" % GdeI18n.t("Выражения"))
	out.append("")
	out.append(GdeI18n.t("Общие выражения пишутся как `Имя(…)`, выражения объекта — как `Объект.Имя(…)`, выражения поведения — как `Объект.Поведение::Имя(…)`."))
	out.append("")
	out.append("| %s | %s | %s |" % [GdeI18n.t("Выражение"), GdeI18n.t("Даёт"), GdeI18n.t("Что это")])
	out.append("| --- | --- | --- |")
	for name: String in _sorted(reg.expressions):
		out.append(_expr_row("%s(%s)" % [name, _kinds(reg.expressions[name])], reg.expressions[name]))
	for name2: String in _sorted(reg.object_expressions):
		out.append(_expr_row("%s.%s(%s)" % [GdeI18n.t("Объект"), name2, _kinds(reg.object_expressions[name2])], reg.object_expressions[name2]))
	for key: String in _sorted(reg.ext_expressions):
		out.append(_expr_row("%s(%s)" % [key, _kinds(reg.ext_expressions[key])], reg.ext_expressions[key]))
	out.append("")

	out.append("## %s" % GdeI18n.t("Поведения"))
	out.append("")
	for b: String in _sorted(reg.behaviors):
		var be: Dictionary = reg.behaviors[b]
		out.append("### %s — %s" % [b, be.get("title", b)])
		out.append("")
		if str(be.get("description", "")) != "":
			out.append(str(be["description"]))
			out.append("")
		for kind: String in ["conditions", "actions"]:
			var table: Dictionary = be.get(kind, {})
			if table.is_empty():
				continue
			out.append("**%s**" % (GdeI18n.t("Условия") if kind == "conditions" else GdeI18n.t("Действия")))
			out.append("")
			for m: String in _sorted(table):
				_entry(out, "%s::%s" % [b, m], table[m])
		var ex: Dictionary = be.get("expressions", {})
		if not ex.is_empty():
			out.append("**%s**" % GdeI18n.t("Выражения"))
			out.append("")
			for e: String in _sorted(ex):
				out.append("- `%s.%s::%s(%s)` — %s" % [GdeI18n.t("Объект"), b, e, _kinds(ex[e]), str((ex[e] as Dictionary).get("description", ""))])
			out.append("")
	return "\n".join(out) + "\n"


static func _instructions(out: Array[String], title: String, table: Dictionary) -> void:
	out.append("## %s" % title)
	out.append("")
	var groups: Dictionary = {}
	for id: String in table:
		var g := str((table[id] as Dictionary).get("group", ""))
		if not groups.has(g):
			groups[g] = []
		(groups[g] as Array).append(id)
	for g2: String in _sorted(groups):
		out.append("### %s" % (g2 if g2 != "" else GdeI18n.t("Прочее")))
		out.append("")
		var ids: Array = groups[g2]
		ids.sort()
		for id2: String in ids:
			_entry(out, id2, table[id2])


static func _entry(out: Array[String], id: String, d: Dictionary) -> void:
	var s := str(d.get("sentence", id))
	var params: Array = d.get("params", [])
	for i in range(params.size()):
		s = s.replace("_PARAM%d_" % i, "‹%s›" % str((params[i] as Dictionary).get("label", "")))
	out.append("- **%s** — `%s`" % [s, id])
	var desc := str(d.get("description", ""))
	if desc != "":
		out.append("  %s" % desc)
	if not params.is_empty():
		var parts: Array[String] = []
		for p: Dictionary in params:
			parts.append("%s (%s)" % [p.get("label", ""), _kind_name(str(p.get("kind", "number")))])
		out.append("  %s %s" % [GdeI18n.t("Параметры:"), ", ".join(parts)])
	out.append("")


static func _expr_row(call: String, d: Dictionary) -> String:
	var t := GdeI18n.t("текст") if str(d.get("type", "number")) == "string" else GdeI18n.t("число")
	return "| `%s` | %s | %s |" % [call, t, str(d.get("description", "")).replace("|", "\\|")]


static func _kinds(d: Dictionary) -> String:
	var ks: Array[String] = []
	for k: Variant in d.get("params", []):
		ks.append(str(k))
	return ", ".join(ks)


static func _kind_name(k: String) -> String:
	match k:
		"object":
			return GdeI18n.t("объект")
		"objname":
			return GdeI18n.t("имя объекта")
		"number":
			return GdeI18n.t("число")
		"string":
			return GdeI18n.t("текст")
		"raw":
			return GdeI18n.t("имя без кавычек")
		"varname":
			return GdeI18n.t("имя переменной")
		"cmpop":
			return "= ≠ < > ≤ ≥"
		"modop":
			return "= + - * /"
	return k


static func _sorted(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort()
	return keys


static func _anchor(title: String) -> String:
	return title.to_lower().replace(" ", "-")
