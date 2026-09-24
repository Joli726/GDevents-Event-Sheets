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
	print("—— таймеры объекта, сравнение, радиус ——")
	await _test_object_timers()
	_test_compare()
	_test_pick_radius()
	print("—— ввод ——")
	await _test_key_hold()
	await _test_double_tap()
	_test_gamepad_absent()
	print("—— прикрепить, дублировать ——")
	_test_attach()
	_test_duplicate()
	print("—— эффекты ——")
	await _test_effects()
	await _test_hitstop_flash_fade()
	print("—— списки, значения на экране ——")
	_test_lists()
	await _test_screen_values()
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


# -------------------------------------------- таймеры, сравнение, радиус ---

func _test_object_timers() -> void:
	var a := _thing("Enemy", Vector2(0, 0), Vector2(8, 8))
	var b := _thing("Enemy", Vector2(50, 0), Vector2(8, 8))
	var r := _runner({}, [
		_event([_cond("object.timer", ["Enemy", "shot", ">", "0.15"])], [
			_act("object.timer_reset", ["Enemy", "shot"]),
			_act("object.variable", ["Enemy", "shots", "+", "1"]),
		]),
	])
	_tick(r, 1)
	await _wait_ms(80)
	Gde.otimer_reset(b, "shot")
	await _wait_ms(100)
	_tick(r, 1)
	_ok(float(Gde.ovar_get(a, "shots")) == 1.0 and float(Gde.ovar_get(b, "shots")) == 0.0,
			"таймер объекта: у каждого свой — первый выстрелил, второй ещё нет")
	await _wait_ms(100)
	_tick(r, 1)
	_ok(float(Gde.ovar_get(b, "shots")) == 1.0 and float(Gde.ovar_get(a, "shots")) == 1.0,
			"таймер объекта: второй выстрелил в свой срок, первый ещё ждёт")
	Gde.otimer_pause(a, "shot", true)
	var t0 := Gde.otimer(a, "shot")
	await _wait_ms(120)
	_ok(absf(Gde.otimer(a, "shot") - t0) < 0.001, "таймер объекта: на паузе стоит")
	Gde.otimer_pause(a, "shot", false)
	await _wait_ms(60)
	_ok(Gde.otimer(a, "shot") > t0 + 0.03, "таймер объекта: снята пауза — пошёл дальше")
	var ex := GdeExpr.compile("Enemy.Timer(shot)", "_c", _reg)
	_ok((ex["errors"] as Array).is_empty() and str(ex["code"]).contains("Gde.otimer"), "таймер объекта: выражение Enemy.Timer(shot)")
	_free([r, a, b])


func _wait_ms(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await get_tree().process_frame


func _test_compare() -> void:
	var r := _runner({"a": 3, "yes": 0, "no": 0, "txt": 0}, [
		_event([_cond("system.compare", ["Variable(a) + 2", "=", "5"])], [_act("var.modify", ["yes", "=", "1"])]),
		_event([_cond("system.compare", ["Variable(a) * 2", "<", "3"])], [_act("var.modify", ["no", "=", "1"])]),
		_event([_cond("system.compare_text", ["VariableString(name)", "=", "\"bob\""])], [_act("var.modify", ["txt", "=", "1"])]),
	])
	Gde.var_set("name", "bob")
	_tick(r, 1)
	_ok(Gde.var_get("yes") == 1.0 and Gde.var_get("no") == 0.0, "сравнить два значения: 3 + 2 = 5 — да, 3 × 2 < 3 — нет")
	_eq(Gde.var_get("txt"), 1.0, "сравнить два текста: «bob» = «bob»")
	_free([r])


func _test_pick_radius() -> void:
	var near := [_thing("Enemy", Vector2(50, 0), Vector2(8, 8)), _thing("Enemy", Vector2(0, 100), Vector2(8, 8))]
	var far := _thing("Enemy", Vector2(300, 0), Vector2(8, 8))
	var boom := _thing("Hero", Vector2(1000, 0), Vector2(8, 8))
	var around := [_thing("Enemy", Vector2(1050, 0), Vector2(8, 8)), _thing("Enemy", Vector2(1000, 110), Vector2(8, 8))]
	var outside := _thing("Enemy", Vector2(1400, 0), Vector2(8, 8))
	var r := _runner({}, [
		_event([_cond("system.trigger_once", []), _cond("pick.in_radius", ["Enemy", "0", "0", "150"])],
				[_act("object.variable", ["Enemy", "hit", "=", "1"])]),
		_event([_cond("system.trigger_once", []), _cond("pick.in_radius_of", ["Enemy", "Hero", "120"])],
				[_act("object.variable", ["Enemy", "boom", "=", "1"])]),
	])
	_tick(r, 1)
	var hit := 0
	for n: Node in near:
		hit += int(Gde.ovar_get(n, "hit", 0.0))
	_ok(hit == 2 and float(Gde.ovar_get(far, "hit", 0.0)) == 0.0, "в радиусе от точки: задеты оба ближних, дальний — нет")
	var boomed := 0
	for n: Node in around:
		boomed += int(Gde.ovar_get(n, "boom", 0.0))
	_ok(boomed == 2 and float(Gde.ovar_get(outside, "boom", 0.0)) == 0.0 and float(Gde.ovar_get(near[0], "boom", 0.0)) == 0.0,
			"в радиусе от объекта: взрыв задел всех рядом и никого дальше")
	_free([r, far, boom, outside] + near + around)


# ------------------------------------------------------------------ ввод ---

func _key_event(code: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)


func _test_key_hold() -> void:
	_key_event(KEY_SPACE, true)
	await get_tree().process_frame
	await _wait_ms(150)
	_ok(Gde.key_held("Space", 0.1) and not Gde.key_held("Space", 1.0), "удержание: держим 0.15 с — «дольше 0.1» да, «дольше 1» нет")
	_ok(Gde.key_held_time("Space") > 0.1, "удержание: KeyHeldTime(Space) = %.2f" % Gde.key_held_time("Space"))
	_key_event(KEY_SPACE, false)
	var fired := false
	for i in 5:
		await get_tree().process_frame
		if Gde.key_released_after("Space", 0.1):
			fired = true
			break
	_ok(fired, "удержание: отпустили после 0.1 с — «заряженный выстрел»")
	await get_tree().process_frame
	_ok(not Gde.key_released_after("Space", 0.1), "удержание: «отпущена после» — только в кадр отпускания")
	_eq(Gde.key_held_time("Space"), 0.0, "удержание: отпущена — время 0")


func _test_double_tap() -> void:
	var taps := 0
	for step: Array in [[true, 0], [false, 60], [true, 60], [false, 60], [true, 60]]:
		_key_event(KEY_Z, step[0])
		for i in 3:
			await get_tree().process_frame
			if Gde.key_double_tap("Z", 0.3):
				taps += 1
		await _wait_ms(step[1])
	_key_event(KEY_Z, false)
	await get_tree().process_frame
	_eq(taps, 1, "двойное нажатие: два быстрых нажатия — один раз, третье следом не считается")
	await _wait_ms(400)
	_key_event(KEY_Z, true)
	var late := false
	for i in 3:
		await get_tree().process_frame
		late = late or Gde.key_double_tap("Z", 0.3)
	_key_event(KEY_Z, false)
	await get_tree().process_frame
	_ok(not late, "двойное нажатие: второе через 0.4 с — уже не двойное")


func _test_gamepad_absent() -> void:
	_ok(not Gde.pad_connected() and not Gde.pad_pressed("A") and Gde.stick(JOY_AXIS_LEFT_X) == 0.0,
			"геймпад: без геймпада — не нажато, стик в нуле, без ошибок")
	var ex := GdeExpr.compile("StickX() * 200", "_c", _reg)
	_ok((ex["errors"] as Array).is_empty(), "геймпад: выражение StickX() собирается")
	Gde.vibrate(0.5, 0.5, 0.1)
	_ok(true, "геймпад: вибрация без геймпада не падает")


# --------------------------------------------- прикрепить, дублировать ---

func _test_attach() -> void:
	var hero := _thing("Hero", Vector2(500, 0), Vector2(20, 20))
	var coin := _thing("Coin", Vector2(600, 0), Vector2(8, 8))
	var r := _runner({}, [
		_event([_cond("system.trigger_once", [])], [_act("object.attach", ["Coin", "Hero", "10", "-20"])]),
		_event([_cond("object.attached", ["Coin"])], [_act("var.modify", ["held", "=", "1"])]),
		_event([_cond("object.attached_to", ["Coin", "Hero"])], [_act("var.modify", ["held_by", "=", "1"])]),
	])
	_tick(r, 1)
	_ok(coin.get_parent() == hero and coin.global_position.distance_to(Vector2(510, -20)) < 0.5,
			"прикрепить: монета у героя со сдвигом 10 ; -20")
	hero.position += Vector2(100, 50)
	_ok(coin.global_position.distance_to(Vector2(610, 30)) < 0.5, "прикрепить: едет вместе с ним")
	_ok(Gde.var_get("held", 0.0) == 1.0 and Gde.var_get("held_by", 0.0) == 1.0, "прикрепить: условия «прикреплён» и «прикреплён к»")
	Gde.detach(coin)
	var at := coin.global_position
	hero.position += Vector2(100, 0)
	_ok(coin.get_parent() != hero and coin.global_position.distance_to(at) < 0.5, "открепить: остался на месте и больше не едет")
	# Тело не падает, пока прикреплено.
	var rb := RigidBody2D.new()
	rb.add_child(_rect_shape(Vector2(8, 8)))
	rb.position = Vector2(900, 0)
	add_child(rb)
	rb.add_to_group(Gde.GROUP_PREFIX + "Coin")
	var ctx := Gde.new_context()
	Gde.attach(rb, ctx, "Hero", 0.0, 0.0, true)
	_ok(rb.freeze and rb.get_parent() == hero and rb.global_position.distance_to(Vector2(900, 0)) < 0.5,
			"прикрепить на месте: тело заморожено и осталось где было")
	Gde.detach(rb)
	_ok(not rb.freeze, "открепить: тело снова падает")
	_free([r, rb, coin, hero])


func _rect_shape(size: Vector2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	return cs


func _test_duplicate() -> void:
	var e := _thing("Enemy", Vector2(0, 300), Vector2(10, 10))
	Gde.ovar_set(e, "hp", 3.0)
	Gde.main(e)          # кэш главного узла — копия не должна его унаследовать
	var r := _runner({}, [
		_event([_cond("system.trigger_once", [])], [
			_act("object.duplicate", ["Enemy", "40", "0"]),
			_act("object.variable", ["Enemy", "copy", "=", "1"]),
		]),
	])
	_tick(r, 1)
	var all := Gde.all_instances("Enemy")
	_eq(all.size(), 2, "дублировать: стало два экземпляра")
	var c: Node2D = all[0] if all[0] != e else all[1]
	_ok(c.global_position.distance_to(e.global_position + Vector2(40, 0)) < 0.5, "дублировать: копия со сдвигом 40")
	_eq(Gde.ovar_get(c, "hp"), 3.0, "дублировать: переменные скопированы")
	Gde.ovar_set(c, "hp", 1.0)
	_eq(Gde.ovar_get(e, "hp"), 3.0, "дублировать: переменные у копии свои")
	_ok(Gde.main(c) == c, "дублировать: копия не держит кэш оригинала")
	_ok(float(Gde.ovar_get(c, "copy", 0.0)) == 1.0 and float(Gde.ovar_get(e, "copy", 0.0)) == 0.0,
			"дублировать: дальше в выборке — копия")
	_free([r] + all)


# --------------------------------------------------------------- эффекты ---

func _count(cls: String) -> int:
	var n := 0
	for c: Node in get_children():
		if c.get_class() == cls or (c.get_script() != null and (c.get_script() as Script).get_global_name() == cls):
			n += 1
	return n


func _test_effects() -> void:
	var r := _runner({}, [
		_event([_cond("system.trigger_once", [])], [
			_act("effect.at", ["explosion", "100", "100", "1"]),
			_act("effect.at", ["искры", "300", "100", "2"]),
		]),
	])
	_tick(r, 1)
	var n := _count("GdeDebris")
	_ok(n >= 32, "эффект в точке: взрыв и «искры» по-русски — частицы на месте (%d)" % n)
	var before := _count("GdeDebris")
	Gde.effect("nope", 0, 0, 1)
	_eq(_count("GdeDebris"), before, "эффект: неизвестное имя — ничего, только предупреждение")
	var hero := _thing("Hero", Vector2(500, 200), Vector2(20, 20))
	var r2 := _runner({}, [
		_event([_cond("system.trigger_once", [])], [_act("effect.float_text", ["Hero", "\"-3\"", "red"])]),
	])
	_tick(r2, 1)
	var ft: Node2D = null
	for c: Node in get_children():
		if c is GdeFloatText:
			ft = c
	_ok(ft != null and ft.global_position.y < hero.global_position.y, "всплывающий текст: появился над объектом")
	# Дым взрыва живёт дольше всех — до 1.2 с.
	await _wait_ms(1500)
	_ok(not is_instance_valid(ft) and _count("GdeDebris") == 0, "всплывающий текст и частицы растаяли сами")
	_free([r, r2, hero])


func _test_hitstop_flash_fade() -> void:
	Gde.hitstop(0.1)
	_ok(Engine.time_scale == 0.0 and Gde.in_hitstop(), "стоп-кадр: игра замерла")
	await _wait_ms(180)
	_ok(Engine.time_scale == 1.0 and not Gde.in_hitstop(), "стоп-кадр: через 0.1 с отпустило")
	Gde.screen_flash("red", 0.15, 0.8)
	await get_tree().process_frame
	var flash: ColorRect = Gde.get("_flash")
	_ok(flash != null and flash.color.r > 0.9 and flash.color.a > 0.5, "вспышка: экран вспыхнул красным")
	await _wait_ms(250)
	_ok(flash.color.a < 0.01, "вспышка: погасла")
	# Путь нарочно без сцены: переход не случится, а затемнение пройдёт целиком.
	Gde.change_scene_fade("res://addons/gdevents/tests/no_such_scene.tscn", 0.2, "black")
	_ok(Gde.is_fading(), "затемнение: началось")
	await _wait_ms(100)
	var fade: ColorRect = Gde.get("_fade")
	_ok(fade.color.a > 0.9, "затемнение: экран потемнел")
	await _wait_ms(250)
	_ok(not Gde.is_fading() and fade.color.a < 0.01, "затемнение: проявился обратно")


# ------------------------------------------- списки, значения на экране ---

func _test_lists() -> void:
	var r := _runner({"inv": [], "has_key": 0, "n": 0, "empty": 0}, [
		_event([_cond("system.trigger_once", [])], [
			_act("list.add", ["inv", "\"key\""]),
			_act("list.add_number", ["inv", "5"]),
			_act("list.add", ["inv", "\"sword\""]),
			_act("var.modify", ["n", "=", "ListCount(inv)"]),
		], [
			_event([_cond("list.contains", ["inv", "\"key\""])], [_act("var.modify", ["has_key", "=", "1"])]),
			_event([], [
				_act("list.remove_value", ["inv", "\"5\""]),
				_act("var.set_string", ["joined", "ListJoin(inv, \", \")"]),
				_act("list.take_first", ["inv", "got"]),
				_act("var.set_string", ["first", "ListItem(inv, 0)"]),
			]),
		]),
		_event([_cond("list.empty", ["inv"])], [_act("var.modify", ["empty", "=", "1"])]),
	])
	_tick(r, 1)
	_eq(Gde.var_get("n"), 3.0, "списки: добавили три элемента — ListCount 3")
	_eq(Gde.var_get("has_key"), 1.0, "списки: «содержит key»")
	_eq(Gde.var_get("joined"), "key, sword", "списки: число 5 убрано по тексту \"5\", ListJoin — «key, sword»")
	_ok(Gde.var_get("got") == "key" and Gde.var_get("first") == "sword", "списки: вынули первый в переменную, дальше — sword")
	_eq(Gde.var_get("empty"), 0.0, "списки: пока не пуст — «пуст» ложно")
	Gde.list_clear("inv")
	_tick(r, 1)
	_eq(Gde.var_get("empty"), 1.0, "списки: очистили — «пуст»")
	_free([r])


func _test_screen_values() -> void:
	Gde.show_value("hp", "3")
	Gde.screen_log("hello")
	await get_tree().process_frame
	var t := Gde.screen_text()
	_ok(t.contains("hp: 3") and t.contains("hello"), "на экране: значение и строка журнала")
	await _wait_ms(650)
	t = Gde.screen_text()
	_ok(not t.contains("hp: 3") and t.contains("hello"), "на экране: переставшее обновляться значение исчезло, журнал держится")
	Gde.clear_screen_values()
	_ok(Gde.screen_text().is_empty(), "на экране: «убрать надписи»")


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
