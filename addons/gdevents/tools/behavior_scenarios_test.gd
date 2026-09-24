## Безголовый тест новых поведений — каждое в своём маленьком мире:
##   godot --headless --quit-after 20000 res://addons/gdevents/tools/behavior_scenarios_test.tscn
##
## В отличие от behavior_test, где все поведения живут на одной сцене и
## проверяются по номерам кадров, здесь сценарии идут по очереди: построить
## мир, прокрутить физику, проверить, убрать. Так новый сценарий не сдвигает
## чужие кадры и не задевает чужие объекты.
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node2D

const PATROL := preload("res://addons/gdevents/behaviors/patrol_enemy/patrol_enemy.gd")

var _fails: int = 0
var _checks: int = 0


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	# Объекты «как из листа»: поведения ищут друг друга по именам.
	Gde.register_objects([
		{"name": "Player", "scene": "res://addons/gdevents/tests/player_virtual.tscn"},
		{"name": "Enemy", "scene": "res://addons/gdevents/tests/enemy_virtual.tscn"},
	])
	await _patrol_enemy()
	_report()


# ------------------------------------------------------------- сценарии ---

func _patrol_enemy() -> void:
	print("— Патрульный враг")
	var w := _world()
	_static(w, Vector2(0, 100), Vector2(400, 20))          # платформа от -200 до 200
	_static(w, Vector2(-190, 60), Vector2(20, 60))         # стена у левого края
	var e := _character(w, Vector2(0, 70), Vector2(20, 20))
	var b := _beh(e, PATROL, {"walk_speed": 240.0, "turn_pause": 0.0, "target_object": "Player",
			"sight_range": 200.0, "chase_speed": 300.0, "lose_time": 0.3})
	var turns: Array[int] = [0]
	b.connect("turned", func() -> void: turns[0] += 1)
	var min_x := INF
	var max_x := -INF
	for i in 200:
		await get_tree().physics_frame
		min_x = minf(min_x, e.global_position.x)
		max_x = maxf(max_x, e.global_position.x)
	_ok(e.global_position.y < 95.0, "патруль: не упал с платформы")
	_ok(max_x > 150.0 and max_x < 205.0, "патруль: дошёл до правого края и развернулся (x до %.0f)" % max_x)
	_ok(min_x > -185.0 and min_x < -150.0, "патруль: развернулся, упёршись в стену (x от %.0f)" % min_x)
	_ok(turns[0] >= 2, "патруль: сигнал turned на каждом развороте")
	_ok(bool(b.call("is_patrolling")), "патруль: без цели — патрулирует")

	# Игрок впереди, в пределах взгляда: враг замечает и гонится.
	b.set("walk_speed", 0.0)
	await _frames(2)
	var dir := float(b.call("direction"))
	var p := _tagged(w, "Player", e.global_position + Vector2(120.0 * dir, 0.0))
	var spotted: Array[bool] = [false]
	b.connect("spotted", func() -> void: spotted[0] = true)
	await _frames(3)
	_ok(spotted[0] and bool(b.call("is_chasing")), "погоня: заметил игрока впереди")
	var before := e.global_position.distance_to(p.global_position)
	await _frames(10)
	_ok(e.global_position.distance_to(p.global_position) < before - 20.0, "погоня: приближается к игроку")
	_eq(b.call("state_name"), "chase", "погоня: состояние текстом")

	# Игрок пропал из виду — поиск, потом возвращение на место старта.
	b.set("walk_speed", 240.0)
	p.global_position = Vector2(5000, 70)
	await _frames(3)
	_ok(bool(b.call("is_searching")), "поиск: цель пропала — ищет")
	var came_back := false
	for i in 150:
		await get_tree().physics_frame
		if bool(b.call("is_patrolling")):
			came_back = true
			break
	_ok(came_back, "потеря: сдался и вернулся к патрулю")
	_ok(absf(e.global_position.x) < 8.0, "потеря: сначала дошёл до места старта (x = %.0f)" % e.global_position.x)

	# Игрок за спиной не замечается, пока не включено sees_behind.
	b.set("walk_speed", 0.0)
	b.set("return_home", false)
	await _frames(2)
	p.global_position = e.global_position + Vector2(-80.0 * float(b.call("direction")), 0.0)
	await _frames(3)
	_ok(not bool(b.call("is_chasing")), "зрение: игрока за спиной не видит")
	b.set("sees_behind", true)
	await _frames(3)
	_ok(bool(b.call("is_chasing")), "зрение: с «видит за спиной» — замечает")

	# Стена между ними загораживает взгляд.
	b.set("sees_behind", false)
	b.call("back_to_patrol")
	b.set("lose_time", 0.0)
	await _frames(3)
	var d2 := float(b.call("direction"))
	_static(w, e.global_position + Vector2(40.0 * d2, -10.0), Vector2(10, 60))
	p.global_position = e.global_position + Vector2(90.0 * d2, 0.0)
	await _frames(4)
	_ok(not bool(b.call("sees_target")), "зрение: стена загораживает игрока")
	w.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- мир ---

func _world() -> Node2D:
	var w := Node2D.new()
	add_child(w)
	return w


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _rect(size: Vector2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	return cs


func _static(w: Node, at: Vector2, size: Vector2) -> StaticBody2D:
	var s := StaticBody2D.new()
	s.position = at
	s.add_child(_rect(size))
	w.add_child(s)
	return s


func _character(w: Node, at: Vector2, size: Vector2) -> CharacterBody2D:
	var c := CharacterBody2D.new()
	c.position = at
	c.add_child(_rect(size))
	w.add_child(c)
	return c


## Экземпляр объекта листа без сцены: рантайм узнаёт его по группе.
func _tagged(w: Node, obj: String, at: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	w.add_child(n)
	n.add_to_group(Gde.GROUP_PREFIX + obj)
	return n


func _beh(host: Node, script: Script, props: Dictionary) -> Node:
	var b := Node.new()
	b.set_script(script)
	for k: String in props:
		b.set(k, props[k])
	host.add_child(b)
	return b


# ------------------------------------------------------------ проверки ---

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	_checks += 1
	var same := false
	if got is float or got is int:
		same = is_equal_approx(float(got), float(want))
	else:
		same = str(got) == str(want)
	if same:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s — ожидалось %s, получено %s" % [what, want, got])


func _report() -> void:
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)
