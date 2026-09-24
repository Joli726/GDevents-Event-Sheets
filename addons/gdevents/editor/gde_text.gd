## Рендеринг фраз инструкций — того самого, что видно в листе событий.
class_name GdeText
extends RefCounted


## Фраза с подставленными названиями параметров — для списка выбора.
## «Изменить X у _PARAM0_: _PARAM1_ _PARAM2_» -> «Изменить X у ‹Объект›: ‹Знак› ‹Значение›»
## object_name — если задан, первый параметр-объект показывается именем,
## а не заглушкой: в пикере объект уже выбран слева, и фраза читается целиком.
static func with_labels(def: Dictionary, object_name: String = "") -> String:
	var s := str(def.get("sentence", ""))
	var params: Array = def.get("params", [])
	var object_used := false
	for i in range(params.size()):
		var pd: Dictionary = params[i]
		var shown: String
		if not object_used and not object_name.is_empty() \
				and str(pd.get("kind", "")) == "object":
			shown = object_name
			object_used = true
		else:
			shown = "‹%s›" % str(pd.get("label", "…"))
		s = s.replace("_PARAM%d_" % i, shown)
	return s


## Фраза с реальными значениями, в BBCode: параметры подсвечены.
static func with_values(def: Variant, inst: Dictionary, param_color: Color) -> String:
	var id := str(inst.get("id", ""))
	if def == null:
		return "[color=#e05555]неизвестная инструкция «%s»[/color]" % _esc(id)
	var d: Dictionary = def
	var s := _esc(str(d.get("sentence", id)))
	var raw: Array = inst.get("params", [])
	var defs: Array = d.get("params", [])
	var hex := param_color.to_html(false)
	for i in range(defs.size()):
		var value := str(raw[i]) if i < raw.size() else ""
		var shown := value if not value.strip_edges().is_empty() \
				else "‹%s›" % str((defs[i] as Dictionary).get("label", "…"))
		s = s.replace("_PARAM%d_" % i, "[color=#%s]%s[/color]" % [hex, _esc(shown)])
	return s


## Заголовок специального события для шапки строки.
static func event_title(e: Dictionary) -> String:
	match str(e.get("type", "standard")):
		"group":
			return str(e.get("name", "Группа"))
		"foreach":
			var o := str(e.get("object", ""))
			return "Для каждого объекта %s" % (o if not o.is_empty() else "‹не выбран›")
		"repeat":
			return "Повторить %s раз" % str(e.get("count", "1"))
		"while":
			return "Пока выполняется"
		_:
			return ""


static func _esc(s: String) -> String:
	return s.replace("[", "[lb]")
