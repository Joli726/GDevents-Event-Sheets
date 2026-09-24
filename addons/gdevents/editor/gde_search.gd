## Поиск и замена по листу событий.
##
## Ищется то, что человек видит на карточке: фразы условий и действий с
## подставленными значениями, текст комментариев, имена групп, объект
## «Для каждого», число повторов, подключённый лист, локальные переменные.
## Заменяется только то, что человек сам вписал, — значения параметров и
## тексты, — а не фразы библиотеки.
@tool
class_name GdeSearch
extends RefCounted


## Пути событий, в которых найден текст, в порядке сверху вниз.
## Регистр не важен. Свёрнутые подсобытия тоже просматриваются.
static func find(events: Variant, reg: GdeRegistry, query: String) -> Array:
	var out: Array = []
	var q := query.strip_edges().to_lower()
	if q.is_empty():
		return out
	_walk(events, [], reg, q, out)
	return out


static func _walk(events: Variant, prefix: Array, reg: GdeRegistry, q: String, out: Array) -> void:
	if not (events is Array):
		return
	for i in range((events as Array).size()):
		var e: Variant = events[i]
		if not (e is Dictionary):
			continue
		var p := prefix + [i]
		if event_text(e, reg).to_lower().contains(q):
			out.append(p)
		_walk((e as Dictionary).get("children", []), p, reg, q, out)


## Весь видимый текст события одной строкой.
static func event_text(e: Dictionary, reg: GdeRegistry) -> String:
	var parts: Array[String] = []
	for key: String in ["text", "name", "object", "count", "sheet"]:
		if e.has(key):
			parts.append(str(e[key]))
	var locals: Variant = e.get("locals", {})
	if locals is Dictionary:
		for k: Variant in (locals as Dictionary):
			parts.append("%s = %s" % [k, (locals as Dictionary)[k]])
	for kind: String in ["conditions", "actions"]:
		for inst: Variant in e.get(kind, []):
			if inst is Dictionary:
				parts.append(instruction_text(inst, kind, reg))
	return "\n".join(parts)


static func instruction_text(inst: Dictionary, kind: String, reg: GdeRegistry) -> String:
	var id := str(inst.get("id", ""))
	var def: Variant = null
	if reg != null:
		def = reg.condition(id) if kind == "conditions" else reg.action(id)
	var params: Array = inst.get("params", [])
	var s := id
	if def is Dictionary:
		s = str((def as Dictionary).get("sentence", id))
		for i in range(params.size()):
			s = s.replace("_PARAM%d_" % i, str(params[i]))
	# Сами значения — отдельно: в фразе могут быть не все параметры.
	var raw: Array[String] = []
	for v: Variant in params:
		raw.append(str(v))
	return "%s %s" % [s, " ".join(raw)]


## Заменить текст во всех значениях и текстах листа. Возвращает число замен.
## Регистр учитывается: «Enemy» → «Boss» не должно трогать «enemy_hp».
static func replace_all(events: Variant, what: String, with: String) -> int:
	if what.is_empty() or not (events is Array):
		return 0
	var n := 0
	for e: Variant in events:
		if not (e is Dictionary):
			continue
		var d: Dictionary = e
		for key: String in ["text", "name", "object", "count", "sheet"]:
			if d.has(key) and d[key] is String:
				n += _replace_in(d, key, what, with)
		for kind: String in ["conditions", "actions"]:
			for inst: Variant in d.get(kind, []):
				if not (inst is Dictionary):
					continue
				var params: Variant = (inst as Dictionary).get("params", [])
				if params is Array:
					for i in range((params as Array).size()):
						if (params as Array)[i] is String:
							var old: String = params[i]
							var c := old.count(what)
							if c > 0:
								(params as Array)[i] = old.replace(what, with)
								n += c
		n += replace_all(d.get("children", []), what, with)
	return n


static func _replace_in(d: Dictionary, key: String, what: String, with: String) -> int:
	var old: String = d[key]
	var c := old.count(what)
	if c > 0:
		d[key] = old.replace(what, with)
	return c
