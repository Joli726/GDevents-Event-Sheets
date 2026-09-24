## Общие листы: событие «Подключить лист» вставляет события другого листа.
##
## Управление игроком, пауза, счёт — пишутся один раз и подключаются к каждому
## уровню. Подключение раскрывается при сборке: события чужого листа
## собираются прямо на месте подключения, как будто их туда скопировали, а
## его объекты, группы и переменные добавляются к объектам листа-хозяина.
## Правка общего листа доходит до всех уровней со следующей сборкой.
class_name GdeInclude
extends RefCounted

## Сколько уровней подключений внутри подключений допускаем. Глубже — почти
## наверняка ошибка, а не замысел.
const MAX_DEPTH := 16


## Лист с раскрытыми подключениями. Исходный лист не меняется.
## Каждое событие {"type": "include"} получает "_events" (раскрытые события
## подключённого листа) или "_error" (почему подключить не вышло).
static func expand(sheet: Dictionary, source_path: String) -> Dictionary:
	var out := sheet.duplicate(true)
	var objects: Array = out.get("objects", [])
	out["objects"] = objects
	var groups: Dictionary = out.get("groups", {})
	var vars: Dictionary = out.get("variables", {})
	var ctx := {
		"objects": objects,
		"by_name": _by_name(objects),
		"groups": groups,
		"vars": vars,
	}
	out["events"] = _expand_events(out.get("events", []), [_norm(source_path)], ctx)
	if not groups.is_empty():
		out["groups"] = groups
	if not vars.is_empty():
		out["variables"] = vars
	return out


static func has_includes(events: Variant) -> bool:
	if not (events is Array):
		return false
	for e: Variant in events:
		if e is Dictionary:
			if str((e as Dictionary).get("type", "")) == "include":
				return true
			if has_includes((e as Dictionary).get("children", [])):
				return true
	return false


static func _expand_events(events: Variant, stack: Array, ctx: Dictionary) -> Array:
	var out: Array = []
	if not (events is Array):
		return out
	for e: Variant in events:
		if not (e is Dictionary):
			out.append(e)
			continue
		var d: Dictionary = e
		if d.has("children"):
			d["children"] = _expand_events(d["children"], stack, ctx)
		if str(d.get("type", "")) == "include" and not d.get("disabled", false):
			_expand_one(d, stack, ctx)
		out.append(d)
	return out


static func _expand_one(d: Dictionary, stack: Array, ctx: Dictionary) -> void:
	var path := _norm(str(d.get("sheet", "")))
	if path.is_empty():
		d["_error"] = GdeI18n.t("«Подключить лист»: не выбран лист")
		return
	if stack.has(path):
		d["_error"] = GdeI18n.t("«Подключить лист»: %s подключает сам себя по кругу (%s)") % [path.get_file(),
				" → ".join(stack.map(func(p: String) -> String: return p.get_file()) + [path.get_file()])]
		return
	if stack.size() > MAX_DEPTH:
		d["_error"] = GdeI18n.t("«Подключить лист»: слишком глубокая цепочка подключений")
		return
	if not FileAccess.file_exists(path):
		d["_error"] = GdeI18n.t("«Подключить лист»: листа %s нет") % path
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		d["_error"] = GdeI18n.t("«Подключить лист»: в %s некорректный JSON") % path
		return
	var m := GdeSheetFormat.migrate(parsed)
	if str(m["error"]) != "":
		d["_error"] = "«%s»: %s" % [path.get_file(), m["error"]]
		return
	var inc: Dictionary = m["data"]
	var err := _merge(inc, path, ctx)
	if err != "":
		d["_error"] = err
		return
	d["_events"] = _expand_events((inc.get("events", []) as Array).duplicate(true), stack + [path], ctx)


## Объекты, группы и переменные подключённого листа — к листу-хозяину.
## Один и тот же объект с той же сценой — не конфликт; с другой сценой —
## ошибка: иначе одно имя значило бы разные вещи в разных частях листа.
static func _merge(inc: Dictionary, path: String, ctx: Dictionary) -> String:
	var by_name: Dictionary = ctx["by_name"]
	for o: Variant in inc.get("objects", []):
		if not (o is Dictionary):
			continue
		var name := str((o as Dictionary).get("name", ""))
		var scene := str((o as Dictionary).get("scene", ""))
		if by_name.has(name):
			if str(by_name[name]) != scene:
				return GdeI18n.t("«Подключить лист»: объект «%s» в %s — сцена %s, а в этом листе — %s") % [
						name, path.get_file(), scene, by_name[name]]
			continue
		by_name[name] = scene
		(ctx["objects"] as Array).append({"name": name, "scene": scene})
	var groups: Dictionary = ctx["groups"]
	var ig: Variant = inc.get("groups", {})
	if ig is Dictionary:
		for g: Variant in (ig as Dictionary):
			if not groups.has(g):
				groups[g] = (ig as Dictionary)[g]
	var vars: Dictionary = ctx["vars"]
	var iv: Variant = inc.get("variables", {})
	if iv is Dictionary:
		for k: Variant in (iv as Dictionary):
			if not vars.has(k):
				vars[k] = (iv as Dictionary)[k]
	return ""


static func _by_name(objects: Array) -> Dictionary:
	var out: Dictionary = {}
	for o: Variant in objects:
		if o is Dictionary:
			out[str((o as Dictionary).get("name", ""))] = str((o as Dictionary).get("scene", ""))
	return out


static func _norm(p: String) -> String:
	return p.strip_edges().simplify_path() if p.strip_edges() != "" else ""
