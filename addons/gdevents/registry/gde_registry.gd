## Реестр инструкций GDevents.
##
## Складывает вместе встроенную библиотеку (builtin.json) и поведения,
## отсканированные из .gd-файлов. Единственный источник правды по поведению —
## сам его исходник: свойства берутся из @export, действия/условия/выражения —
## из комментариев ## @action / ## @condition / ## @expression.
class_name GdeRegistry
extends RefCounted

const BUILTIN_PATH := "res://addons/gdevents/registry/builtin.json"
const BEHAVIOR_DIRS := ["res://addons/gdevents/behaviors", "res://behaviors"]
## Расширения — свои условия, действия и выражения без поведения.
const EXTENSION_DIRS := ["res://addons/gdevents/extensions", "res://extensions"]

var conditions: Dictionary = {}
var actions: Dictionary = {}
var expressions: Dictionary = {}
var object_expressions: Dictionary = {}
var operators: Dictionary = {}
var behaviors: Dictionary = {}
## имя расширения -> {"path", "title", "description", "icon", "untranslated",
## "conditions", "actions", "expressions"}. Условия и действия расширений
## лежат и в общих conditions/actions под именами «Расширение::функция».
var extensions: Dictionary = {}
## «Clock::Hour» -> описание выражения расширения.
var ext_expressions: Dictionary = {}
var errors: Array[String] = []


static func load_default() -> GdeRegistry:
	var r := GdeRegistry.new()
	r.load_builtin(BUILTIN_PATH)
	for d: String in BEHAVIOR_DIRS:
		r.scan_behaviors(d)
	for d2: String in EXTENSION_DIRS:
		r.scan_extensions(d2)
	return r


func load_builtin(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append(GdeI18n.t("не открывается %s") % path)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		errors.append(GdeI18n.t("%s — некорректный JSON") % path)
		return
	var d: Dictionary = parsed
	conditions = d.get("conditions", {})
	actions = d.get("actions", {})
	expressions = d.get("expressions", {})
	object_expressions = d.get("object_expressions", {})
	operators = d.get("operators", {})
	_localize_builtin()


## Тексты встроенной библиотеки написаны по-русски и переводятся по общему
## словарю i18n/<язык>.json — так же, как интерфейс. Шаблоны кода не трогаем.
func _localize_builtin() -> void:
	for table: Dictionary in [conditions, actions]:
		for id: String in table:
			var def: Dictionary = table[id]
			for field: String in ["sentence", "description", "group"]:
				if def.has(field):
					def[field] = GdeI18n.t(str(def[field]))
			for p: Variant in def.get("params", []):
				if p is Dictionary and (p as Dictionary).has("label"):
					(p as Dictionary)["label"] = GdeI18n.t(str((p as Dictionary)["label"]))
	for table2: Dictionary in [expressions, object_expressions]:
		for id2: String in table2:
			var def2: Dictionary = table2[id2]
			if def2.has("description"):
				def2["description"] = GdeI18n.t(str(def2["description"]))


# ----------------------------------------------------------------- запросы ---

func condition(id: String) -> Variant:
	if conditions.has(id):
		return conditions[id]
	return _behavior_member(id, "conditions")


func action(id: String) -> Variant:
	if actions.has(id):
		return actions[id]
	return _behavior_member(id, "actions")


func free_expr(name: String) -> Variant:
	if expressions.has(name):
		var d: Dictionary = (expressions[name] as Dictionary).duplicate()
		d["name"] = name
		return d
	return null


func object_expr(name: String) -> Variant:
	if object_expressions.has(name):
		var d: Dictionary = (object_expressions[name] as Dictionary).duplicate()
		d["name"] = name
		return d
	return null


## Выражение расширения: Clock::Hour().
func ext_expr(ext: String, name: String) -> Variant:
	var key := "%s::%s" % [ext, name]
	if not ext_expressions.has(key):
		return null
	var d: Dictionary = (ext_expressions[key] as Dictionary).duplicate()
	d["name"] = key
	return d


func behavior_expr(beh: String, name: String) -> Variant:
	var b: Variant = behaviors.get(beh)
	if b == null:
		return null
	var table: Dictionary = (b as Dictionary).get("expressions", {})
	if not table.has(name):
		return null
	var d: Dictionary = (table[name] as Dictionary).duplicate()
	d["name"] = "%s::%s" % [beh, name]
	return d


## id вида "Shoot::fire" — член поведения.
func _behavior_member(id: String, table: String) -> Variant:
	var parts := id.split("::", false)
	if parts.size() != 2:
		return null
	var b: Variant = behaviors.get(parts[0])
	if b == null:
		return null
	var t: Dictionary = (b as Dictionary).get(table, {})
	return t.get(parts[1])


## Перевести знак из листа в оператор GDScript.
func resolve_op(kind: String, token: String) -> String:
	var table: Dictionary = operators.get(kind, {})
	if table.has(token):
		return table[token]
	return ""


# ------------------------------------------------------- сканер поведений ---

func scan_behaviors(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for f: String in _gd_files(dir_path):
		_scan_behavior_file(f)


func scan_extensions(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for f: String in _gd_files(dir_path):
		_scan_behavior_file(f, true)


func _gd_files(root: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(root)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := root.path_join(name)
		if d.current_is_dir():
			if not name.begins_with("."):
				out.append_array(_gd_files(full))
		elif name.ends_with(".gd"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
	return out


## Разбор одного файла поведения.
##
## Главный источник понятных названий — обычные ##-комментарии. Godot и так
## показывает их подсказками в инспекторе, так что писать их всё равно надо;
## реестр просто перестал их выбрасывать. Из-за этого раньше в списке событий
## стояло «Свойство acceleration у Player (Platformer)» — строка, которая
## ничего не объясняет.
func _scan_behavior_file(path: String, extension: bool = false) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var src := f.get_as_text()
	f.close()
	if not src.contains("extends GdeExtension" if extension else "extends GdeBehavior"):
		return

	var bname := _default_behavior_name(path)
	# Любую метку можно продублировать на другом языке: @title.en, @action.en…
	var re_note := RegEx.create_from_string(
			"^\\s*##\\s*@(action|condition|expression|behavior|extension|title|description|icon|target|needs|internal|param|options|group)(?:\\.([a-z]{2}))?(?=\\s|$)\\s*(.*)$")
	var re_doc := RegEx.create_from_string("^\\s*##\\s?(.*)$")
	# Строка описания на другом языке: «## @en Maximum speed.»
	var re_doc_lang := RegEx.create_from_string("^@([a-z]{2})\\s+(.*)$")
	# У расширений функции статические, а тип результата решает, число
	# выражение или текст.
	var re_func := RegEx.create_from_string(
			"^\\s*(?:static\\s+)?func\\s+([A-Za-z_]\\w*)\\s*\\(([^)]*)\\)\\s*(?:->\\s*([\\w\\[\\]]+))?")
	var re_export := RegEx.create_from_string(
			"^\\s*@export\\w*(?:\\([^)]*\\))?\\s+var\\s+([A-Za-z_]\\w*)\\s*(?::\\s*([\\w\\[\\], ]+?))?\\s*(?:=|$)")
	var re_group := RegEx.create_from_string("^\\s*@export_group\\s*\\(\\s*\"([^\"]*)\"")
	# Аннотация на своей строке, а var — на следующей:
	#   @export_enum("Свои настройки", "Пистолет")
	#   var preset: int = 1
	var re_split_export := RegEx.create_from_string("^\\s*@export\\w*(?:\\([^)]*\\))?\\s*$")
	var re_var := RegEx.create_from_string("^\\s*var\\s+([A-Za-z_]\\w*)")

	var entry := {
		"path": path, "actions": {}, "conditions": {}, "expressions": {},
		"properties": {}, "description": "", "icon": "behavior",
		"title": "", "target": "", "needs": [],
		## имя настройки -> {"label", "doc", "group", "internal", "options"} —
		## для окна настроек поведения. В отличие от действий, тут все @export,
		## и сложные тоже: сцена снаряда настраивается там же, где скорость.
		"settings": {},
		## @export_group как в коде -> название на выбранном языке.
		"group_names": {},
		## язык -> тексты без перевода на него (для i18n_test).
		"untranslated": {},
	}
	var title := {}
	var about := {}
	var needs := {}
	var pending_kind := ""
	var pending_text := {}
	var params := {}
	var options := {}
	var group_title := {}
	var doc := {}
	var group := ""
	var internal := false
	var split_export := false

	for raw_line: String in src.split("\n"):
		var m_note := re_note.search(raw_line)
		if m_note != null:
			var k := m_note.get_string(1)
			var lang := m_note.get_string(2)
			var v := m_note.get_string(3).strip_edges()
			match k:
				"behavior", "extension":
					bname = v
				"title":
					title[lang] = v
				"description":
					about[lang] = v
				"icon":
					entry["icon"] = v
				"target":
					entry["target"] = v
				"needs":
					if not needs.has(lang):
						needs[lang] = []
					(needs[lang] as Array).append(v)
				"internal":
					internal = true
				"param":
					# «@param force Сила толчка» — подпись параметра действия.
					var sp := v.split(" ", false, 1)
					if sp.size() == 2:
						if not params.has(sp[0]):
							params[sp[0]] = {}
						(params[sp[0]] as Dictionary)[lang] = sp[1].strip_edges()
				"options":
					var items: Array[String] = []
					for o: String in v.split(","):
						items.append(o.strip_edges())
					options[lang] = items
				"group":
					group_title[lang] = v
				_:
					pending_kind = k
					pending_text[lang] = v
			continue

		var m_doc := re_doc.search(raw_line)
		if m_doc != null:
			var line := m_doc.get_string(1).strip_edges()
			var lang2 := ""
			var m_lang := re_doc_lang.search(line)
			if m_lang != null and GdeI18n.LANGUAGES.has(m_lang.get_string(1)):
				lang2 = m_lang.get_string(1)
				line = m_lang.get_string(2).strip_edges()
			if not doc.has(lang2):
				doc[lang2] = []
			(doc[lang2] as Array).append(line)
			continue

		var m_group := re_group.search(raw_line)
		if m_group != null:
			group = m_group.get_string(1).strip_edges()
			group_title[""] = group
			(entry["group_names"] as Dictionary)[group] = _pick(entry, "group " + group, group_title)
			group_title = {}
			doc.clear()
			internal = false
			continue

		if split_export:
			split_export = false
			var m_var := re_var.search(raw_line)
			if m_var != null:
				# Только в окно настроек: в библиотеку событий такие свойства
				# не попадали и раньше — пресет без «применить» ничего не делает.
				_add_setting(entry, m_var.get_string(1), _pick_doc(entry, m_var.get_string(1), doc),
						group, internal, _pick_list(options))
				pending_kind = ""
				doc.clear()
				options = {}
				internal = false
				continue

		var m_exp := re_export.search(raw_line)
		if m_exp != null:
			var pname := m_exp.get_string(1)
			var ptype := m_exp.get_string(2).strip_edges()
			var pdoc := _pick_doc(entry, pname, doc)
			entry["properties"][pname] = ptype
			_add_setting(entry, pname, pdoc, group, internal, _pick_list(options))
			if not internal:
				_add_property_members(entry, bname, pname, ptype, pdoc,
						str((entry["group_names"] as Dictionary).get(group, group)))
			pending_kind = ""
			doc.clear()
			options = {}
			internal = false
			continue

		if re_split_export.search(raw_line) != null:
			split_export = true
			continue

		var m_fn := re_func.search(raw_line)
		if m_fn != null:
			if pending_kind != "":
				var labels := {}
				for pn: String in params:
					labels[pn] = _pick(entry, "@param " + pn, params[pn])
				var sentence := _pick(entry, m_fn.get_string(1), pending_text)
				var fdoc := _pick_doc(entry, m_fn.get_string(1), doc)
				if extension:
					_add_ext_member(entry, bname, pending_kind, sentence, m_fn.get_string(1),
							m_fn.get_string(2), m_fn.get_string(3), fdoc, labels)
				else:
					_add_member(entry, bname, pending_kind, sentence,
							m_fn.get_string(1), m_fn.get_string(2), fdoc, labels)
			pending_kind = ""
			pending_text = {}
			params = {}
			doc.clear()
			internal = false
			continue

		if not raw_line.strip_edges().is_empty():
			pending_kind = ""
			pending_text = {}
			params = {}
			options = {}
			doc.clear()
			internal = false

	entry["title"] = _pick(entry, "@title", title) if not title.is_empty() else ""
	entry["description"] = _pick(entry, "@description", about) if not about.is_empty() else ""
	var lang_needs: Array = needs.get(GdeI18n.language(), needs.get("", []))
	if lang_needs.size() != (needs.get("", []) as Array).size():
		lang_needs = needs.get("", [])
	for nd: String in lang_needs:
		(entry["needs"] as Array).append(_parse_need(nd))
	if str(entry["title"]).is_empty():
		entry["title"] = bname
	if extension:
		_register_extension(entry, bname)
		return
	_retitle(entry, str(entry["title"]))

	# Своя копия встроенного поведения в res://behaviors — не дубль, а замена:
	# работает она, а встроенная остаётся «дефолтом», к которому можно вернуться.
	entry["builtin_path"] = path if path.begins_with(BEHAVIOR_DIRS[0] + "/") else ""
	if behaviors.has(bname):
		var prev := str((behaviors[bname] as Dictionary)["path"])
		if prev.begins_with(BEHAVIOR_DIRS[0] + "/") and path.begins_with(BEHAVIOR_DIRS[1] + "/"):
			entry["builtin_path"] = prev
		else:
			errors.append(GdeI18n.t("поведение «%s» объявлено дважды: %s и %s") % [bname, prev, path])
	behaviors[bname] = entry


static func _add_setting(entry: Dictionary, pname: String, doc: String, group: String,
		internal: bool, options: Array = []) -> void:
	(entry["settings"] as Dictionary)[pname] = {
		"label": _label_from_doc(doc, ""),
		"doc": doc,
		"group": group,
		"internal": internal,
		# Названия пунктов @export_enum на выбранном языке; пусто — как в коде.
		"options": options,
	}


## Текст на выбранном языке из вариантов {"": основной, "en": …, "ru": …}.
## Чего не хватает, записывается в entry["untranslated"] — i18n_test следит,
## чтобы у встроенных поведений перевод был у всего.
static func _pick(entry: Dictionary, what: String, variants: Dictionary) -> String:
	var miss: Dictionary = entry["untranslated"]
	for lang: String in GdeI18n.LANGUAGES:
		if not variants.has(lang):
			if not miss.has(lang):
				miss[lang] = []
			(miss[lang] as Array).append(what)
	return GdeI18n.pick(variants)


## Описание из ##-строк: основные строки и «## @en …» — отдельно.
static func _pick_doc(entry: Dictionary, what: String, doc: Dictionary) -> String:
	var variants := {}
	for lang: String in doc:
		variants[lang] = _doc_text(doc[lang])
	if not variants.has("") or str(variants[""]).is_empty():
		return str(GdeI18n.pick(variants))
	return _pick(entry, what, variants)


## Пункты @options на выбранном языке. Пусто — остаются как в @export_enum.
static func _pick_list(options: Dictionary) -> Array:
	return options.get(GdeI18n.language(), [])


# ------------------------------------------------------------ расширения ---

## Типы, которые делают параметр объектом листа: инструкция тогда работает
## с отобранными экземплярами, а в функцию приходит сам экземпляр.
static func _is_node_type(ty: String) -> bool:
	return ty == "Node" or (ClassDB.class_exists(ty) and ClassDB.is_parent_class(ty, "Node"))


## Условие, действие или выражение расширения из статической функции.
func _add_ext_member(entry: Dictionary, ename: String, kind: String, sentence: String,
		method: String, arglist: String, ret: String, doc: String, labels: Dictionary) -> void:
	var params: Array = []
	var call: Array[String] = []
	var kinds: Array = []
	var on_object := false
	var i := 0
	for a: String in arglist.split(",", false):
		var s := a.strip_edges()
		if s.is_empty():
			continue
		var nm := s.split(":")[0].split("=")[0].strip_edges()
		var ty := s.split(":")[1].split("=")[0].strip_edges() if s.contains(":") else "float"
		var label: String = labels.get(nm, nm)
		if _is_node_type(ty):
			if i != 0 or kind == "expression":
				errors.append(GdeI18n.t("расширение «%s», %s(): объект может быть только первым параметром условия или действия")
						% [ename, method])
				return
			on_object = true
			params.append({"kind": "object", "label": labels.get(nm, GdeI18n.t("Объект"))})
			call.append("{o}")
		elif ty == "String" or ty == "StringName":
			params.append({"kind": "string", "label": label})
			kinds.append("string")
			call.append("{%d}" % i)
		else:
			params.append({"kind": "number", "label": label})
			kinds.append("number")
			# Из листа приходят числа — к типу параметра приводим сами.
			call.append(("bool({%d})" if ty == "bool" else ("int({%d})" if ty == "int" else "{%d}")) % i)
		i += 1
	var target := "preload(\"%s\").%s(%s)" % [str(entry["path"]), method, ", ".join(call)]
	match kind:
		"action":
			entry["actions"][method] = {
				"sentence": sentence, "description": doc, "params": params,
				"kind": "object" if on_object else "global",
				"code": target,
			}
		"condition":
			var d := {
				"sentence": sentence, "description": doc, "params": params,
				"kind": "object" if on_object else "global",
			}
			d["pred" if on_object else "code"] = "bool(%s)" % target
			entry["conditions"][method] = d
		"expression":
			var is_text := ret == "String" or ret == "StringName"
			entry["expressions"][_pascal(method)] = {
				"type": "string" if is_text else "number",
				"params": kinds,
				"description": sentence if doc.is_empty() else doc,
				"template": ("str(%s)" if is_text else "float(%s)") % target,
			}


## Расширение — в общие таблицы: его условия и действия видны в окне выбора
## и в генераторе так же, как встроенные, под именами «Расширение::функция».
func _register_extension(entry: Dictionary, ename: String) -> void:
	if extensions.has(ename) or behaviors.has(ename):
		errors.append(GdeI18n.t("расширение «%s» объявлено дважды: %s и %s")
				% [ename, str((extensions.get(ename, behaviors.get(ename, {})) as Dictionary).get("path", "")), entry["path"]])
		return
	extensions[ename] = entry
	for table: String in ["conditions", "actions"]:
		var target: Dictionary = conditions if table == "conditions" else actions
		for m: String in (entry[table] as Dictionary):
			var d: Dictionary = entry[table][m]
			d["group"] = entry["title"]
			d["icon"] = entry["icon"]
			d["extension"] = ename
			target["%s::%s" % [ename, m]] = d
	for e: String in (entry["expressions"] as Dictionary):
		ext_expressions["%s::%s" % [ename, e]] = entry["expressions"][e]


## Английское имя поведения нужно только коду. В глаза пользователю должно
## смотреть русское из @title — и в заголовке группы, и внутри фраз.
const TITLE_MARK := "__BEHAVIOR_TITLE__"

func _retitle(entry: Dictionary, title: String) -> void:
	for table: String in ["actions", "conditions"]:
		var t: Dictionary = entry[table]
		for id: String in t:
			var d: Dictionary = t[id]
			d["group"] = title
			d["sentence"] = str(d["sentence"]).replace(TITLE_MARK, title)
			if d.has("description"):
				d["description"] = str(d["description"]).replace(TITLE_MARK, title)


static func _doc_text(doc: Array) -> String:
	var parts: Array[String] = []
	for line: String in doc:
		if not line.is_empty():
			parts.append(line)
	return " ".join(parts)


## «CollisionShape2D Форма столкновения» -> {"type", "any", "name"}.
## Через | перечисляются равноценные варианты: «Sprite2D|AnimatedSprite2D»
## значит «нужен хоть какой-то спрайт», а создаётся первый из списка.
static func _parse_need(v: String) -> Dictionary:
	var sp := v.split(" ", false, 1)
	var cls := sp[0].strip_edges() if sp.size() > 0 else ""
	var alts: Array[String] = []
	for a: String in cls.split("|", false):
		if not a.strip_edges().is_empty():
			alts.append(a.strip_edges())
	var first := alts[0] if not alts.is_empty() else ""
	var nm := sp[1].strip_edges() if sp.size() > 1 else first
	return {"type": first, "any": alts, "name": nm}


func _default_behavior_name(path: String) -> String:
	var base := path.get_file().get_basename()
	var out := ""
	for part: String in base.split("_", false):
		if not part.is_empty():
			out += part.substr(0, 1).to_upper() + part.substr(1)
	return out


## Параметры метода -> виды параметров инструкции.
func _parse_params(arglist: String) -> Array:
	var out: Array = []
	for a: String in arglist.split(",", false):
		var s := a.strip_edges()
		if s.is_empty():
			continue
		var nm := s
		var ty := "float"
		if s.contains(":"):
			var bits := s.split(":", false, 1)
			nm = bits[0].strip_edges()
			ty = bits[1].split("=")[0].strip_edges()
		out.append({"kind": _kind_of(ty), "label": nm})
	return out


func _kind_of(gdtype: String) -> String:
	match gdtype:
		"String", "StringName":
			return "string"
		_:
			return "number"


func _add_member(entry: Dictionary, bname: String, kind: String, sentence: String,
		method: String, arglist: String, doc: String = "", labels: Dictionary = {}) -> void:
	var params: Array = [{"kind": "object", "label": GdeI18n.t("Объект")}]
	for p: Dictionary in _parse_params(arglist):
		# Подпись из @param вместо имени аргумента: «Сила», а не ‹force›.
		if labels.has(p["label"]):
			p["label"] = labels[p["label"]]
		params.append(p)
	var call_args: Array[String] = []
	for i in range(1, params.size()):
		call_args.append("{%d}" % i)
	var argstr := ", ".join(call_args)
	var about := doc if not doc.is_empty() \
			else GdeI18n.t("Из поведения «%s».") % TITLE_MARK

	match kind:
		"action":
			entry["actions"][method] = {
				"group": bname,
				"sentence": sentence,
				"description": about,
				"icon": str(entry.get("icon", "behavior")),
				"kind": "object",
				"params": params,
				"code": "Gde.beh_call({o}, \"%s\", \"%s\", [%s])" % [bname, method, argstr],
			}
		"condition":
			entry["conditions"][method] = {
				"group": bname,
				"sentence": sentence,
				"description": about,
				"icon": str(entry.get("icon", "behavior")),
				"kind": "object",
				"params": params,
				"pred": "Gde.beh_bool({o}, \"%s\", \"%s\", [%s])" % [bname, method, argstr],
			}
		"expression":
			var ex_params: Array = []
			for p: Dictionary in _parse_params(arglist):
				ex_params.append(p["kind"])
			var ex_args: Array[String] = []
			for i in range(ex_params.size()):
				ex_args.append("{%d}" % i)
			entry["expressions"][_pascal(method)] = {
				"type": "number",
				"params": ex_params,
				"description": sentence if doc.is_empty() else doc,
				"template": "float(Gde.beh_val({ctx}.first(\"{obj}\"), \"{beh}\", \"%s\", [%s]))"
						% [method, ", ".join(ex_args)],
			}


## Простые @export-свойства бесплатно дают действие, условие и выражение.
## Сложные (PackedScene, Texture2D, ресурсы) остаются только в инспекторе:
## в редакторе событий их всё равно нечем осмысленно заполнить.
const SCALAR_TYPES := ["float", "int", "bool", "String", "StringName", ""]

func _add_property_members(entry: Dictionary, bname: String, pname: String,
		ptype: String, doc: String = "", group: String = "") -> void:
	if not SCALAR_TYPES.has(ptype):
		return
	var kind := _kind_of(ptype)
	var label := _label_from_doc(doc, pname)
	# Понятные названия свойств нужны и проверке сцен: «нет анимации для
	# «Анимация подъёма в прыжке»» понятнее, чем «jump_animation».
	if not entry.has("labels"):
		entry["labels"] = {}
	(entry["labels"] as Dictionary)[pname] = label
	var about := _property_about(doc, group)
	# Чтение свойства в шаблонах. Строке нужен запасной "" — иначе на объекте
	# без поведения приходил 0.0 и сравнение со строкой падало. Галочку
	# читаем числом: в листе она 1 или 0, а «true == 1.0» в Godot — ошибка.
	var read := "Gde.beh_get({o}, \"%s\", \"%s\"%s)" % [bname, pname, ", \"\"" if kind == "string" else ""]
	if ptype == "bool":
		read = "float(%s)" % read

	entry["actions"]["set_" + pname] = {
		"group": bname,
		"sentence": GdeI18n.t("Изменить «%s» у _PARAM0_ (%s): _PARAM1_ _PARAM2_") % [label, TITLE_MARK],
		"description": about,
		"weight": 1,
		"kind": "object",
		"params": [
			{"kind": "object", "label": GdeI18n.t("Объект")},
			{"kind": "modop", "label": GdeI18n.t("Знак")},
			{"kind": kind, "label": GdeI18n.t("Значение")},
		],
		"code": "Gde.beh_set({o}, \"%s\", \"%s\", %s {1~} {2})" % [bname, pname, read],
		"code_assign": "Gde.beh_set({o}, \"%s\", \"%s\", {2})" % [bname, pname],
	}
	entry["conditions"]["is_" + pname] = {
		"group": bname,
		"sentence": GdeI18n.t("«%s» у _PARAM0_ (%s) _PARAM1_ _PARAM2_") % [label, TITLE_MARK],
		"description": about,
		"weight": 1,
		"kind": "object",
		"params": [
			{"kind": "object", "label": GdeI18n.t("Объект")},
			{"kind": "cmpop", "label": GdeI18n.t("Знак")},
			{"kind": kind, "label": GdeI18n.t("Значение")},
		],
		"pred": "%s {1} {2}" % read,
	}
	var getter := "Gde.beh_get({ctx}.first(\"{obj}\"), \"{beh}\", \"%s\"%s)" \
			% [pname, ", \"\"" if kind == "string" else ""]
	entry["expressions"][_pascal(pname)] = {
		"type": kind,
		"params": [],
		"description": GdeI18n.t("%s — настройка поведения.") % label if doc.is_empty() else doc,
		"template": ("str(%s)" if kind == "string" else "float(%s)") % getter,
	}


## Короткое название свойства из его ##-описания: первая мысль до точки,
## запятой или тире. «Как быстро набирается скорость. Больше — резче старт.»
## превращается в «Как быстро набирается скорость».
static func _label_from_doc(doc: String, fallback: String) -> String:
	var s := doc.strip_edges()
	if s.is_empty():
		return fallback
	var cut := -1
	for sep: String in [". ", ", ", " — ", ": ", "; ", " ("]:
		var i := s.find(sep)
		if i > 0 and (cut < 0 or i < cut):
			cut = i
	if cut > 0:
		s = s.substr(0, cut)
	s = s.trim_suffix(".").strip_edges()
	if s.length() > 44 or s.is_empty():
		return fallback
	return s


static func _property_about(doc: String, group: String) -> String:
	var head := GdeI18n.t("Настройка поведения «%s»") % TITLE_MARK
	if not group.is_empty():
		head += GdeI18n.t(", раздел «%s»") % group
	if doc.is_empty():
		return head + "."
	return "%s. %s" % [head, doc]


static func _pascal(s: String) -> String:
	var out := ""
	for part: String in s.split("_", false):
		if not part.is_empty():
			out += part.substr(0, 1).to_upper() + part.substr(1)
	return out
