## Транспайлер выражений GDevelop в GDScript.
##
## Понимает привычный синтаксис:
##   1 + Player.X() * 2
##   RandomInRange(0, 5)
##   "Счёт: " + ToString(Variable(score))
##   Player.Variable(hp) - 10
##   Player.Shoot::CooldownLeft()
##
## Числа всегда компилируются во float — в GDevelop нет целочисленного
## деления, а в GDScript 3 / 2 == 1, и это выстрелило бы в ногу.
class_name GdeExpr
extends RefCounted

var _toks: Array = []
var _i: int = 0
var _errors: Array[String] = []
var _ctx: String = ""
var _reg: Object = null


## Объекты листа: имя -> true. Если заданы, опечатка в имени объекта
## ловится при сборке, а не превращается в молчаливый ноль в игре.
## Ставит тот, кто компилирует лист (генератор, окно параметров).
static var known_objects: Dictionary = {}


## Скомпилировать выражение. Возвращает { code, type, errors }.
## type — "number" или "string".
static func compile(src: String, ctx_var: String, registry: Object) -> Dictionary:
	var p := GdeExpr.new()
	p._reg = registry
	p._ctx = ctx_var
	p._toks = _lex(src, p._errors)
	p._i = 0
	if src.strip_edges().is_empty():
		return {"code": "0.0", "type": "number", "errors": p._errors}
	var r := p._expr()
	if p._peek()["t"] != "eof":
		p._err(GdeI18n.t("лишнее в конце выражения: «%s»") % str(p._peek()["v"]))
	return {"code": r[0], "type": r[1], "errors": p._errors}


## Скомпилировать с приведением к нужному типу ("number" | "string").
static func compile_as(src: String, want: String, ctx_var: String, registry: Object) -> Dictionary:
	var r := compile(src, ctx_var, registry)
	if want == "string" and r["type"] == "number":
		r["code"] = "str(%s)" % r["code"]
		r["type"] = "string"
	elif want == "number" and r["type"] == "string":
		r["code"] = "float(%s)" % r["code"]
		r["type"] = "number"
	return r


# ------------------------------------------------------------------ лексер ---

static func _lex(src: String, errors: Array[String]) -> Array:
	var toks: Array = []
	var i := 0
	var n := src.length()
	while i < n:
		var c := src[i]
		if c == " " or c == "\t" or c == "\n" or c == "\r":
			i += 1
			continue
		if c == "\"":
			var buf := ""
			var j := i + 1
			var closed := false
			while j < n:
				if src[j] == "\\" and j + 1 < n:
					j += 1
					match src[j]:
						"n": buf += "\n"
						"t": buf += "\t"
						"\"": buf += "\""
						"\\": buf += "\\"
						_: buf += src[j]
				elif src[j] == "\"":
					closed = true
					break
				else:
					buf += src[j]
				j += 1
			if not closed:
				errors.append(GdeI18n.t("незакрытая кавычка"))
			toks.append({"t": "str", "v": buf})
			i = j + 1
			continue
		if _is_digit(c) or (c == "." and i + 1 < n and _is_digit(src[i + 1])):
			var j2 := i
			var seen_dot := false
			while j2 < n and (_is_digit(src[j2]) or (src[j2] == "." and not seen_dot)):
				if src[j2] == ".":
					seen_dot = true
				j2 += 1
			toks.append({"t": "num", "v": src.substr(i, j2 - i)})
			i = j2
			continue
		if _is_ident_start(c):
			var j3 := i
			while j3 < n and _is_ident_part(src[j3]):
				j3 += 1
			toks.append({"t": "id", "v": src.substr(i, j3 - i)})
			i = j3
			continue
		if c == ":" and i + 1 < n and src[i + 1] == ":":
			toks.append({"t": "op", "v": "::"})
			i += 2
			continue
		if c in ["+", "-", "*", "/", "%", "(", ")", ",", "."]:
			toks.append({"t": "op", "v": c})
			i += 1
			continue
		errors.append(GdeI18n.t("непонятный символ «%s»") % c)
		i += 1
	toks.append({"t": "eof", "v": ""})
	return toks


static func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"


## Имя может быть каким угодно словом, не только латиницей: переменную
## разумно назвать «счёт», и ломаться на этом транспайлер не должен.
## Всё, что не разделитель, не цифра и не знак операции — буква.
static func _is_ident_start(c: String) -> bool:
	if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_":
		return true
	return c.unicode_at(0) > 127


static func _is_ident_part(c: String) -> bool:
	return _is_ident_start(c) or _is_digit(c)


# ------------------------------------------------------------------ парсер ---

func _peek() -> Dictionary:
	return _toks[_i]


func _next() -> Dictionary:
	var t: Dictionary = _toks[_i]
	if _i < _toks.size() - 1:
		_i += 1
	return t


func _is_op(v: String) -> bool:
	var t := _peek()
	return t["t"] == "op" and t["v"] == v


func _eat_op(v: String) -> bool:
	if _is_op(v):
		_next()
		return true
	_err(GdeI18n.t("ожидалось «%s»") % v)
	return false


func _err(msg: String) -> void:
	if _errors.size() < 12:
		_errors.append(msg)


## Сложение и конкатенация. Если любая сторона — строка, «+» склеивает.
func _expr() -> Array:
	var left := _term()
	while _is_op("+") or _is_op("-"):
		var op: String = _next()["v"]
		var right := _term()
		if op == "+" and (left[1] == "string" or right[1] == "string"):
			left = ["(%s + %s)" % [_as_str(left), _as_str(right)], "string"]
		else:
			left = ["(%s %s %s)" % [_as_num(left), op, _as_num(right)], "number"]
	return left


func _term() -> Array:
	var left := _unary()
	while _is_op("*") or _is_op("/") or _is_op("%"):
		var op: String = _next()["v"]
		var right := _unary()
		if op == "%":
			left = ["fmod(%s, %s)" % [_as_num(left), _as_num(right)], "number"]
		else:
			left = ["(%s %s %s)" % [_as_num(left), op, _as_num(right)], "number"]
	return left


func _unary() -> Array:
	if _is_op("-"):
		_next()
		var v := _unary()
		return ["(-%s)" % _as_num(v), "number"]
	if _is_op("+"):
		_next()
		return _unary()
	return _primary()


func _primary() -> Array:
	var t := _peek()
	if t["t"] == "num":
		_next()
		return [_num_literal(str(t["v"])), "number"]
	if t["t"] == "str":
		_next()
		return [_str_literal(str(t["v"])), "string"]
	if _is_op("("):
		_next()
		var inner := _expr()
		_eat_op(")")
		return inner
	if t["t"] == "id":
		return _ident()
	_err(GdeI18n.t("не понимаю «%s»") % str(t["v"]))
	_next()
	return ["0.0", "number"]


## Идентификатор: свободная функция, Объект.Функция() или
## Объект.Поведение::Функция().
func _ident() -> Array:
	var name: String = str(_next()["v"])

	if _is_op("("):
		var def: Variant = _reg.free_expr(name)
		if def == null:
			_err(GdeI18n.t("неизвестная функция «%s»") % name)
			_skip_args()
			return ["0.0", "number"]
		var args := _args(def)
		# Count() и Timer() смотрят на выборку события и на раннер листа —
		# без этих подстановок в код уходили голые {ctx} и {self}.
		var fsubs := {"ctx": _ctx, "self": "self"}
		return [_fill(def["template"], fsubs, args), def.get("type", "number")]

	# Выражение расширения: Clock::Hour().
	if _is_op("::"):
		_next()
		if _peek()["t"] != "id":
			_err(GdeI18n.t("после «%s::» ожидалось имя функции") % name)
			return ["0.0", "number"]
		var efn: String = str(_next()["v"])
		var edef: Variant = _reg.ext_expr(name, efn) if _reg != null and _reg.has_method("ext_expr") else null
		if edef == null:
			_err(GdeI18n.t("у расширения «%s» нет выражения «%s»") % [name, efn])
			_skip_args()
			return ["0.0", "number"]
		var eargs := _args(edef)
		return [_fill(edef["template"], {"ctx": _ctx, "self": "self"}, eargs), edef.get("type", "number")]

	if _is_op("."):
		_next()
		if _peek()["t"] != "id":
			_err(GdeI18n.t("после «%s.» ожидалось имя функции") % name)
			return ["0.0", "number"]
		var member: String = str(_next()["v"])
		if not known_objects.is_empty() and not known_objects.has(name):
			_err(_unknown_object(name))

		if _is_op("::"):
			_next()
			if _peek()["t"] != "id":
				_err(GdeI18n.t("после «%s::» ожидалось имя функции") % member)
				return ["0.0", "number"]
			var bfn: String = str(_next()["v"])
			var bdef: Variant = _reg.behavior_expr(member, bfn)
			if bdef == null:
				_err(GdeI18n.t("у поведения «%s» нет выражения «%s»") % [member, bfn])
				_skip_args()
				return ["0.0", "number"]
			var bargs := _args(bdef)
			var subs := {"ctx": _ctx, "obj": name, "beh": member}
			return [_fill(bdef["template"], subs, bargs), bdef.get("type", "number")]

		var odef: Variant = _reg.object_expr(member)
		if odef == null:
			_err(GdeI18n.t("неизвестное выражение объекта «%s»") % member)
			_skip_args()
			return ["0.0", "number"]
		var oargs := _args(odef)
		return [_fill(odef["template"], {"ctx": _ctx, "obj": name}, oargs), odef.get("type", "number")]

	_err(GdeI18n.t("«%s» само по себе не является выражением") % name)
	return ["0.0", "number"]


## «Объекта Plaer нет в листе — может, Player?»
static func _unknown_object(name: String) -> String:
	var best := ""
	var best_score := 0.0
	for o: String in known_objects:
		var sc := name.to_lower().similarity(o.to_lower())
		if sc > best_score:
			best_score = sc
			best = o
	if best_score >= 0.5:
		return GdeI18n.t("объекта «%s» нет в листе — может, «%s»?") % [name, best]
	return GdeI18n.t("объекта «%s» нет в листе") % name


## Разбор аргументов по описанию параметров. Параметры вида varname/raw
## читаются как сырой идентификатор, а не как выражение — именно так
## работает Variable(score) в GDevelop.
func _args(def: Dictionary) -> Array:
	var kinds: Array = def.get("params", [])
	var out: Array = []
	if not _eat_op("("):
		return out
	if _is_op(")"):
		_next()
		if kinds.size() > 0:
			_err(GdeI18n.t("«%s» ожидает %d аргумент(ов)") % [def.get("name", "?"), kinds.size()])
		return out
	var idx := 0
	while true:
		var kind: String = str(kinds[idx]) if idx < kinds.size() else "number"
		if kind == "varname" or kind == "raw":
			out.append(_str_literal(_raw_path()))
		else:
			var e := _expr()
			out.append(_as_str(e) if kind == "string" else _as_num(e))
		idx += 1
		if _is_op(","):
			_next()
			continue
		break
	_eat_op(")")
	if idx != kinds.size():
		_err(GdeI18n.t("«%s» ожидает %d аргумент(ов), получено %d") % [def.get("name", "?"), kinds.size(), idx])
	return out


## Сырой путь вида hp или player.hp — для имён переменных.
func _raw_path() -> String:
	var parts: Array[String] = []
	while _peek()["t"] == "id":
		parts.append(str(_next()["v"]))
		if _is_op("."):
			_next()
			continue
		break
	if parts.is_empty():
		_err(GdeI18n.t("ожидалось имя переменной"))
		return ""
	return ".".join(parts)


## Проглотить скобки после нераспознанной функции, чтобы не сыпать ошибками.
func _skip_args() -> void:
	if not _is_op("("):
		return
	var depth := 0
	while _peek()["t"] != "eof":
		if _is_op("("):
			depth += 1
		elif _is_op(")"):
			depth -= 1
			if depth == 0:
				_next()
				return
		_next()


# ----------------------------------------------------------------- утилиты ---

func _as_num(v: Array) -> String:
	return v[0] if v[1] == "number" else "float(%s)" % v[0]


func _as_str(v: Array) -> String:
	return v[0] if v[1] == "string" else "str(%s)" % v[0]


static func _num_literal(s: String) -> String:
	## Всегда float: иначе GDScript сделает целочисленное деление.
	if s.contains("."):
		return s if not s.ends_with(".") else s + "0"
	return s + ".0"


static func _str_literal(s: String) -> String:
	return "\"%s\"" % s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t")


static func _fill(template: String, subs: Dictionary, args: Array) -> String:
	var out := template
	for k: String in subs:
		out = out.replace("{%s}" % k, str(subs[k]))
	for i in range(args.size()):
		out = out.replace("{%d}" % i, str(args[i]))
	return out
