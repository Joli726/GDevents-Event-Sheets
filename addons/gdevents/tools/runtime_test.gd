## Безголовый тест рантайма и генератора:
##   godot --headless res://addons/gdevents/tools/runtime_test.tscn
##
## Выборка объектов — то, на чём держится смысл каждого события, и ошибка
## в ней не видна ни в редакторе, ни в консоли: событие просто трогает не
## тех. Здесь её семантика сверяется с GDevelop на живых нодах, а собранный
## генератором код — компилятором Godot.
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node2D

const ENEMY_SCENE := "res://addons/gdevents/tests/enemy.tscn"

var _fails: int = 0
var _checks: int = 0


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	Gde.register_objects([{"name": "Enemy", "scene": ENEMY_SCENE}])
	print("—— выборка ——")
	_test_create_picks_only_new()
	_test_create_keeps_existing_pick()
	_test_not_filters()
	_test_not_pair_filters()
	print("—— переменные сцены ——")
	_test_begin_scene_twice()
	_test_empty_var_name()
	print("—— генератор ——")
	_test_fractional_variable()
	_test_var_name_escaping()
	_test_string_modop()
	_test_missing_template()
	_test_free_expr_subs()
	_test_compile_check()
	_finish()


# ---------------------------------------------------------------- выборка ---

func _spawn(n: int) -> Array[Node2D]:
	var ps: PackedScene = load(ENEMY_SCENE)
	var out: Array[Node2D] = []
	for i in range(n):
		var e: Node2D = ps.instantiate()
		add_child(e)
		out.append(e)
	return out


func _clear() -> void:
	for e: Node in Gde.all_instances("Enemy"):
		remove_child(e)
		e.free()


func _test_create_picks_only_new() -> void:
	_spawn(2)
	var ctx := Gde.new_context()
	var made := Gde.create_object(ctx, "Enemy", 0, 0, self)
	var picked := ctx.pick("Enemy")
	_ok(picked.size() == 1 and picked[0] == made,
			"«Создать» в событии без выборки: отобран только новый (в выборке %d)" % picked.size())
	_clear()


func _test_create_keeps_existing_pick() -> void:
	var old := _spawn(3)
	old[0].visible = false
	var ctx := Gde.new_context()
	Gde.filter(ctx, "Enemy", func(o: Node) -> bool: return (o as Node2D).visible)
	var made := Gde.create_object(ctx, "Enemy", 0, 0, self)
	var picked := ctx.pick("Enemy")
	_ok(picked.size() == 3 and picked.has(made) and not picked.has(old[0]),
			"«Создать» после условия: новый добавлен к отобранным, а не ко всем")
	_clear()


func _test_not_filters() -> void:
	var e := _spawn(3)
	e[0].visible = true
	e[1].visible = false
	e[2].visible = false
	var ctx := Gde.new_context()
	var res := Gde.filter_not(ctx, "Enemy", func(o: Node) -> bool: return (o as Node2D).visible)
	var picked := ctx.pick("Enemy")
	_ok(res, "«НЕ видим»: истинно, когда невидимые есть — даже рядом с видимым")
	_ok(picked.size() == 2 and not picked.has(e[0]), "«НЕ видим»: отобраны именно невидимые")

	e[1].visible = true
	e[2].visible = true
	var ctx2 := Gde.new_context()
	_ok(not Gde.filter_not(ctx2, "Enemy", func(o: Node) -> bool: return (o as Node2D).visible),
			"«НЕ видим»: ложно, когда видимы все")
	_ok(ctx2.pick("Enemy").is_empty(), "и в выборке никого")
	_clear()


func _test_not_pair_filters() -> void:
	var e := _spawn(3)
	e[0].position = Vector2(0, 0)
	e[1].position = Vector2(10, 0)
	e[2].position = Vector2(1000, 0)
	var near := func(a: Node, b: Node) -> bool: return Gde.distance(a, b) < 50.0
	var ctx := Gde.new_context()
	var res := Gde.filter_pair_not(ctx, "Enemy", "Enemy", near)
	var picked := ctx.pick("Enemy")
	_ok(res and picked.size() == 1 and picked[0] == e[2],
			"«НЕ рядом» для пары: отобран только тот, кто далеко от всех")
	_clear()


# ------------------------------------------------------ переменные сцены ---

func _test_begin_scene_twice() -> void:
	Gde.begin_scene({"score": 0.0})
	Gde.var_set("score", 42.0)
	Gde.timer_value(self, "t")
	Gde.timer_advance(self, 1.5)
	# Второй раннер той же сцены: игрок с листом появился ещё раз.
	Gde.begin_scene({"score": 0.0, "lives": 3.0})
	_ok(is_equal_approx(float(Gde.var_get("score")), 42.0), "второй раннер не обнулил переменную сцены")
	_ok(is_equal_approx(float(Gde.var_get("lives")), 3.0), "и добавил свою новую")
	_ok(is_equal_approx(Gde.timer_value(self, "t"), 1.5), "и не сбросил таймеры")


func _test_empty_var_name() -> void:
	# Раньше — выход за границы массива в _dig().
	_ok(is_equal_approx(float(Gde.var_get("", 7.0)), 7.0), "пустое имя переменной: чтение не падает")
	Gde.var_set("", 1.0)
	_ok(true, "пустое имя переменной: запись не падает")


# ------------------------------------------------------------- генератор ---

func _sheet(vars: Dictionary, events: Array) -> Dictionary:
	return {"objects": [{"name": "Enemy", "scene": ENEMY_SCENE}], "variables": vars, "events": events}


func _gen(sheet: Dictionary) -> Dictionary:
	return GdeGenerator.generate(sheet, GdeRegistry.load_default(), "res://runtime_test.gdes.json")


func _compiles(code: String) -> bool:
	var s := GDScript.new()
	s.source_code = code
	return s.reload() == OK


func _test_fractional_variable() -> void:
	var r := _gen(_sheet({"speed": 2.5, "big": 1e20, "n": 3}, []))
	var code: String = r["code"]
	_ok(_compiles(code), "дробное начальное значение переменной собирается")
	_ok(code.contains("\"speed\": 2.5"), "и записано как есть: 2.5")
	_ok(not code.contains("-9223372036854775808"), "большое число не превратилось в отрицательное")


func _test_var_name_escaping() -> void:
	var ev := {"type": "standard", "conditions": [{"id": "var.compare", "params": ["a\"b", "=", "1"]}], "actions": []}
	var r := _gen(_sheet({}, [ev]))
	_ok((r["errors"] as Array).is_empty() and _compiles(r["code"]), "кавычка в имени переменной не ломает скрипт")

	var ev2 := {"type": "standard", "conditions": [], "actions": [{"id": "var.modify", "params": ["", "=", "1"]}]}
	var r2 := _gen(_sheet({}, [ev2]))
	_ok(not (r2["errors"] as Array).is_empty(), "пустое имя переменной — ошибка сборки: %s" % [r2["errors"]])


func _test_string_modop() -> void:
	var reg := GdeRegistry.load_default()
	var id := "TopDown::set_idle_animation"
	_ok(reg.action(id) != null, "у поведения есть строковая настройка для проверки")
	var ev := {"type": "standard", "conditions": [], "actions": [{"id": id, "params": ["Enemy", "-", "\"Run\""]}]}
	var r := GdeGenerator.generate(_sheet({}, [ev]), reg, "")
	_ok(not (r["errors"] as Array).is_empty(), "вычитание из строки — ошибка сборки, а не падение в игре")
	var ev2 := {"type": "standard", "conditions": [], "actions": [{"id": id, "params": ["Enemy", "+", "\"Run\""]}]}
	_ok((GdeGenerator.generate(_sheet({}, [ev2]), reg, "")["errors"] as Array).is_empty(), "а дописать строку можно")


func _test_missing_template() -> void:
	var reg := GdeRegistry.load_default()
	reg.conditions["test.no_template"] = {"kind": "global", "params": [], "pred": "true"}
	var ev := {"type": "standard", "conditions": [{"id": "test.no_template", "params": []}], "actions": []}
	var r := GdeGenerator.generate(_sheet({}, [ev]), reg, "")
	_ok(not (r["errors"] as Array).is_empty(), "условие без шаблона — ошибка сборки, а не молчаливое «false»")


func _test_free_expr_subs() -> void:
	var ev := {"type": "standard", "conditions": [], "actions": [
		{"id": "system.print", "params": ["ToString(Count(Enemy) + Timer(t))"]}]}
	var r := _gen(_sheet({}, [ev]))
	var code: String = r["code"]
	_ok(not code.contains("{ctx}") and not code.contains("{self}") and _compiles(code),
			"Count() и Timer() в выражениях собираются")


func _test_compile_check() -> void:
	_ok(GdeBuild.compile_error("extends Node\nfunc f() -> void:\n\tpass\n") == "", "проверка сборки пропускает рабочий код")
	_ok(GdeBuild.compile_error("extends Node\nfunc f() -> void:\n\tvar x = {\"a\": %.10g}\n") != "",
			"и ловит сломанный")


# ---------------------------------------------------------------- итоги ---

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)


func _finish() -> void:
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)
