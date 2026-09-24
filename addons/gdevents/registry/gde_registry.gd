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

var conditions: Dictionary = {}
var actions: Dictionary = {}
var expressions: Dictionary = {}
var object_expressions: Dictionary = {}
var operators: Dictionary = {}
var behaviors: Dictionary = {}
var errors: Array[String] = []


static func load_default() -> GdeRegistry:
	var r := GdeRegistry.new()
	r.load_builtin(BUILTIN_PATH)
	for d: String in BEHAVIOR_DIRS:
		r.scan_behaviors(d)
	return r


func load_builtin(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append("не открывается %s" % path)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		errors.append("%s — некорректный JSON" % path)
		return
	var d: Dictionary = parsed
	conditions = d.get("conditions", {})
	actions = d.get("actions", {})
	expressions = d.get("expressions", {})
	object_expressions = d.get("object_expressions", {})
	operators = d.get("operators", {})


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
func _scan_behavior_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var src := f.get_as_text()
	f.close()
	if not src.contains("extends GdeBehavior"):
		return

	var bname := _default_behavior_name(path)
	var re_note := RegEx.create_from_string(
			"^\\s*##\\s*@(action|condition|expression|behavior|title|description|icon|target|needs|internal)\\b\\s*(.*)$")
	var re_doc := RegEx.create_from_string("^\\s*##\\s?(.*)$")
	var re_func := RegEx.create_from_string("^\\s*func\\s+([A-Za-z_]\\w*)\\s*\\(([^)]*)\\)")
	var re_export := RegEx.create_from_string(
			"^\\s*@export\\w*(?:\\([^)]*\\))?\\s+var\\s+([A-Za-z_]\\w*)\\s*(?::\\s*([\\w\\[\\], ]+?))?\\s*(?:=|$)")
	var re_group := RegEx.create_from_string("^\\s*@export_group\\s*\\(\\s*\"([^\"]*)\"")

	var entry := {
		"path": path, "actions": {}, "conditions": {}, "expressions": {},
		"properties": {}, "description": "", "icon": "behavior",
		"title": "", "target": "", "needs": [],
	}
	var pending_kind := ""
	var pending_text := ""
	var doc: Array[String] = []
	var group := ""
	var internal := false

	for raw_line: String in src.split("\n"):
		var m_note := re_note.search(raw_line)
		if m_note != null:
			var k := m_note.get_string(1)
			var v := m_note.get_string(2).strip_edges()
			match k:
				"behavior":
					bname = v
				"title":
					entry["title"] = v
				"description":
					entry["description"] = v
				"icon":
					entry["icon"] = v
				"target":
					entry["target"] = v
				"needs":
					(entry["needs"] as Array).append(_parse_need(v))
				"internal":
					internal = true
				_:
					pending_kind = k
					pending_text = v
			continue

		var m_doc := re_doc.search(raw_line)
		if m_doc != null:
			doc.append(m_doc.get_string(1).strip_edges())
			continue

		var m_group := re_group.search(raw_line)
		if m_group != null:
			group = m_group.get_string(1).strip_edges()
			doc.clear()
			internal = false
			continue

		var m_exp := re_export.search(raw_line)
		if m_exp != null:
			var pname := m_exp.get_string(1)
			var ptype := m_exp.get_string(2).strip_edges()
			entry["properties"][pname] = ptype
			if not internal:
				_add_property_members(entry, bname, pname, ptype, _doc_text(doc), group)
			pending_kind = ""
			doc.clear()
			internal = false
			continue

		var m_fn := re_func.search(raw_line)
		if m_fn != null:
			if pending_kind != "":
				_add_member(entry, bname, pending_kind, pending_text,
						m_fn.get_string(1), m_fn.get_string(2), _doc_text(doc))
			pending_kind = ""
			doc.clear()
			internal = false
			continue

		if not raw_line.strip_edges().is_empty():
			pending_kind = ""
			doc.clear()
			internal = false

	if str(entry["title"]).is_empty():
		entry["title"] = bname
	_retitle(entry, str(entry["title"]))

	if behaviors.has(bname):
		errors.append("поведение «%s» объявлено дважды: %s и %s"
				% [bname, (behaviors[bname] as Dictionary)["path"], path])
	behaviors[bname] = entry


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


static func _doc_text(doc: Array[String]) -> String:
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
		method: String, arglist: String, doc: String = "") -> void:
	var params: Array = [{"kind": "object", "label": "Объект"}]
	params.append_array(_parse_params(arglist))
	var call_args: Array[String] = []
	for i in range(1, params.size()):
		call_args.append("{%d}" % i)
	var argstr := ", ".join(call_args)
	var about := doc if not doc.is_empty() \
			else "Из поведения «%s»." % TITLE_MARK

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

	entry["actions"]["set_" + pname] = {
		"group": bname,
		"sentence": "Изменить «%s» у _PARAM0_ (%s): _PARAM1_ _PARAM2_" % [label, TITLE_MARK],
		"description": about,
		"weight": 1,
		"kind": "object",
		"params": [
			{"kind": "object", "label": "Объект"},
			{"kind": "modop", "label": "Знак"},
			{"kind": kind, "label": "Значение"},
		],
		"code": "Gde.beh_set({o}, \"%s\", \"%s\", Gde.beh_get({o}, \"%s\", \"%s\") {1~} {2})"
				% [bname, pname, bname, pname],
		"code_assign": "Gde.beh_set({o}, \"%s\", \"%s\", {2})" % [bname, pname],
	}
	entry["conditions"]["is_" + pname] = {
		"group": bname,
		"sentence": "«%s» у _PARAM0_ (%s) _PARAM1_ _PARAM2_" % [label, TITLE_MARK],
		"description": about,
		"weight": 1,
		"kind": "object",
		"params": [
			{"kind": "object", "label": "Объект"},
			{"kind": "cmpop", "label": "Знак"},
			{"kind": kind, "label": "Значение"},
		],
		"pred": "Gde.beh_get({o}, \"%s\", \"%s\") {1} {2}" % [bname, pname],
	}
	var getter := "Gde.beh_get({ctx}.first(\"{obj}\"), \"{beh}\", \"%s\"%s)" \
			% [pname, ", \"\"" if kind == "string" else ""]
	entry["expressions"][_pascal(pname)] = {
		"type": kind,
		"params": [],
		"description": "%s — настройка поведения." % label if doc.is_empty() else doc,
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
	var head := "Настройка поведения «%s»" % TITLE_MARK
	if not group.is_empty():
		head += ", раздел «%s»" % group
	if doc.is_empty():
		return head + "."
	return "%s. %s" % [head, doc]


static func _pascal(s: String) -> String:
	var out := ""
	for part: String in s.split("_", false):
		if not part.is_empty():
			out += part.substr(0, 1).to_upper() + part.substr(1)
	return out
