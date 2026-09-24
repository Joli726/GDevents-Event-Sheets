## Безголовый тест всей библиотеки инструкций:
##   godot --headless --quit-after 600 res://addons/gdevents/tools/library_test.tscn
##
## Каждое условие (и с «НЕ»), каждое действие и каждое выражение — встроенные,
## из поведений и из расширений — собирается в отдельный лист, компилируется
## и дважды выполняется на живом объекте со всеми поведениями разом (сама
## механика — GdeInstructionCheck). Руками столько не перепроверить, а поломки
## тут тихие: так нашлись условия, которые всегда были «false», «Удалить все»,
## ломавшее скрипт, и настройки-галочки, падавшие в игре на «true == 1.0».
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node2D

var _fails: int = 0
var _checks: int = 0


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	var reg := GdeRegistry.load_default()
	var chk := GdeInstructionCheck.new(reg)
	add_child(chk)
	await chk.prepare()

	var conds: Array[String] = []
	var acts: Array[String] = []
	for id: String in reg.conditions:
		conds.append(id)
	for id: String in reg.actions:
		acts.append(id)
	for b: String in reg.behaviors:
		var entry: Dictionary = reg.behaviors[b]
		for m: String in (entry.get("conditions", {}) as Dictionary):
			conds.append("%s::%s" % [b, m])
		for m: String in (entry.get("actions", {}) as Dictionary):
			acts.append("%s::%s" % [b, m])

	var before := _fails
	for id: String in conds:
		_check("условие %s" % id, chk.condition(id))
	_summary("условий", conds.size(), before)

	before = _fails
	var n_acts := 0
	for id: String in acts:
		if id in GdeInstructionCheck.SKIP:
			continue
		n_acts += 1
		_check("действие %s" % id, chk.action(id))
	_summary("действий", n_acts, before)

	before = _fails
	var n_expr := 0
	for name: String in reg.expressions:
		n_expr += 1
		_check("выражение %s" % name, chk.expression(name, reg.free_expr(name)))
	for name: String in reg.object_expressions:
		n_expr += 1
		_check("выражение Hero.%s" % name, chk.expression("Hero.%s" % name, reg.object_expr(name)))
	for b: String in reg.behaviors:
		for name: String in ((reg.behaviors[b] as Dictionary).get("expressions", {}) as Dictionary):
			n_expr += 1
			_check("выражение Hero.%s::%s" % [b, name],
					chk.expression("Hero.%s::%s" % [b, name], reg.behavior_expr(b, name)))
	# Выражения расширений: Clock::Hour() и т. п.
	for key: String in reg.ext_expressions:
		n_expr += 1
		var parts := key.split("::")
		_check("выражение %s" % key, chk.expression(key, reg.ext_expr(parts[0], parts[1])))
	_summary("выражений", n_expr, before)

	chk.finish()
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _check(title: String, why: String) -> void:
	_checks += 1
	if not why.is_empty():
		_fails += 1
		print("  ✗ %s — %s" % [title, why])


func _summary(what: String, n: int, fails_before: int) -> void:
	if _fails == fails_before:
		print("  ✓ %s: %d — все собираются и выполняются" % [what, n])
