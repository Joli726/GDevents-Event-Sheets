## Безголовый тест новых событий библиотеки на настоящих листах:
##   godot --headless --quit-after 20000 res://addons/gdevents/tools/events_test.tscn
##
## library_test проверяет, что каждое условие и действие собирается и не
## падает. Здесь — что оно делает то, что обещает: «только что столкнулся»
## срабатывает один раз, «подождать» откладывает, таймер у каждого врага
## свой. Лист собирается генератором, а кадры крутятся вручную — так их
## счёт точный.
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node2D

const OBJECTS := ["Hero", "Spike", "Coin", "Enemy"]

var _fails: int = 0
var _checks: int = 0
var _reg: GdeRegistry


func _ready() -> void:
	GdeI18n.set_language("ru", false)
	_reg = GdeRegistry.load_default()
	var defs: Array = []
	for o: String in OBJECTS:
		defs.append({"name": o, "scene": "res://addons/gdevents/tests/%s_virtual.tscn" % o.to_lower()})
	Gde.register_objects(defs)
	print("—— касания ——")
	await _test_touch_start()
	await _test_touch_end()
	await _test_touch_sides()
	print("—— подождать ——")
	_test_wait_basic()
	_test_wait_keeps_picking()
	_test_wait_chain_and_children()
	_finish()


# --------------------------------------------------------------- касания ---

func _test_touch_start() -> void:
	var hero := _thing("Hero", Vector2(0, 0), Vector2(20, 20))
	var spike := _thing("Spike", Vector2(100, 0), Vector2(20, 20))
	var r := _runner({"hits": 0, "hits2": 0}, [
		_event([_cond("object.collision_start", ["Hero", "Spike"])], [_act("var.modify", ["hits", "+", "1"])]),
		_event([_cond("object.collision_start", ["Hero", "Spike"])], [_act("var.modify", ["hits2", "+", "1"])]),
	])
	_tick(r, 3)
	_eq(Gde.var_get("hits"), 0.0, "только что столкнулся: не касаются — молчит")
	hero.position = Vector2(95, 0)
	_tick(r, 10)
	_eq(Gde.var_get("hits"), 1.0, "только что столкнулся: касаются десять кадров — сработало один раз")
	_eq(Gde.var_get("hits2"), 1.0, "только что столкнулся: у второго такого же условия своя память")
	hero.position = Vector2(0, 0)
	_tick(r, 2)
	hero.position = Vector2(95, 0)
	_tick(r, 5)
	_eq(Gde.var_get("hits"), 2.0, "только что столкнулся: разошлись и снова коснулись — второй раз")
	# Касание краями — тоже столкновение: тела не проникают друг в друга.
	hero.position = Vector2(0, 0)
	_tick(r, 2)
	hero.position = Vector2(80, 0)
	_tick(r, 3)
	_eq(Gde.var_get("hits"), 3.0, "только что столкнулся: касание краями считается")
	_free([r, hero, spike])


func _test_touch_end() -> void:
	var hero := _thing("Hero", Vector2(95, 0), Vector2(20, 20))
	var spike := _thing("Spike", Vector2(100, 0), Vector2(20, 20))
	var r := _runner({"ends": 0}, [
		_event([_cond("object.collision_end", ["Hero", "Spike"])], [_act("var.modify", ["ends", "+", "1"])]),
	])
	_tick(r, 5)
	_eq(Gde.var_get("ends"), 0.0, "касание закончилось: пока касаются — молчит")
	hero.position = Vector2(0, 0)
	_tick(r, 5)
	_eq(Gde.var_get("ends"), 1.0, "касание закончилось: разошлись — сработало один раз")
	_free([r, hero, spike])


func _test_touch_sides() -> void:
	var spike := _thing("Spike", Vector2(0, 0), Vector2(40, 20))    # от -20 до 20, по высоте от -10 до 10
	var hero := _thing("Hero", Vector2(0, -20), Vector2(20, 20))    # стоит сверху: низ героя на -10
	var r := _runner({"top": 0, "bottom": 0, "side": 0}, [
		_event([_cond("object.touch_top", ["Hero", "Spike"])], [_act("var.modify", ["top", "=", "1"])]),
		_event([_cond("object.touch_bottom", ["Hero", "Spike"])], [_act("var.modify", ["bottom", "=", "1"])]),
		_event([_cond("object.touch_side", ["Hero", "Spike"])], [_act("var.modify", ["side", "=", "1"])]),
	])
	_tick(r, 1)
	_ok(Gde.var_get("top") == 1.0 and Gde.var_get("side") == 0.0 and Gde.var_get("bottom") == 0.0,
			"касается сверху: стоит на нём — «сверху», а не «сбоку»")
	_reset_vars(["top", "bottom", "side"])
	hero.position = Vector2(30, 0)
	_tick(r, 1)
	_ok(Gde.var_get("side") == 1.0 and Gde.var_get("top") == 0.0, "касается сбоку: подошёл сбоку")
	_reset_vars(["top", "bottom", "side"])
	hero.position = Vector2(0, 20)
	_tick(r, 1)
	_ok(Gde.var_get("bottom") == 1.0 and Gde.var_get("top") == 0.0, "касается снизу: упёрся снизу")
	_free([r, hero, spike])


# ------------------------------------------------------------ подождать ---

func _test_wait_basic() -> void:
	var r := _runner({"a": 0, "b": 0}, [
		_event([_cond("system.trigger_once", [])], [
			_act("var.modify", ["a", "=", "1"]),
			_act("system.wait", ["0.5"]),
			_act("var.modify", ["b", "=", "1"]),
		]),
		_event([_cond("system.waiting", [])], [_act("var.modify", ["w", "=", "1"])]),
	])
	_tick(r, 10)
	_ok(Gde.var_get("a") == 1.0 and Gde.var_get("b") == 0.0, "подождать: что выше — сразу, что ниже — ещё нет")
	_eq(Gde.var_get("w", 0.0), 1.0, "подождать: условие «идёт ожидание»")
	_tick(r, 25)
	_eq(Gde.var_get("b"), 1.0, "подождать: через полсекунды выполнилось")
	Gde.var_set("w", 0.0)
	_tick(r, 2)
	_eq(Gde.var_get("w", 0.0), 0.0, "подождать: ожидание кончилось — условие ложно")
	_free([r])


func _test_wait_keeps_picking() -> void:
	var coins: Array = []
	for x: float in [10.0, 200.0, 400.0]:
		coins.append(_thing("Coin", Vector2(x, 0), Vector2(8, 8)))
	var r := _runner({}, [
		_event([_cond("system.trigger_once", []), _cond("pick.nearest", ["Coin", "0", "0"])], [
			_act("system.wait", ["0.2"]),
			_act("object.delete", ["Coin"]),
		]),
	])
	_tick(r, 5)
	_eq(Gde.all_instances("Coin").size(), 3, "подождать: пока ждём — все монеты на месте")
	_tick(r, 15)
	var left := Gde.all_instances("Coin")
	_ok(left.size() == 2 and not left.has(coins[0]), "подождать: удалена именно отобранная до ожидания")
	_free([r] + coins)


func _test_wait_chain_and_children() -> void:
	var r := _runner({"x": 0, "y": 0, "c": 0}, [
		_event([_cond("system.trigger_once", [])], [
			_act("system.wait", ["0.1"]),
			_act("var.modify", ["x", "=", "1"]),
			_act("system.wait", ["0.2"]),
			_act("var.modify", ["y", "=", "1"]),
		], [
			_event([], [_act("var.modify", ["c", "+", "1"])]),
		]),
	])
	_tick(r, 3)
	_ok(Gde.var_get("x") == 0.0 and Gde.var_get("c") == 0.0, "подождать: подсобытия тоже ждут")
	_tick(r, 6)
	_ok(Gde.var_get("x") == 1.0 and Gde.var_get("y") == 0.0, "подождать дважды: после первого — только своё")
	_tick(r, 13)
	_ok(Gde.var_get("y") == 1.0 and Gde.var_get("c") == 1.0, "подождать дважды: после второго — остальное и подсобытие, один раз")
	_free([r])


# ------------------------------------------------------------------ лист ---

func _cond(id: String, params: Array, inverted: bool = false) -> Dictionary:
	return {"id": id, "params": params, "inverted": inverted}


func _act(id: String, params: Array) -> Dictionary:
	return {"id": id, "params": params}


func _event(conds: Array, acts: Array, children: Array = []) -> Dictionary:
	return {"type": "standard", "conditions": conds, "actions": acts, "children": children}


## Собрать лист и повесить его раннер в сцену. Кадры — вручную, через _tick.
func _runner(vars: Dictionary, events: Array) -> Node2D:
	var objects: Array = []
	for o: String in OBJECTS:
		objects.append({"name": o, "scene": "res://addons/gdevents/tests/%s_virtual.tscn" % o.to_lower()})
	var sheet := {"objects": objects, "variables": vars, "events": events}
	var r := GdeGenerator.generate(sheet, _reg, "res://events_test.gdes.json")
	if not (r["errors"] as Array).is_empty():
		_ok(false, "лист собирается: %s" % [r["errors"]])
	var s := GDScript.new()
	s.source_code = r["code"]
	if s.reload() != OK:
		_ok(false, "собранный лист компилируется")
		print(r["code"])
	var runner := Node2D.new()
	runner.set_script(s)
	add_child(runner)
	runner.set_process(false)
	# Переменные листа — заново для каждого теста.
	for k: String in vars:
		Gde.var_set(k, vars[k])
	return runner


func _tick(runner: Node, frames: int, delta: float = 1.0 / 60.0) -> void:
	for i in frames:
		runner.call("_process", delta)


func _reset_vars(names: Array) -> void:
	for n: String in names:
		Gde.var_set(n, 0.0)


## Экземпляр объекта листа с формой — для касаний и габаритов.
func _thing(obj: String, at: Vector2, size: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	n.add_child(cs)
	add_child(n)
	n.add_to_group(Gde.GROUP_PREFIX + obj)
	return n


func _free(nodes: Array) -> void:
	for n: Variant in nodes:
		if is_instance_valid(n):
			(n as Node).free()


# ---------------------------------------------------------------- итоги ---

func _eq(got: Variant, want: Variant, what: String) -> void:
	var same := is_equal_approx(float(got), float(want)) if (got is float or got is int) else str(got) == str(want)
	_ok(same, what if same else "%s — ожидалось %s, получено %s" % [what, want, got])


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
