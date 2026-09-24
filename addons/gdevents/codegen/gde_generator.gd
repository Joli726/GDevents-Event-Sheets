## Кодогенератор GDevents: лист событий -> GDScript.
##
## Результат специально сделан читаемым: над каждым событием стоят его
## условия и действия человеческими фразами, а ниже — код, в который они
## превратились. Это и отладка, и способ постепенно выучить GDScript.
class_name GdeGenerator
extends RefCounted

const MAX_WHILE_ITERATIONS := 10000

var _reg: GdeRegistry
var _out: Array[String] = []
var _errors: Array[String] = []
var _warnings: Array[String] = []
var _ctx_n: int = 0
var _tmp_n: int = 0
var _once_n: int = 0
var _every_n: int = 0
var _event_n: int = 0
var _objects: Dictionary = {}

## Где сейчас идёт генерация — чтобы ошибку можно было показать прямо
## на строке листа, а не одной фразой в консоли.
var _path: Array = []
var _inst: Array = []
var _cond_i: int = -1
var _act_i: int = -1
var _error_items: Array = []


static func generate(sheet: Dictionary, reg: GdeRegistry, source_path: String) -> Dictionary:
	var g := GdeGenerator.new()
	g._reg = reg
	return g._run(sheet, source_path)


func _run(sheet: Dictionary, source_path: String) -> Dictionary:
	var objects: Array = sheet.get("objects", [])
	for o: Dictionary in objects:
		_objects[str(o.get("name", ""))] = true
	for gname: String in (sheet.get("groups", {}) as Dictionary):
		_objects[gname] = true

	GdeExpr.known_objects = _objects.duplicate()
	_emit_header(sheet, source_path)
	_emit_ready(sheet)
	_emit_process(sheet)

	_line(0, "")
	_line(0, "func _events() -> void:")
	var events: Array = sheet.get("events", [])
	if events.is_empty():
		_line(1, "pass")
	else:
		_gen_events(events, 1, "")

	GdeExpr.known_objects = {}
	return {
		"code": "\n".join(_out) + "\n",
		"errors": _errors,
		"warnings": _warnings,
		## [{"text", "path": Array, "inst": ["conditions"|"actions", индекс] или []}]
		"error_items": _error_items,
	}


# ------------------------------------------------------------------ каркас ---

func _emit_header(sheet: Dictionary, source_path: String) -> void:
	var base: String = str(sheet.get("extends", "Node2D"))
	_line(0, "# =============================================================")
	_line(0, GdeI18n.t("#  СГЕНЕРИРОВАНО GDevents. Правки здесь будут перезаписаны —"))
	_line(0, GdeI18n.t("#  меняйте лист событий, а не этот файл."))
	_line(0, GdeI18n.t("#  Источник: %s") % source_path)
	_line(0, "# =============================================================")
	_line(0, "extends %s" % base)
	_line(0, "")
	_line(0, "var _delta: float = 0.0")


func _emit_ready(sheet: Dictionary) -> void:
	_line(0, "")
	_line(0, "")
	_line(0, "func _ready() -> void:")
	var objects: Array = sheet.get("objects", [])
	if objects.is_empty():
		_warnings.append(GdeI18n.t("в листе не объявлено ни одного объекта"))
		_line(1, "Gde.register_objects([])")
	else:
		_line(1, "Gde.register_objects([")
		for o: Dictionary in objects:
			_line(2, "{\"name\": %s, \"scene\": %s},"
					% [_quote(str(o.get("name", ""))), _quote(str(o.get("scene", "")))])
		_line(1, "])")

	var groups: Dictionary = sheet.get("groups", {})
	if not groups.is_empty():
		_line(1, "Gde.register_object_groups({")
		for g: String in groups:
			var members: Array = groups[g]
			var quoted: Array[String] = []
			for m: String in members:
				quoted.append(_quote(m))
			_line(2, "%s: [%s]," % [_quote(g), ", ".join(quoted)])
		_line(1, "})")

	var vars: Dictionary = sheet.get("variables", {})
	_line(1, "Gde.begin_scene(%s)" % _literal(vars))


func _emit_process(sheet: Dictionary) -> void:
	_line(0, "")
	_line(0, "")
	_line(0, "func _process(delta: float) -> void:")
	_line(1, "_delta = delta")
	_line(1, "Gde.frame_begin(self)")
	_line(1, "Gde.timer_advance(self, delta)")
	_line(1, "_events()")


# ------------------------------------------------------------------ события ---

func _gen_events(events: Array, indent: int, parent_ctx: String) -> void:
	for i in range(events.size()):
		var e: Dictionary = events[i]
		_path.append(i)
		_inst = []
		_cond_i = -1
		_act_i = -1
		# Выключенное событие не исполняется и не проверяется: пользователь
		# выключает как раз то, что пока сломано.
		if not e.get("disabled", false):
			_gen_event(e, indent, parent_ctx)
		_path.pop_back()


func _gen_event(e: Dictionary, indent: int, parent_ctx: String) -> void:
	match str(e.get("type", "standard")):
		"comment":
			_gen_comment(e, indent)
		"group":
			_gen_group(e, indent, parent_ctx)
		"foreach":
			_gen_foreach(e, indent, parent_ctx)
		"repeat":
			_gen_repeat(e, indent, parent_ctx)
		"while":
			_gen_while(e, indent, parent_ctx)
		_:
			_gen_standard(e, indent, parent_ctx)


func _gen_comment(e: Dictionary, indent: int) -> void:
	_line(indent, "")
	for l: String in str(e.get("text", "")).split("\n"):
		_line(indent, "# %s" % l)


func _gen_group(e: Dictionary, indent: int, parent_ctx: String) -> void:
	_line(indent, "")
	_line(indent, "# ┌─ %s" % str(e.get("name", GdeI18n.t("Группа"))))
	_gen_events(e.get("children", []), indent, parent_ctx)
	_line(indent, "# └─")


func _gen_standard(e: Dictionary, indent: int, parent_ctx: String) -> void:
	if e.get("disabled", false):
		return
	_event_n += 1
	var ctx := _new_ctx()
	_emit_event_comment(e, indent)
	_line(indent, _ctx_decl(ctx, _ctx_init(parent_ctx)))

	var conds := _gen_conditions(e, ctx)

	var body := indent
	if not conds.is_empty():
		_line(indent, "if %s:" % _join_conds(conds, indent))
		body = indent + 1

	var emitted := _gen_body(e.get("actions", []), e.get("children", []), ctx, body)
	if not emitted and body > indent:
		_line(body, "pass")


func _gen_foreach(e: Dictionary, indent: int, parent_ctx: String) -> void:
	var obj := str(e.get("object", ""))
	if not _objects.has(obj):
		_err(GdeI18n.t("«Для каждого»: объект «%s» не объявлен в листе") % obj)
		return
	_event_n += 1
	var outer := _new_ctx()
	_emit_event_comment(e, indent, GdeI18n.t("Для каждого объекта %s") % obj)
	_line(indent, _ctx_decl(outer, _ctx_init(parent_ctx)))
	var it := _tmp("_each")
	_line(indent, "for %s in %s.pick(%s):" % [it, outer, _quote(obj)])
	_line(indent + 1, "if not is_instance_valid(%s): continue" % it)
	var inner := _new_ctx()
	_line(indent + 1, _ctx_decl(inner, "%s.with_single(%s, %s)" % [outer, _quote(obj), it]))

	var conds := _gen_conditions(e, inner)
	var body := indent + 1
	if not conds.is_empty():
		_line(indent + 1, "if %s:" % _join_conds(conds, indent + 1))
		body = indent + 2

	if not _gen_body(e.get("actions", []), e.get("children", []), inner, body):
		_line(body, "pass")


func _gen_repeat(e: Dictionary, indent: int, parent_ctx: String) -> void:
	_event_n += 1
	var outer := _new_ctx()
	_emit_event_comment(e, indent, GdeI18n.t("Повторить %s раз") % str(e.get("count", "1")))
	_line(indent, _ctx_decl(outer, _ctx_init(parent_ctx)))
	var n := GdeExpr.compile_as(str(e.get("count", "1")), "number", outer, _reg)
	_collect(n, GdeI18n.t("«Повторить»: количество"))
	var it := _tmp("_rep")
	_line(indent, "for %s in range(int(%s)):" % [it, n["code"]])
	var inner := _new_ctx()
	_line(indent + 1, _ctx_decl(inner, "%s.copy()" % outer))
	if not _gen_body(e.get("actions", []), e.get("children", []), inner, indent + 1):
		_line(indent + 1, "pass")


func _gen_while(e: Dictionary, indent: int, parent_ctx: String) -> void:
	_event_n += 1
	_emit_event_comment(e, indent, GdeI18n.t("Пока выполняется"))
	var guard := _tmp("_guard")
	_line(indent, "var %s := 0" % guard)
	var outer := _new_ctx()
	_line(indent, _ctx_decl(outer, _ctx_init(parent_ctx)))
	# Контекст условия пересоздаётся каждой итерацией — иначе выборка,
	# суженная на первом проходе, заморозила бы цикл.
	_line(indent, "while true:")
	var inner := _new_ctx()
	_line(indent + 1, _ctx_decl(inner, "%s.copy()" % outer))
	var conds := _gen_conditions(e, inner)
	if conds.is_empty():
		_err(GdeI18n.t("событие «Пока» без условий — это вечный цикл"))
		conds.append("false")
	_line(indent + 1, "if not (%s): break" % _join_conds(conds, indent + 1))
	_line(indent + 1, "%s += 1" % guard)
	_line(indent + 1, "if %s > %d:" % [guard, MAX_WHILE_ITERATIONS])
	_line(indent + 2, "push_error(%s)" % _quote(GdeI18n.t("GDevents: событие «Пока» превысило %d итераций") % MAX_WHILE_ITERATIONS))
	_line(indent + 2, "break")
	_gen_body(e.get("actions", []), e.get("children", []), inner, indent + 1)


## Действия и подсобытия события. «Подождать N секунд» уносит всё, что
## стоит после него, в отложенную функцию: она выполнится позже с той же
## выборкой — контекст захватывается вместе с ней, как в GDevelop.
func _gen_body(actions: Array, children: Array, ctx: String, indent: int) -> bool:
	var emitted := false
	var cur := indent
	var opened: Array[int] = []
	for a: Dictionary in actions:
		var d: Variant = _reg.action(str(a.get("id", "")))
		if d is Dictionary and bool((d as Dictionary).get("defer", false)) and not a.get("disabled", false):
			_act_i += 1
			_inst = ["actions", _act_i]
			var p := _compile_params(d, a.get("params", []), ctx, str(a.get("id", "")))
			var secs: String = (p["args"] as Array)[0] if not (p["args"] as Array).is_empty() else "0.0"
			_line(cur, "Gde.wait(self, float(%s), func() -> void:" % secs)
			opened.append(_out.size())
			cur += 1
			emitted = true
			continue
		if _gen_action(a, ctx, cur):
			emitted = true
	if not children.is_empty():
		_gen_events(children, cur, ctx)
		emitted = true
	while not opened.is_empty():
		if _out.size() == opened.pop_back():
			_line(cur, "pass")
		cur -= 1
		_line(cur, ")")
	return emitted


# -------------------------------------------------------- условия/действия ---

## Условия события: через «и» или, у события «Любое из условий», через «или».
func _gen_conditions(e: Dictionary, ctx: String) -> Array[String]:
	var conds: Array[String] = []
	if not e.get("any", false):
		for c: Dictionary in e.get("conditions", []):
			conds.append(_gen_condition(c, ctx))
		return conds
	var branches: Array[String] = []
	for c2: Dictionary in e.get("conditions", []):
		var sub := _new_ctx()
		var code := _gen_condition(c2, sub)
		# Выключенное условие даёт «true» — в «или» оно сделало бы истинным
		# всё событие. Его просто нет.
		if c2.get("disabled", false):
			continue
		branches.append("func(%s: GdePickContext) -> bool: return %s" % [sub, code])
	# Одной строкой: встроенная функция внутри скобок, разорванная переносом,
	# у парсера GDScript капризна, а читают этот код по комментарию выше.
	if not branches.is_empty():
		conds.append("Gde.any_of(%s, [%s])" % [ctx, ", ".join(branches)])
	return conds


func _gen_condition(c: Dictionary, ctx: String) -> String:
	_cond_i += 1
	_inst = ["conditions", _cond_i]
	# Выключенное условие — как будто его нет: не сужает выборку и не мешает.
	if c.get("disabled", false):
		return "true"
	var id := str(c.get("id", ""))
	var def: Variant = _reg.condition(id)
	if def == null:
		_err(GdeI18n.t("неизвестное условие «%s»") % id)
		return "false"
	var d: Dictionary = def
	var inverted: bool = c.get("inverted", false)
	var raw: Array = c.get("params", [])
	var p := _compile_params(d, raw, ctx, id)
	var args: Array = p["args"]
	var bare: Array = p["bare"]
	var kind := str(d.get("kind", "global"))

	match kind:
		"object":
			var obj := _object_arg(d, args, 0, id)
			if obj == "":
				return "false"
			var ov := _tmp("_o")
			var pred := _fill(_template(d, "pred", id), _memory_subs(_template(d, "pred", id),
					{"ctx": ctx, "self": "self", "o": ov}), args, bare)
			var fn := "Gde.filter_not" if inverted else "Gde.filter"
			return "%s(%s, %s, func(%s): return %s)" % [fn, ctx, _quote(obj), ov, pred]
		"pair":
			var a := _object_arg(d, args, 0, id)
			var b := _object_arg(d, args, 1, id)
			if a == "" or b == "":
				return "false"
			var av := _tmp("_a")
			var bv := _tmp("_b")
			var pred2 := _fill(_template(d, "pred", id), _memory_subs(_template(d, "pred", id),
					{"ctx": ctx, "self": "self", "a": av, "b": bv}), args, bare)
			var fn2 := "Gde.filter_pair_not" if inverted else "Gde.filter_pair"
			return "%s(%s, %s, %s, func(%s, %s): return %s)" % [fn2, ctx, _quote(a), _quote(b), av, bv, pred2]
		_:
			# Условия с памятью («триггер один раз», «каждые N секунд») получают
			# свой номер — иначе два таких условия в листе делили бы состояние.
			var template := _template(d, "code", id)
			var code := _fill(template, _memory_subs(template, {"ctx": ctx, "self": "self"}), args, bare)
			return "not (%s)" % code if inverted else code


## Условия с памятью («триггер один раз», «каждые N секунд», «только что
## столкнулся») получают свой номер — иначе два таких условия в листе
## делили бы состояние. Нужен и парным, и объектным условиям.
func _memory_subs(template: String, subs: Dictionary) -> Dictionary:
	subs["once"] = str(_once_n)
	subs["every"] = str(_every_n)
	if template.contains("{once}"):
		_once_n += 1
	if template.contains("{every}"):
		_every_n += 1
	return subs


func _gen_action(a: Dictionary, ctx: String, indent: int) -> bool:
	_act_i += 1
	_inst = ["actions", _act_i]
	if a.get("disabled", false):
		return false
	var id := str(a.get("id", ""))
	var def: Variant = _reg.action(id)
	if def == null:
		_err(GdeI18n.t("неизвестное действие «%s»") % id)
		return false
	var d: Dictionary = def
	var raw: Array = a.get("params", [])
	var p := _compile_params(d, raw, ctx, id)
	var args: Array = p["args"]
	var bare: Array = p["bare"]
	var template := str(d.get("code", ""))
	# «=» у изменяющих действий — это присваивание, а не «x = x = v».
	if d.has("code_assign") and _has_plain_assign(d, bare):
		template = str(d["code_assign"])

	match str(d.get("kind", "global")):
		"object":
			var obj := _object_arg(d, args, 0, id)
			if obj == "":
				return false
			var ov := _tmp("_o")
			_line(indent, "for %s in %s.pick(%s):" % [ov, ctx, _quote(obj)])
			_line(indent + 1, "if not is_instance_valid(%s): continue" % ov)
			_line(indent + 1, _fill(template, {"ctx": ctx, "self": "self", "o": ov}, args, bare))
		_:
			_line(indent, _fill(template, {"ctx": ctx, "self": "self"}, args, bare))
	return true


## Скомпилировать параметры инструкции в куски GDScript.
##
## Возвращает два набора: args — для подстановки {N}, bare — для {N~}.
## Различаются они только для знаков изменения: в позиции оператора
## нужно «+=», а внутри выражения (a = b + v) — голый «+».
func _compile_params(d: Dictionary, raw: Array, ctx: String, id: String) -> Dictionary:
	var defs: Array = d.get("params", [])
	var out: Array = []
	var bare: Array = []
	if raw.size() < defs.size():
		_err(GdeI18n.t("«%s»: не заполнено параметров (%d из %d)") % [id, raw.size(), defs.size()])
	for i in range(defs.size()):
		var pd: Dictionary = defs[i]
		var kind := str(pd.get("kind", "number"))
		var val := str(raw[i]) if i < raw.size() else ""
		match kind:
			"object", "objname":
				if not _objects.has(val):
					_err(GdeI18n.t("«%s»: объект «%s» не объявлен в листе") % [id, val])
				out.append(val)
				bare.append(val)
			"raw", "varname":
				# Шаблоны ставят такие значения внутрь кавычек: "{0}". Кавычка
				# или обратная косая в имени закрыли бы строку раньше времени,
				# и собранный скрипт не компилировался бы — экранируем.
				if kind == "varname" and not _is_var_path(val):
					_err("«%s»: %s" % [id, GdeI18n.t("не указано имя переменной") if val.strip_edges().is_empty()
							else GdeI18n.t("имя переменной «%s» — пустая часть между точками") % val])
				var safe := _escape(val)
				out.append(safe)
				bare.append(safe)
			"cmpop":
				var cop := _reg.resolve_op("cmpop", val)
				if cop == "":
					_err(GdeI18n.t("«%s»: непонятный знак «%s»") % [id, val])
					cop = "=="
				out.append(cop)
				bare.append(cop)
			"modop":
				var mop := _reg.resolve_op("modop", val)
				if mop == "":
					_err(GdeI18n.t("«%s»: непонятный знак «%s»") % [id, val])
					mop = "="
				out.append(mop)
				bare.append(val)
			"string":
				var r := GdeExpr.compile_as(val, "string", ctx, _reg)
				_collect(r, GdeI18n.t("«%s», параметр %d") % [id, i + 1])
				out.append(r["code"])
				bare.append(r["code"])
			_:
				var r2 := GdeExpr.compile_as(val, "number", ctx, _reg)
				_collect(r2, GdeI18n.t("«%s», параметр %d") % [id, i + 1])
				out.append(r2["code"])
				bare.append(r2["code"])
	# Строку можно заменить или дописать, но не вычесть и не умножить:
	# «"Idle" - "Run"» собрался бы, а в игре упал бы на первом же кадре.
	for i in range(mini(defs.size() - 1, raw.size())):
		if str((defs[i] as Dictionary).get("kind", "")) == "modop" \
				and str((defs[i + 1] as Dictionary).get("kind", "")) == "string" \
				and not (str(raw[i]) in ["=", "+"]):
			_err(GdeI18n.t("«%s»: строку можно только заменить (=) или дописать (+), а не «%s»") % [id, str(raw[i])])
	return {"args": out, "bare": bare}


## Шаблон условия. Без него условие раньше молча становилось «false» и
## событие просто никогда не срабатывало — теперь это ошибка сборки.
func _template(d: Dictionary, key: String, id: String) -> String:
	if not d.has(key):
		_err(GdeI18n.t("«%s»: в библиотеке у условия нет шаблона «%s»") % [id, key])
		return "false"
	return str(d[key])


func _has_plain_assign(d: Dictionary, bare: Array) -> bool:
	var defs: Array = d.get("params", [])
	for i in range(mini(defs.size(), bare.size())):
		if str((defs[i] as Dictionary).get("kind", "")) == "modop" and str(bare[i]) == "=":
			return true
	return false


## Имя объекта из n-го по счёту параметра вида object.
func _object_arg(d: Dictionary, args: Array, which: int, id: String) -> String:
	var defs: Array = d.get("params", [])
	var seen := 0
	for i in range(defs.size()):
		if str((defs[i] as Dictionary).get("kind", "")) == "object":
			if seen == which:
				return str(args[i]) if i < args.size() else ""
			seen += 1
	_err(GdeI18n.t("«%s»: в описании инструкции не хватает параметра-объекта") % id)
	return ""


# ------------------------------------------------------------------ утилиты ---

func _emit_event_comment(e: Dictionary, indent: int, title: String = "") -> void:
	_line(indent, "")
	_line(indent, GdeI18n.t("# ── Событие %d ─%s") % [_event_n, (" " + title) if title != "" else ""])
	var conds: Array = e.get("conditions", [])
	var acts: Array = e.get("actions", [])
	for i in range(conds.size()):
		var c: Dictionary = conds[i]
		var prefix := GdeI18n.t("ЕСЛИ:  ") if i == 0 \
				else (GdeI18n.t("  ИЛИ: ") if e.get("any", false) else GdeI18n.t("  И:   "))
		var neg := GdeI18n.t("НЕ ") if c.get("inverted", false) else ""
		_line(indent, "# %s%s%s" % [prefix, neg, _sentence(_reg.condition(str(c.get("id", ""))), c)])
	for i in range(acts.size()):
		var a: Dictionary = acts[i]
		_line(indent, "# %s%s" % [GdeI18n.t("ТО:    ") if i == 0 else "       ", _sentence(_reg.action(str(a.get("id", ""))), a)])


## Человеческая фраза инструкции с подставленными параметрами.
func _sentence(def: Variant, inst: Dictionary) -> String:
	if def == null:
		return "??? %s" % str(inst.get("id", ""))
	var s := str((def as Dictionary).get("sentence", str(inst.get("id", ""))))
	var raw: Array = inst.get("params", [])
	for i in range(raw.size()):
		s = s.replace("_PARAM%d_" % i, str(raw[i]))
	return s


func _err(text: String) -> void:
	_errors.append(text)
	_error_items.append({"text": text, "path": _path.duplicate(), "inst": _inst.duplicate()})


func _ctx_init(parent_ctx: String) -> String:
	return "Gde.new_context()" if parent_ctx == "" else "%s.copy()" % parent_ctx


## Объявление контекста с явным типом. С «:=» при первом импорте проекта,
## пока кэш классов не построен, Godot не выводил тип из Gde.new_context()
## и сыпал ошибками «Cannot infer the type».
func _ctx_decl(ctx: String, init: String) -> String:
	return "var %s: GdePickContext = %s" % [ctx, init]


func _join_conds(conds: Array[String], indent: int) -> String:
	if conds.size() == 1:
		return conds[0]
	var pad := "\t".repeat(indent + 2)
	return (" \\\n%sand " % pad).join(conds)


func _collect(r: Dictionary, where: String) -> void:
	for e: String in r.get("errors", []):
		_err("%s: %s" % [where, e])


func _new_ctx() -> String:
	_ctx_n += 1
	return "_c%d" % _ctx_n


func _tmp(prefix: String) -> String:
	_tmp_n += 1
	return "%s%d" % [prefix, _tmp_n]


func _line(indent: int, text: String) -> void:
	_out.append("" if text.is_empty() else "\t".repeat(indent) + text)


static func _fill(template: String, subs: Dictionary, args: Array, bare: Array = []) -> String:
	var out := template
	for k: String in subs:
		out = out.replace("{%s}" % k, str(subs[k]))
	# С конца — иначе {1} затрёт часть {10}.
	for i in range(args.size() - 1, -1, -1):
		if i < bare.size():
			out = out.replace("{%d~}" % i, str(bare[i]))
		out = out.replace("{%d}" % i, str(args[i]))
	return out


static func _quote(s: String) -> String:
	return "\"%s\"" % _escape(s)


## Содержимое строкового литерала GDScript без внешних кавычек.
static func _escape(s: String) -> String:
	return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")


## Имя переменной: «score» или путь «player.hp» без пустых частей.
static func _is_var_path(s: String) -> bool:
	if s.strip_edges().is_empty():
		return false
	for part: String in s.split("."):
		if part.strip_edges().is_empty():
			return false
	return true


static func _literal(v: Variant) -> String:
	match typeof(v):
		TYPE_DICTIONARY:
			var parts: Array[String] = []
			for k: Variant in (v as Dictionary):
				parts.append("%s: %s" % [_quote(str(k)), _literal((v as Dictionary)[k])])
			return "{%s}" % ", ".join(parts)
		TYPE_ARRAY:
			var items: Array[String] = []
			for x: Variant in (v as Array):
				items.append(_literal(x))
			return "[%s]" % ", ".join(items)
		TYPE_STRING, TYPE_STRING_NAME:
			return _quote(str(v))
		TYPE_BOOL:
			return "true" if v else "false"
		TYPE_INT, TYPE_FLOAT:
			# var_to_str — литерал, который GDScript прочтёт обратно как есть:
			# «2.5», «3.0», «1e+20». Раньше тут стоял формат %g, которого в
			# Godot нет: дробное значение превращалось в «%.10g» и ломало
			# скрипт, а 1e20 через int() становилось отрицательным.
			return var_to_str(float(v))
		_:
			return "null"
