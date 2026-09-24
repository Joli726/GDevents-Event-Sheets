## Функции из событий: свои действия и условия без единой строки кода.
##
## Функция — событие листа вида
##   {"type": "function", "name": "Hurt", "kind": "action" | "condition",
##    "sentence": "Ранить _PARAM0_ на _PARAM1_", "description": "…",
##    "params": [{"name": "target", "kind": "object", "label": "Кого"},
##               {"name": "amount", "kind": "number", "label": "Сколько"}],
##    "children": [события — тело функции]}
## В окне выбора она стоит рядом со встроенными инструкциями (id «fn.Hurt»),
## доступна в своём листе и во всех, кто его подключил. Внутри тела параметр-
## объект — это отобранные экземпляры того объекта, что передали при вызове,
## а числа и тексты читаются как Variable(amount). Функция-условие отвечает
## действием «Вернуть: истина».
class_name GdeFunctions
extends RefCounted

const PREFIX := "fn."
const RETURN_TRUE := "fn.return_true"
const RETURN_FALSE := "fn.return_false"
const PARAM_KINDS := ["object", "number", "string"]


## Функции листа (и подключённых им листов, если лист раскрыт GdeInclude):
## [{"e": событие, "path": путь в листе, "include": путь подключения или []}].
static func collect(events: Variant, prefix: Array = [], include_path: Array = []) -> Array:
	var out: Array = []
	if not (events is Array):
		return out
	for i in range((events as Array).size()):
		var e: Variant = events[i]
		if not (e is Dictionary):
			continue
		var d: Dictionary = e
		var p := prefix + [i]
		match str(d.get("type", "standard")):
			"function":
				if not d.get("disabled", false):
					out.append({"e": d, "path": p, "include": include_path})
			"group":
				out.append_array(collect(d.get("children", []), p, include_path))
			"include":
				out.append_array(collect(d.get("_events", []), p, include_path if not include_path.is_empty() else p))
	return out


## Описания для реестра: {"conditions": {id: def}, "actions": {id: def}}.
static func defs(fns: Array) -> Dictionary:
	var conds: Dictionary = {}
	var acts: Dictionary = {}
	var has_condition := false
	for f: Dictionary in fns:
		var e: Dictionary = f["e"]
		var name := str(e.get("name", ""))
		if not is_valid_name(name):
			continue
		var params: Array = []
		for p: Variant in e.get("params", []):
			if p is Dictionary:
				var pk := str((p as Dictionary).get("kind", "number"))
				params.append({"kind": pk if pk in PARAM_KINDS else "number",
						"label": str((p as Dictionary).get("label", (p as Dictionary).get("name", "")))})
		var sentence := str(e.get("sentence", "")).strip_edges()
		if sentence.is_empty():
			sentence = name
			for i in range(params.size()):
				sentence += " _PARAM%d_" % i
		var def := {
			"group": GdeI18n.t("Функции листа"),
			"sentence": sentence,
			"description": str(e.get("description", "")) if str(e.get("description", "")) != "" \
					else GdeI18n.t("Своя функция «%s» из событий листа.") % name,
			"kind": "global",
			"params": params,
			"function": name,
			"icon": "function",
		}
		if str(e.get("kind", "action")) == "condition":
			conds[PREFIX + name] = def
			has_condition = true
		else:
			acts[PREFIX + name] = def
	if has_condition:
		acts[RETURN_TRUE] = {"group": GdeI18n.t("Функции листа"), "sentence": GdeI18n.t("Вернуть: условие истинно"),
				"description": GdeI18n.t("Только внутри функции-условия: условие, которое её вызвало, выполнено."),
				"kind": "global", "params": [], "icon": "function", "code": "_gde_ret = true"}
		acts[RETURN_FALSE] = {"group": GdeI18n.t("Функции листа"), "sentence": GdeI18n.t("Вернуть: условие ложно"),
				"description": GdeI18n.t("Только внутри функции-условия: условие, которое её вызвало, не выполнено. Так и по умолчанию."),
				"kind": "global", "params": [], "icon": "function", "code": "_gde_ret = false"}
	return {"conditions": conds, "actions": acts}


## Описания функций для листа как есть (с раскрытием подключений) — для редактора.
static func defs_for_sheet(sheet: Dictionary, source_path: String) -> Dictionary:
	var data := sheet
	if GdeInclude.has_includes(sheet.get("events", [])):
		data = GdeInclude.expand(sheet, source_path)
	return defs(collect(data.get("events", [])))


static func is_valid_name(name: String) -> bool:
	return name.is_valid_ascii_identifier()


## Имя метода в собранном скрипте.
static func method_name(name: String) -> String:
	return "_gdefn_%s" % name
